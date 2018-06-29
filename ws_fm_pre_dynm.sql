CREATE DEFINER=`raxuser`@`%` PROCEDURE `ws_fm_pre_dynm`(in base long, in t_id long, in in_airline char(2), in in_audit_batch char(8))
BEGIN

declare frm_date date;
declare to_date date;
declare airline char(2);
declare audit_batch char(8);

SELECT in_audit_batch into @audit_batch ;

SELECT in_airline into @airline ;

SELECT max(trnsc_date) into @to_date FROM ws_audit.audit_fare_main a where a.audit_batch = @audit_batch; -- write the variable with @ helps to identify theh variable and the field

SELECT min(trnsc_date) into @frm_date FROM ws_audit.audit_fare_main a where a.audit_batch = @audit_batch;


# ############################################################################################################## build location to tarrif table ###############################################################################################################
# ============================================================================================================================================================================================================================= #
-- Clean tour code for a better matching potentially
-- From Jayden

#-------------------------------------------------------------------------------------------------------------------------------
##################################### create all possible carrier for each fare component, to locate carrier for fare matching
-- for some international sectors, it is impossible  to determine which carrier's fare, both carriers need to be considerred

drop table if exists zz_ws.temp_tbl_fc_cxrs;
create table zz_ws.temp_tbl_fc_cxrs engine = MyISAM
select f.doc_nbr_prime, f.carr_cd, f.trnsc_date, f.fc_cpn_nbr, f.fc_carr_cd, 
left(fc_carr_cd, 2) as r_carr_cd, left(fc_rbd, 1) as fc_rbd,
@audit_batch
from ws_audit.audit_fare_main a
join ws_dw.sales_tkt_fc f
on a.doc_nbr_prime = f.doc_nbr_prime and a.carr_cd = f.carr_cd and a.trnsc_date = f.trnsc_date
where
a.doc_nbr_prime not in (select doc_nbr_prime from ws_dw.sales_tkt_fc_err)
and 
a.trnsc_date between @frm_date and @to_date
and
a.audit_batch = @audit_batch
union
select f.doc_nbr_prime, f.carr_cd, f.trnsc_date, f.fc_cpn_nbr, f.fc_carr_cd, 
right(fc_carr_cd, 2) as r_carr_cd, right(fc_rbd, 1) as fc_rbd,
@audit_batch
from ws_audit.audit_fare_main a
join ws_dw.sales_tkt_fc f
on a.doc_nbr_prime = f.doc_nbr_prime and a.carr_cd = f.carr_cd and a.trnsc_date = f.trnsc_date
where
a.doc_nbr_prime not in (select doc_nbr_prime from ws_dw.sales_tkt_fc_err)
and 
a.trnsc_date between @frm_date and @to_date
and
a.audit_batch = @audit_batch
and
length(fc_carr_cd) = 4;

ALTER TABLE zz_ws.temp_tbl_fc_cxrs 
ADD INDEX idx_doc (doc_nbr_prime ASC, fc_cpn_nbr ASC, fc_carr_cd asc);


##################################### create mapping table to map each fare component's original airport and destination airport to their countries
# create tariff information for improving matching -- spec
drop table if exists zz_ws.temp_tbl_fc_ond_cntry;

create table zz_ws.temp_tbl_fc_ond_cntry engine = MyISAM
select distinct cxrs.r_carr_cd as fc_carr_cd, 
o.atpco_cntry_cd as fc_orig_cntry, o.atpco_zone as fc_orig_zone, o.atpco_area as fc_orig_area, o.atpco_data_subs as fc_orig_data_subs,
d.atpco_cntry_cd as fc_dest_cntry, d.atpco_zone as fc_dest_zone, d.atpco_area as fc_dest_area, d.atpco_data_subs as fc_dest_data_subs,
fc_rwct_ind
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxrs on (fc.doc_nbr_prime = cxrs.doc_nbr_prime and fc.carr_cd = cxrs.carr_cd and fc.trnsc_date = cxrs.trnsc_date)
join genie.iata_airport_city o on o.airpt_cd = fc.fc_orig_airpt
join genie.iata_airport_city d on d.airpt_cd = fc.fc_dest_airpt

union		# reverse the direction because ws_dw.sales_tkt_fc does not necessarily provides correct fare direction

select distinct cxrs.r_carr_cd as fc_carr_cd, 
o.atpco_cntry_cd as fc_orig_cntry, o.atpco_zone as fc_orig_zone, o.atpco_area as fc_orig_area, o.atpco_data_subs as fc_orig_data_subs,
d.atpco_cntry_cd as fc_dest_cntry, d.atpco_zone as fc_dest_zone, d.atpco_area as fc_dest_area, d.atpco_data_subs as fc_dest_data_subs,
fc_rwct_ind
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxrs on (fc.doc_nbr_prime = cxrs.doc_nbr_prime and fc.carr_cd = cxrs.carr_cd and fc.trnsc_date = cxrs.trnsc_date)
join genie.iata_airport_city o on o.airpt_cd = fc.fc_dest_airpt
join genie.iata_airport_city d on d.airpt_cd = fc.fc_orig_airpt;


##################################### create tariff mapping table
drop table if exists zz_ws.temp_tbl_fc_tar_spec;

CREATE TABLE zz_ws.temp_tbl_fc_tar_spec(
  carr_cd char(2) NOT NULL,
  orig_cntry char(2) NOT NULL,
  orig_area char(1) NOT NULL DEFAULT '',
  dest_cntry char(2) NOT NULL,
  dest_area char(1) NOT NULL DEFAULT '',
  -- rwct_ind char(2) NOT NULL,
  -- tar_cd char(7) NOT NULL DEFAULT '',
  tar_nbr char(3) NOT NULL DEFAULT ''
  -- pub_pvt_ind char(3) NOT NULL DEFAULT '',
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

truncate zz_ws.temp_tbl_fc_tar_spec;

insert into zz_ws.temp_tbl_fc_tar_spec (carr_cd, 
orig_cntry, orig_area, 
dest_cntry, dest_area,  
tar_nbr)
select distinct f.fc_carr_cd,
 fc_orig_cntry, fc_orig_area, 
 fc_dest_cntry, fc_dest_area,
 g.ff_nbr
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (g.carr_cd = f.fc_carr_cd and m.tar_cd = if(ff1_cd<>'', ff1_cd, ff2_cd) )
where
m.fbr_ind = 'N'
and
(case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then fc_orig_area =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then fc_dest_zone = m.loc2
	when 'A' then fc_dest_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
#and not (m.loc1 = '1' and f.fc_orig_cntry in ('us', 'ca') and m.data_subs ='1') -- exception as us is area 1 but international substription

union  -- genie.ref_atpco_tariff doesn't have directions

select distinct f.fc_carr_cd, 
 fc_orig_cntry, fc_orig_area, 
 fc_dest_cntry, fc_dest_area,
g.ff_nbr
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (g.carr_cd = f.fc_carr_cd and m.tar_cd = if(ff1_cd<>'', ff1_cd, ff2_cd) )
where
m.fbr_ind = 'N'
and
(case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then fc_dest_zone = m.loc1
	when 'A' then fc_dest_area =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then fc_orig_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
#and not (m.loc1 = '1' and f.fc_dest_cntry in ('us', 'ca') and m.data_subs ='1')
;

ALTER TABLE zz_ws.temp_tbl_fc_tar_spec 
ADD INDEX idx (carr_cd ASC,orig_cntry ASC, dest_cntry ASC);

##################################### make a simplified table for specified tariff table fast matching
-- can not be removed, it reduce the column of the original table from 8521 records to 2598 records, saving 2/3 duplication on 2018-03-23
/*
drop table if exists zz_ws.i_or_d_table_temp;
create table if not exists zz_ws.i_or_d_table_temp engine = MyISAM
select distinct carr_cd, orig_cntry, dest_cntry from zz_ws.temp_tbl_fc_tar_spec;

ALTER TABLE zz_ws.i_or_d_table_temp 
ADD INDEX idx (carr_cd ASC, orig_cntry ASC, dest_cntry ASC);
*/

##################################### create a table to check data_sub

-- this is also created as in the atpco area, us and ca is separated as not area 1 but area D
-- can not be removed, it reduce the column of the original table from 8521 records to 1508 records, saving 3/4 duplication
drop table if exists zz_ws.data_sub;
/*
create table if not exists zz_ws.data_sub engine = MyISAM
select distinct  fc_orig_cntry as orig_cntry, fc_dest_cntry as dest_cntry, m.data_subs
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (g.carr_cd = f.fc_carr_cd and m.tar_cd = if(ff1_cd<>'', ff1_cd, ff2_cd) )
where
m.fbr_ind = 'N'
and
(case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then fc_orig_data_subs =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then fc_dest_zone = m.loc2
	when 'A' then fc_dest_data_subs =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)

union  -- genie.ref_atpco_tariff doesn't have directions

select distinct  fc_orig_cntry as orig_cntry, fc_dest_cntry as dest_cntry, m.data_subs
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (g.carr_cd = f.fc_carr_cd and m.tar_cd = if(ff1_cd<>'', ff1_cd, ff2_cd) )
where
m.fbr_ind = 'N'
and
(case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then fc_dest_zone = m.loc1
	when 'A' then fc_dest_data_subs =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then fc_orig_data_subs =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
;
*/

create table if not exists zz_ws.data_sub engine = MyISAM
select distinct
fc_orig_cntry as orig_cntry, fc_dest_cntry as dest_cntry,
case
when fc_orig_data_subs = 'D' and fc_dest_data_subs = 'D' then 'D'
when fc_orig_data_subs = 'D' and fc_dest_data_subs in ('1', '2', '3') then 'I'
when fc_orig_data_subs in ('1', '2', '3') and fc_dest_data_subs = 'D' then 'I'
when fc_orig_data_subs = '1' and fc_dest_data_subs in ('1', '2', '3') then '1'
when fc_orig_data_subs in ('1', '2', '3') and fc_dest_data_subs = '1' then '1'
when fc_orig_data_subs = '2' and fc_dest_data_subs in ('2', '3') then fc_dest_data_subs
when fc_orig_data_subs in ('2', '3') and fc_dest_data_subs = '2' then fc_orig_data_subs
when fc_orig_data_subs ='3' and fc_dest_data_subs = '3' then '3'
else '0'
end
as data_subs
from zz_ws.temp_tbl_fc_ond_cntry f
;

ALTER TABLE zz_ws.data_sub 
ADD INDEX idx (orig_cntry ASC, dest_cntry ASC);

# ---------------------------------------------------------------------------------------------------------

/*
##################################### create g16 table to build a mapping between afz and ff tariff number

drop table if exists zz_ws.temp_tbl_g16;

create table zz_ws.temp_tbl_g16 engine = MyISAM
select carr_cd, ff1_cd as ff_cd, ff1_nbr as ff_nbr, afz1_cd as afz_cd, afz1_nbr as afz_nbr, frt_cd, frt_nbr, area_cd
from zz_ws.atpco_g16
where ff1_cd <> '' and afz1_cd <> ''
union
select carr_cd, ff2_cd, ff2_nbr, afz1_cd, afz1_nbr, frt_cd, frt_nbr, area_cd
from zz_ws.atpco_g16
where ff2_cd <> '' and afz1_cd <> ''
union
select carr_cd, ff2_cd, ff2_nbr, afz2_cd, afz2_nbr, frt_cd, frt_nbr, area_cd
from zz_ws.atpco_g16
where ff2_cd <> '' and afz2_cd <> '';                   #expand G16 to expand the addon tariff

ALTER TABLE zz_ws.temp_tbl_g16 
ADD INDEX idx (carr_cd ASC);
*/

##################################### create construction fare tariff mapping table ###############################################################################################################

drop table if exists zz_ws.temp_tbl_fc_tar_addon;

CREATE TABLE zz_ws.temp_tbl_fc_tar_addon (
  carr_cd char(2) NOT NULL,
  orig_cntry char(2) NOT NULL,
  orig_area char(1) NOT NULL DEFAULT '',
  dest_cntry char(2) NOT NULL,
  dest_area char(1) NOT NULL DEFAULT '',
  -- rwct_ind char(2) NOT NULL,
  -- ff_cd char(7) NOT NULL DEFAULT '',
  ff_nbr char(3) NOT NULL DEFAULT '',
  -- pub_pvt_ind char(3) NOT NULL DEFAULT '',
  -- afz_cd char(7) NOT NULL DEFAULT '',
  afz_nbr char(3) NOT NULL DEFAULT '',
  afz_p06_nbr char(3) NOT NULL DEFAULT '',		# changed on 2018-04-23, where p06 must match the reciprocal tariff number

  -- frt_cd char(7) NOT NULL DEFAULT '',
  frt_nbr char(3) NOT NULL DEFAULT '',
  area_cd char(2) NOT NULL DEFAULT ''	-- is equal to globl index
  -- data_subs char(1) NOT NULL DEFAULT ''  
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;


# Scenario 1, both afz1 and afz2 are specified in G16
insert into zz_ws.temp_tbl_fc_tar_addon (carr_cd, orig_cntry, orig_area, dest_cntry, dest_area, ff_nbr, afz_nbr, afz_p06_nbr, frt_nbr, area_cd)
select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff2_nbr, g.afz1_nbr, g.afz2_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (fc_carr_cd = g.carr_cd and g.ff2_cd = m.tar_cd)
where ff2_cd <> ''
and (case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then fc_orig_area =  m.loc1
	else true
    end)	
and (case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then fc_dest_zone = m.loc2
	when 'A' then fc_dest_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)

union		# reverse afz1 and afz2, the reciprocal tariffs for addon matching

select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff2_nbr, g.afz2_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (fc_carr_cd = g.carr_cd and g.ff2_cd = m.tar_cd)
where ff2_cd <> ''
and (case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then fc_orig_area =  m.loc1
	else true
    end)	
and (case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then fc_dest_zone = m.loc2
	when 'A' then fc_dest_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)

union		# genie.ref_atpco_tariff doesn't have directions --------------------------------------------------------------------------

select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff2_nbr, g.afz1_nbr, g.afz2_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (fc_carr_cd = g.carr_cd and g.ff2_cd = m.tar_cd)
where ff2_cd <> ''
and (case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then fc_dest_zone = m.loc1
	when 'A' then fc_dest_area =  m.loc1
	else true
    end)
and (case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then fc_orig_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)

union		# reverse afz1 and afz2, the reciprocal tariffs for addon matching

select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff2_nbr, g.afz2_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (fc_carr_cd = g.carr_cd and g.ff2_cd = m.tar_cd)
where ff2_cd <> ''
and (case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then  fc_dest_zone = m.loc1
	when 'A' then fc_dest_area =  m.loc1
	else true
    end)
and (case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then  fc_orig_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
;


# Scenario 2, only afz1 is specified in G16
insert into zz_ws.temp_tbl_fc_tar_addon (carr_cd, orig_cntry, orig_area, dest_cntry, dest_area, ff_nbr, afz_nbr, afz_p06_nbr, frt_nbr, area_cd)
select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff_nbr, g.afz1_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (fc_carr_cd = g.carr_cd and g.ff1_cd = m.tar_cd)
where ff1_cd <> '' and afz1_cd <> ''
and (case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then fc_orig_area =  m.loc1
	else true
    end)	
and (case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then fc_dest_zone = m.loc2
	when 'A' then fc_dest_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)

union		# genie.ref_atpco_tariff doesn't have directions --------------------------------------------------------------------------

select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff_nbr, g.afz1_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (fc_carr_cd = g.carr_cd and g.ff1_cd = m.tar_cd)
where ff1_cd <> '' and afz1_cd <> ''
and (case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then fc_dest_zone = m.loc1
	when 'A' then fc_dest_area =  m.loc1
	else true
    end)
and (case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then fc_orig_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
;


# find the cases where addon actually cut across different zones, where our genie.ref_atpco_tariff could not specify

drop table if exists zz_ws.temp_tbl_xzone_addon;

create table zz_ws.temp_tbl_xzone_addon engine = MyISAM
select distinct a.carr_cd, a.tar_nbr, o.atpco_cntry_cd as via_cntry, d.atpco_cntry_cd as addon_cntry
from atpco_fare.atpco_addon a
join genie.iata_airport_city o on o.city_cd = a.orig_city
join genie.iata_airport_city d on d.city_cd = a.dest_city
where o.atpco_zone <> d.atpco_zone
and carr_cd = in_airline
union
select distinct a.carr_cd, a.tar_nbr, o.atpco_cntry_cd as via_cntry, d.atpco_cntry_cd as addon_cntry
from atpco_fare.atpco_addon a
join genie.iata_airport_city o on o.airpt_cd = a.orig_city	# change to using airport code
join genie.iata_airport_city d on d.city_cd = a.dest_city
where o.atpco_zone <> d.atpco_zone
and carr_cd = in_airline
union
select distinct a.carr_cd, a.tar_nbr, o.atpco_cntry_cd as via_cntry, d.atpco_cntry_cd as addon_cntry
from atpco_fare.atpco_addon a
join genie.iata_airport_city o on o.city_cd = a.orig_city
join genie.iata_airport_city d on d.airpt_cd = a.dest_city
where o.atpco_zone <> d.atpco_zone
and carr_cd = in_airline
union
select distinct a.carr_cd, a.tar_nbr, o.atpco_cntry_cd as via_cntry, d.atpco_cntry_cd as addon_cntry
from atpco_fare.atpco_addon a
join genie.iata_airport_city o on o.airpt_cd = a.orig_city
join genie.iata_airport_city d on d.airpt_cd = a.dest_city
where o.atpco_zone <> d.atpco_zone
and carr_cd = in_airline
;

alter table zz_ws.temp_tbl_xzone_addon
add index idx (addon_cntry ASC, carr_cd ASC);


drop table if exists zz_ws.temp_tbl_fare_tar;

create table zz_ws.temp_tbl_fare_tar engine = MyISAM
select distinct carr_cd, orig_cntry, dest_cntry, tar_nbr
from atpco_fare.atpco_fare
where carr_cd = in_airline;

alter table zz_ws.temp_tbl_fare_tar
add index idx (orig_cntry ASC, dest_cntry ASC, carr_cd ASC);



# Scenario 1, both afz1 and afz2 are specified in G16
insert into zz_ws.temp_tbl_fc_tar_addon (carr_cd, orig_cntry, dest_cntry, ff_nbr, afz_nbr, afz_p06_nbr, frt_nbr, area_cd)

select distinct fc_carr_cd, fc_orig_cntry, fc_dest_cntry, g.ff2_nbr, g.afz1_nbr, g.afz2_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join zz_ws.temp_tbl_xzone_addon a on (a.addon_cntry = f.fc_dest_cntry and a.carr_cd = f.fc_carr_cd)
join zz_ws.temp_tbl_fare_tar t on (t.orig_cntry = f.fc_orig_cntry and t.dest_cntry = a.via_cntry and t.carr_cd = f.fc_carr_cd)
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.ff2_nbr = t.tar_nbr and (g.afz1_nbr = a.tar_nbr or g.afz2_nbr = a.tar_nbr))
union
select distinct fc_carr_cd, fc_orig_cntry, fc_dest_cntry, g.ff2_nbr, g.afz2_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd		# reverse afz1 and afz2, the reciprocal tariffs for addon matching
from zz_ws.temp_tbl_fc_ond_cntry f
join zz_ws.temp_tbl_xzone_addon a on (a.addon_cntry = f.fc_dest_cntry and a.carr_cd = f.fc_carr_cd)
join zz_ws.temp_tbl_fare_tar t on (t.orig_cntry = f.fc_orig_cntry and t.dest_cntry = a.via_cntry and t.carr_cd = f.fc_carr_cd)
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.ff2_nbr = t.tar_nbr and (g.afz1_nbr = a.tar_nbr or g.afz2_nbr = a.tar_nbr))

union 		# genie.ref_atpco_tariff doesn't have directions --------------------------------------------------------------------------

select distinct fc_carr_cd, fc_orig_cntry, fc_dest_cntry, g.ff2_nbr, g.afz1_nbr, g.afz2_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join zz_ws.temp_tbl_xzone_addon a on (a.addon_cntry = f.fc_orig_cntry and a.carr_cd = f.fc_carr_cd)
join zz_ws.temp_tbl_fare_tar t on (t.orig_cntry = a.via_cntry and t.dest_cntry = f.fc_dest_cntry and t.carr_cd = f.fc_carr_cd)
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.ff2_nbr = t.tar_nbr and (g.afz1_nbr = a.tar_nbr or g.afz2_nbr = a.tar_nbr))

union

select distinct fc_carr_cd, fc_orig_cntry, fc_dest_cntry, g.ff2_nbr, g.afz2_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd		# reverse afz1 and afz2, the reciprocal tariffs for addon matching
from zz_ws.temp_tbl_fc_ond_cntry f
join zz_ws.temp_tbl_xzone_addon a on (a.addon_cntry = f.fc_orig_cntry and a.carr_cd = f.fc_carr_cd)
join zz_ws.temp_tbl_fare_tar t on (t.orig_cntry = a.via_cntry and t.dest_cntry = f.fc_dest_cntry and t.carr_cd = f.fc_carr_cd)
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.ff2_nbr = t.tar_nbr and (g.afz1_nbr = a.tar_nbr or g.afz2_nbr = a.tar_nbr))
;


# Scenario 2, only afz1 is specified in G16
insert into zz_ws.temp_tbl_fc_tar_addon (carr_cd, orig_cntry, dest_cntry, ff_nbr, afz_nbr, afz_p06_nbr, frt_nbr, area_cd)
select distinct fc_carr_cd, fc_orig_cntry, fc_dest_cntry, g.ff_nbr, g.afz1_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join zz_ws.temp_tbl_xzone_addon a on (a.addon_cntry = f.fc_dest_cntry and a.carr_cd = f.fc_carr_cd)
join zz_ws.temp_tbl_fare_tar t on (t.orig_cntry = f.fc_orig_cntry and t.dest_cntry = a.via_cntry and t.carr_cd = f.fc_carr_cd)
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.ff1_nbr = t.tar_nbr and g.afz1_nbr = a.tar_nbr)

union 		# genie.ref_atpco_tariff doesn't have directions --------------------------------------------------------------------------

select distinct fc_carr_cd, fc_orig_cntry, fc_dest_cntry, g.ff_nbr, g.afz1_nbr, g.afz1_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join zz_ws.temp_tbl_xzone_addon a on (a.addon_cntry = f.fc_orig_cntry and a.carr_cd = f.fc_carr_cd)
join zz_ws.temp_tbl_fare_tar t on (t.orig_cntry = a.via_cntry and t.dest_cntry = f.fc_dest_cntry and t.carr_cd = f.fc_carr_cd)
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.ff1_nbr = t.tar_nbr and g.afz1_nbr = a.tar_nbr)
;


ALTER TABLE zz_ws.temp_tbl_fc_tar_addon
ADD INDEX idx (carr_cd ASC, orig_cntry ASC, dest_cntry ASC, ff_nbr asc);		-- the tariff can be estimated


/*
# the following code is replaced by the code above

insert into zz_ws.temp_tbl_fc_tar_addon (carr_cd, orig_cntry, orig_area, dest_cntry, dest_area, ff_nbr, afz_nbr, frt_nbr, area_cd)
select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff_nbr, g.afz_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_zone o on (o.cntry_cd = f.fc_orig_cntry)
join genie.ref_atpco_zone d on (d.cntry_cd = f.fc_dest_cntry)
join genie.ref_atpco_tariff m
join zz_ws.temp_tbl_g16 g on (fc_carr_cd = g.carr_cd and g.ff_cd = m.tar_cd)
where
(case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then  fc_orig_area =  m.loc1
	else true
    end)	
and
(case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then  fc_dest_zone = m.loc2
	when 'A' then fc_dest_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
and not (m.loc1 = '1' and f.fc_orig_cntry in ('us', 'ca') and m.data_subs ='1') -- exception as us is area 1 but international substription

union  -- genie.ref_atpco_tariff doesn't have directions
select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.ff_nbr, g.afz_nbr, g.frt_nbr, g.area_cd
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_zone o on (o.cntry_cd = f.fc_orig_cntry)
join genie.ref_atpco_zone d on (d.cntry_cd = f.fc_dest_cntry)
join genie.ref_atpco_tariff m
join zz_ws.temp_tbl_g16 g on (fc_carr_cd = g.carr_cd and g.ff_cd = m.tar_cd)
where
(case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then  fc_dest_zone = m.loc1
	when 'A' then fc_dest_area =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then  fc_orig_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
and not (m.loc1 = '1' and f.fc_dest_cntry in ('us', 'ca') and m.data_subs ='1') -- exception as us is area 1 but international substription
;

ALTER TABLE zz_ws.temp_tbl_fc_tar_addon
ADD INDEX idx (carr_cd ASC, orig_cntry ASC, dest_cntry ASC, ff_nbr asc);		-- the tariff can be estimated

*/


# ---------------------------------------------------------------------------------------------------------
##################################### create tariff mapping table for FBR ####################################################################################################################################################

drop table if exists zz_ws.temp_tbl_fc_tar_fbr;

CREATE TABLE zz_ws.temp_tbl_fc_tar_fbr (
  carr_cd char(2) NOT NULL,
  orig_cntry char(2) NOT NULL,
  orig_area char(1) NOT NULL DEFAULT '',
  dest_cntry char(2) NOT NULL,
  dest_area char(1) NOT NULL DEFAULT '',
  -- rwct_ind char(2) NOT NULL,
  -- tar_cd char(7) NOT NULL DEFAULT '',
  tar_nbr char(3) NOT NULL DEFAULT ''
  -- pub_pvt_ind char(3) NOT NULL DEFAULT '',
  -- data_subs char(1) NOT NULL DEFAULT '' 
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

insert into zz_ws.temp_tbl_fc_tar_fbr (carr_cd, orig_cntry, orig_area, dest_cntry, dest_area, tar_nbr)
select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.frt_nbr
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.frt_cd = m.tar_cd)
where
m.fbr_ind = 'Y'
and
(case m.loc1_type
	when 'N' then fc_orig_cntry = m.loc1
	when 'Z' then fc_orig_zone = m.loc1
	when 'A' then  fc_orig_area =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_dest_cntry = m.loc2
	when 'Z' then  fc_dest_zone = m.loc2
	when 'A' then fc_dest_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
#and not (m.loc1 = '1' and f.fc_orig_cntry in ('us', 'ca') and m.data_subs ='1') -- exception as us is area 1 but international substription

union  -- genie.ref_atpco_tariff doesn't have directions

select distinct fc_carr_cd, fc_orig_cntry, fc_orig_area, fc_dest_cntry, fc_dest_area, g.frt_nbr
from zz_ws.temp_tbl_fc_ond_cntry f
join genie.ref_atpco_tariff m
join zz_ws.atpco_g16 g on (g.carr_cd = fc_carr_cd and g.frt_cd = m.tar_cd)
where
m.fbr_ind = 'Y'
and
(case m.loc1_type
	when 'N' then fc_dest_cntry = m.loc1
	when 'Z' then  fc_dest_zone = m.loc1
	when 'A' then fc_dest_area =  m.loc1
	else true
    end)
and
(case m.loc2_type
	when 'N' then fc_orig_cntry = m.loc2
	when 'Z' then fc_orig_zone = m.loc2
	when 'A' then  fc_orig_area =  m.loc2
	else true
    end)
and if(m.dom_ind = 'Y', fc_orig_cntry = fc_dest_cntry, true)
and if(m.rwct_ind = 'Y', fc_rwct_ind in ('RW', 'CT'), true)
#and not (m.loc1 = '1' and f.fc_dest_cntry in ('us', 'ca') and m.data_subs ='1') -- exception as us is area 1 but international substription
;

ALTER TABLE zz_ws.temp_tbl_fc_tar_fbr 
ADD INDEX idx (carr_cd ASC,orig_cntry ASC, dest_cntry ASC);

# ---------------------------------------------------------------------------------------------------------
##################################### create table temp_tbl_fc_all containing all permutation of directions
 
drop table if exists zz_ws.temp_tbl_fc_all;

CREATE TABLE zz_ws.temp_tbl_fc_all (
  fc_all_id int(11) NOT NULL AUTO_INCREMENT,
  doc_nbr_prime bigint(20) NOT NULL,
  doc_carr_nbr char(3) NOT NULL,
  trnsc_date date NOT NULL,
  fare_lockin_date date NOT NULL,
  -- fcs varchar(512) NOT NULL DEFAULT '',
  -- fcs_std varchar(512) NOT NULL DEFAULT '',
  fc_cpn_nbr tinyint(3) unsigned NOT NULL,
  -- fc_rwct_ind char(2) NOT NULL DEFAULT '',
  fc_orig char(3) NOT NULL,
  fc_orig_cntry char(2) NOT NULL,
  fc_orig_area char(1) NOT NULL,
  fc_dest char(3) NOT NULL,
  fc_dest_cntry char(2) NOT NULL,
  fc_dest_area char(1) NOT NULL,
  fc_carr_cd char(2) NOT NULL,
  fc_fbc varchar(15) NOT NULL,
  fc_mile_plus decimal(3,2) NOT NULL,
  fc_tkt_dsg varchar(15) DEFAULT NULL,
  fc_rbd char(1) default '',
  fc_pax_type char(3) DEFAULT NULL,
  fc_curr_cd char(3) DEFAULT NULL,
  fc_amt decimal(11, 2) DEFAULT NULL,
  fc_roe decimal(13, 6) DEFAULT NULL,
  fc_nuc_amt decimal(11,2) DEFAULT NULL,
  -- fc_disc_pct decimal(3,2) DEFAULT NULL,
  jrny_dep_date date DEFAULT NULL,
  tkt_tour_cd varchar(15) NOT NULL DEFAULT '',
  mod_tour_cd varchar(15) NOT NULL default '',
  tkt_endorse_cd varchar(15) NOT NULL DEFAULT '',	-- temporarily keep it
  map_di_ind char(1) DEFAULT NULL,
  -- fare_match_ind char(1) not null DEFAULT 'N',
  -- spec_match char(1) not null DEFAULT 'N',
  -- cda_match char(1) not null DEFAULT 'N',
  -- fbr_match char(1) not null DEFAULT 'N',
  PRIMARY KEY (fc_all_id)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

insert into zz_ws.temp_tbl_fc_all (doc_nbr_prime, doc_carr_nbr, trnsc_date, 
fare_lockin_date, mod_tour_cd, 
fc_cpn_nbr, fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area,
 fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_rbd,
 fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind)
select distinct fc.doc_nbr_prime, fc.carr_cd, fc.trnsc_date, 
fc.trnsc_date, fc.tkt_tour_cd,
fc.fc_cpn_nbr, orig.city_cd, orig.atpco_cntry_cd, orig.atpco_area, dest.city_cd, dest.atpco_cntry_cd, dest.atpco_area,
cxr.r_carr_cd, fc.fc_fbc, if(right(fc.fc_type,1)='M', left(fc_type,2)/100.00, 0), fc.fc_tkt_dsg, cxr.fc_rbd,
fc.tkt_pax_type, fc.fc_curr_cd, fc.fc_amt, fc_roe, fc.fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, 'F'
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxr on (fc.doc_nbr_prime = cxr.doc_nbr_prime and fc.fc_carr_cd = cxr.fc_carr_cd and fc.trnsc_date = cxr.trnsc_date and fc.fc_cpn_nbr = cxr.fc_cpn_nbr)
join zz_ws.temp_tbl_airpt_city orig on (orig.airpt_cd = fc.fc_orig_airpt)
join zz_ws.temp_tbl_airpt_city dest on (dest.airpt_cd = fc.fc_dest_airpt)
#join genie.ref_pax_disc d on (if(tkt_pax_type in ('INF'), 0.10, if(tkt_pax_type in ('CNN', 'UNN'), 0.50, 1.00)) <= d.disc_pct)

# the code is removed on 2018-06-0=18, due to PU IO changes, no longer need
# left join zz_ws.data_sub t1	on (orig.atpco_cntry_cd = t1.orig_cntry and dest.atpco_cntry_cd = t1.dest_cntry )
# where (fc_fare_io <> 'I'  or t1.data_subs = 'D' )  # domestic we need to do both; international we do the inbound

union

select distinct fc.doc_nbr_prime, fc.carr_cd, fc.trnsc_date, 
fc.trnsc_date, fc.tkt_tour_cd,
fc.fc_cpn_nbr, orig.city_cd, orig.atpco_cntry_cd, orig.atpco_area, dest.city_cd, dest.atpco_cntry_cd, dest.atpco_area,
cxr.r_carr_cd, fc.fc_fbc, if(right(fc.fc_type,1)='M', left(fc_type,2)/100.00, 0), fc.fc_tkt_dsg, cxr.fc_rbd,
fc.tkt_pax_type, fc.fc_curr_cd, fc.fc_amt, fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, 'R'
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxr on (fc.doc_nbr_prime = cxr.doc_nbr_prime and fc.fc_carr_cd = cxr.fc_carr_cd and fc.trnsc_date = cxr.trnsc_date and fc.fc_cpn_nbr = cxr.fc_cpn_nbr)
join zz_ws.temp_tbl_airpt_city orig on (orig.airpt_cd = fc.fc_dest_airpt)
join zz_ws.temp_tbl_airpt_city dest on (dest.airpt_cd = fc.fc_orig_airpt)
#join genie.ref_pax_disc d on (if(tkt_pax_type in ('INF'), 0.10, if(tkt_pax_type in ('CNN', 'UNN'), 0.50, 1.00)) <= d.disc_pct)
left join zz_ws.data_sub t1 on (orig.atpco_cntry_cd = t1.dest_cntry and dest.atpco_cntry_cd = t1.orig_cntry )

# the code is modified on 2018-06-0=18, due to PU IO changes, no longer need
# where ( ((fc.fc_fare_io = 'I') or (fc.fc_fare_io = 'O' and fc.fc_cpn_nbr <> 1)) or t1.data_subs='D')  # domestic we need to do both; international we do the outbond and not the first one

where not(fc.fc_cpn_nbr = 1 and t1.data_subs <> 'D')  # for the 1st international fare component (outbound), we do not need to reverse. For all other scenarios, we need to reverse the matching

/* -- the process of hipping is temporarily omitted.
union
select distinct fc.doc_nbr_prime, fc.carr_cd, fc.trnsc_date, fc.fc_cpn_nbr, fc.fc_hip_orig, orig.atpco_cntry_cd, orig.atpco_area, fc.fc_hip_dest, dest.atpco_cntry_cd, dest.atpco_area,
cxr.r_carr_cd, fc.fc_fbc, if(right(fc.fc_type,1)='M', left(fc_type,2)/100.00, 0), fc.fc_tkt_dsg,
fc.tkt_pax_type, fc.fc_curr_cd, fc.fc_amt, fc_roe, fc.fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, 'F'
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxr on (fc.doc_nbr_prime = cxr.doc_nbr_prime and fc.fc_carr_cd = cxr.fc_carr_cd and fc.trnsc_date = cxr.trnsc_date and fc.fc_cpn_nbr = cxr.fc_cpn_nbr)
join zz_ws.temp_tbl_airpt_city orig on (orig.city_cd = fc.fc_hip_orig) and fc.fc_hip_orig <> ''
join zz_ws.temp_tbl_airpt_city dest on (dest.city_cd = fc.fc_hip_dest) and fc.fc_hip_dest <> ''
#straight_join zz_ws.i_or_d_table_temp t1 on orig.atpco_cntry_cd=t1.orig_cntry and dest.atpco_cntry_cd=t1.dest_cntry and cxr.r_carr_cd=t1.carr_cd -- can be removed if it passes the test
*/
;

####################################### insert extra tour_cd

insert into zz_ws.temp_tbl_fc_all (doc_nbr_prime, doc_carr_nbr, trnsc_date, fare_lockin_date, mod_tour_cd, 
fc_cpn_nbr, fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area,
 fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_rbd,
 fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind)
 
select distinct fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc_cpn_nbr, fc.trnsc_date, tcl.mod_tour_cd,
fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area, 
fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_rbd, 
fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind
from zz_ws.temp_tbl_fc_all fc
join ws_dw.tour_cd_list tcl	on ( tcl.tour_cd = fc.tkt_tour_cd );


#######################################
# due to the fact that Sabre tends to add 'CH' and 'IN' to FBC, need to generate extra matching records by removing CH/IN,
# cannot remove CH/IN directly from FBC due to that CH/IN might be part of the FBC

insert into zz_ws.temp_tbl_fc_all (doc_nbr_prime, doc_carr_nbr, trnsc_date, 
fare_lockin_date, mod_tour_cd, 
fc_cpn_nbr, fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_rbd, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind)
select fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, 
fc.fare_lockin_date, fc.mod_tour_cd, 
fc_cpn_nbr, fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area, fc_carr_cd, left(fc_fbc, length(fc_fbc)-2), fc_mile_plus, fc_tkt_dsg, fc_rbd, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind
from zz_ws.temp_tbl_fc_all fc
join ws_dw.sales_tkt tkt on (tkt.doc_nbr_prime = fc.doc_nbr_prime)
where (left(tkt.tkt_pnr, 3) in ('AA/', '1S/') or right(tkt.tkt_pnr, 3) in ('/AA', '/1S'))
and right(fc_fbc, 2) in ('CH', 'IN');


####################################### insert extra date

insert into zz_ws.temp_tbl_fc_all (doc_nbr_prime, doc_carr_nbr, trnsc_date, fare_lockin_date, mod_tour_cd, 
fc_cpn_nbr, fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area,
 fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_rbd,
 fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind)
 
select distinct fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc_cpn_nbr, DATE_sub(tcx.eff_date, INTERVAL 1 DAY), fc.mod_tour_cd,
fc_orig, fc_orig_cntry, fc_orig_area, fc_dest, fc_dest_cntry, fc_dest_area, 
fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_rbd, 
fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd, tkt_endorse_cd, map_di_ind
from zz_ws.temp_tbl_fc_all fc
join ws_dw.tour_cd_ext tcx	on ( tcx.mod_tour_cd = fc.mod_tour_cd )
and (fc.trnsc_date between tcx.eff_date and tcx.ext_date);

alter table zz_ws.temp_tbl_fc_all add index idx_doc (doc_nbr_prime asc);

####################################### insert extra date

optimize table  zz_ws.temp_tbl_fc_all;

update zz_ws.temp_tbl_fc_all a
join ws_dw.fare_lockin_date_mod m on a.doc_nbr_prime = m.doc_nbr_prime and a.trnsc_date = m.trnsc_date
set a.fare_lockin_date = m.fare_lockin_date;

####################################### create a table to check data_subs of each fc not in err table

drop table if exists zz_ws.temp_include_tkt;
create table if not exists zz_ws.temp_include_tkt engine myisam
select distinct fc.doc_nbr_prime, 
fc.trnsc_date, t1.data_subs
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxr on (fc.doc_nbr_prime = cxr.doc_nbr_prime and fc.fc_carr_cd = cxr.fc_carr_cd and fc.trnsc_date = cxr.trnsc_date and fc.fc_cpn_nbr = cxr.fc_cpn_nbr)
join zz_ws.temp_tbl_airpt_city orig on (orig.airpt_cd = fc.fc_dest_airpt)
join zz_ws.temp_tbl_airpt_city dest on (dest.airpt_cd = fc.fc_orig_airpt)
left join zz_ws.data_sub t1
on orig.atpco_cntry_cd=t1.dest_cntry and dest.atpco_cntry_cd=t1.orig_cntry 
union 
select distinct fc.doc_nbr_prime, 
fc.trnsc_date, t1.data_subs
from ws_dw.sales_tkt_fc fc
join zz_ws.temp_tbl_fc_cxrs cxr on (fc.doc_nbr_prime = cxr.doc_nbr_prime and fc.fc_carr_cd = cxr.fc_carr_cd and fc.trnsc_date = cxr.trnsc_date and fc.fc_cpn_nbr = cxr.fc_cpn_nbr) 
-- fc.fc_carr_cd can be mixed as two carr_cd as cx/ka, it is the same as temp_tbl_fc_cxrs
join zz_ws.temp_tbl_airpt_city orig on (orig.airpt_cd = fc.fc_orig_airpt)
join zz_ws.temp_tbl_airpt_city dest on (dest.airpt_cd = fc.fc_dest_airpt)
left join zz_ws.data_sub t1
on orig.atpco_cntry_cd=t1.orig_cntry and dest.atpco_cntry_cd=t1.dest_cntry
;
alter table zz_ws.temp_include_tkt
add index idx_doc (doc_nbr_prime);

####################################### create a table to find all fare components within area 1, 2, or domestic or with us and ca
drop table if exists zz_ws.temp_exclude_tkt;

create table if not exists zz_ws.temp_exclude_tkt engine myisam
select distinct a.doc_nbr_prime, a.fc_cpn_nbr, a.trnsc_date, a.doc_carr_nbr
from zz_ws.temp_tbl_fc_all a 
join  zz_ws.data_sub sub -- join zz_ws.temp_tbl_fc_tar_all b, let us check whether it will get changed in future
on a.fc_orig_cntry = sub.orig_cntry
and a.fc_dest_cntry = sub.dest_cntry
join rax.ref_airline_fare al_f
on 
al_f.airline = @airline
and 
(
	(sub.data_subs = '1' and al_f.area_1 <> 'Y')
    or
    	(sub.data_subs = '2' and al_f.area_2 <> 'Y')
    or
    	(sub.data_subs = '3' and al_f.area_3 <> 'Y')
    or
    	(sub.data_subs = 'D' and al_f.area_dom <> 'Y')
    or
    	(sub.data_subs = 'I' and al_f.area_int <> 'Y')
);

alter table zz_ws.temp_exclude_tkt
add index idx_exclude (doc_nbr_prime, doc_carr_nbr);

optimize table zz_ws.temp_exclude_tkt;

####################################### delete tickets that we cannot find fares, update the corresponding field in ws_audit.audit_fare_main

delete a from zz_ws.temp_tbl_fc_all a where (doc_nbr_prime, fc_carr_cd) in (select doc_nbr_prime, fc_carr_cd from zz_ws.temp_exclude_tkt);  -- delete tickets in area 1, 2, D, and within us and ca

delete a from zz_ws.temp_tbl_fc_all a join zz_ws.temp_include_tkt b on a.doc_nbr_prime=b.doc_nbr_prime and a.trnsc_date=b.trnsc_date and b.data_subs is null; -- delete tickets where we cannot find a tariff for it.

update ws_audit.audit_fare_main a 
set atpco_fare_exist_ind = 'Y';

update ws_audit.audit_fare_main a 
set atpco_fare_exist_ind = 'N'
where (doc_nbr_prime, carr_cd) in (select doc_nbr_prime, doc_carr_nbr from zz_ws.temp_exclude_tkt);  -- mark tickets in area 1, 2, D, and within us and ca

update ws_audit.audit_fare_main a 
join zz_ws.temp_include_tkt b on a.doc_nbr_prime=b.doc_nbr_prime and a.trnsc_date=b.trnsc_date and b.data_subs is null
set atpco_fare_exist_ind = 'N'; -- mark tickets where we cannot find a tariff for it.

update ws_audit.audit_fare_main a 
set a.fc_pass_ind = 'Y'
where audit_batch = @audit_batch
; -- mark fc err indicator

update ws_audit.audit_fare_main a 
join ws_dw.sales_tkt_fc_err b on a.doc_nbr_prime=b.doc_nbr_prime and a.trnsc_date=b.trnsc_date and a.carr_cd = b.carr_cd
set a.fc_pass_ind = 'N'; -- mark fc err indicator

####################################### zz_ws.temp_tbl_fc_all will append city state nation zone and area to temp_tbl_fc_all


ALTER TABLE zz_ws.temp_tbl_fc_all
add column fc_orig_c char(3) default '',
add column fc_orig_s char(2) default '',
add column fc_orig_n char(2) default '',
add column fc_orig_z char(3) default '',
add column fc_orig_sz char(3) default '',
add column fc_orig_a char(1) default ''
;

ALTER TABLE zz_ws.temp_tbl_fc_all
add column fc_dest_c char(3) default '',
add column fc_dest_s char(2) default '',
add column fc_dest_n char(2) default '',
add column fc_dest_z char(3) default '',
add column fc_dest_sz char(3) default '',
add column fc_dest_a char(1) default ''
;

update zz_ws.temp_tbl_fc_all fc
join genie.iata_airport_city i
on
fc.fc_orig=i.city_cd
set 
fc.fc_orig_c=i.city_cd,
fc.fc_orig_s=i.state_cd,
fc.fc_orig_n=i.atpco_cntry_cd, 
fc.fc_orig_z=i.atpco_zone,
fc.fc_orig_sz=i.atpco_subzone,
fc.fc_orig_a=i.atpco_area;

update zz_ws.temp_tbl_fc_all fc
join genie.iata_airport_city i
on
fc.fc_orig=i.airpt_cd
set 
fc.fc_orig_c=i.city_cd,
fc.fc_orig_s=i.state_cd,
fc.fc_orig_n=i.atpco_cntry_cd, 
fc.fc_orig_z=i.atpco_zone,
fc.fc_orig_sz=i.atpco_subzone,
fc.fc_orig_a=i.atpco_area;

update zz_ws.temp_tbl_fc_all fc
join genie.iata_airport_city i
on
fc.fc_dest =i.city_cd
set 
fc.fc_dest_c=i.city_cd,
fc.fc_dest_s=i.state_cd,
fc.fc_dest_n=i.atpco_cntry_cd,
fc.fc_dest_z=i.atpco_zone,
fc.fc_dest_sz=i.atpco_subzone,
fc.fc_dest_a=i.atpco_area;

update zz_ws.temp_tbl_fc_all fc
join genie.iata_airport_city i
on
fc.fc_dest =i.airpt_cd
set 
fc.fc_dest_c=i.city_cd,
fc.fc_dest_s=i.state_cd,
fc.fc_dest_n=i.atpco_cntry_cd,
fc.fc_dest_z=i.atpco_zone,
fc.fc_dest_sz=i.atpco_subzone,
fc.fc_dest_a=i.atpco_area;

optimize table zz_ws.temp_tbl_fc_all;


# ############################################################################# create table to speed up the Specified fare matching processing #############################################################################################
-- to speed up fare matching, try to use the fare basis code (FBC)		


drop table if exists zz_ws.temp_fbcx_spec_tar;

create table zz_ws.temp_fbcx_spec_tar engine = MyISAM
select tar_nbr, carr_cd, fbc_rule, dsg_rule, count(*) as cnt
FROM zz_ws.temp_fbcx_spec
group by tar_nbr, carr_cd, fbc_rule, dsg_rule;

alter table zz_ws.temp_fbcx_spec_tar
add index idx (tar_nbr asc, carr_cd asc);

# --------------------------------------------------------------------------------------------------------------------------------

drop table if exists zz_ws.temp_map_fbcx_spec;

CREATE TABLE zz_ws.temp_map_fbcx_spec (
  doc_nbr_prime bigint(20) NOT NULL,
  fc_cpn_nbr tinyint(3) unsigned NOT NULL,
  fc_fbc varchar(15) NOT NULL,
  fc_tkt_dsg varchar(15) DEFAULT NULL,
  frt_nbr char(3) not null DEFAULT '',
  fft_nbr char(3) not null DEFAULT '',
  carr_cd char(2) not null DEFAULT '',
  fbc_match varchar(15) not null DEFAULT '',
  fbc_rule varchar(15) not null DEFAULT ''
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

#######################################  insert the FBC directly when fbcx_rule = ''
insert into zz_ws.temp_map_fbcx_spec (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, g16.ff_nbr, fbcm.carr_cd, fc_fbc, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
join zz_ws.temp_tbl_fc_tar_spec t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
join zz_ws.atpco_g16 g16 on (g16.carr_cd = t.carr_cd and g16.ff_nbr = t.tar_nbr)
join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = g16.frt_nbr and fbcm.carr_cd = g16.carr_cd)
# join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd)
where fbcm.fbc_rule = ''
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


#######################################  insert the FBC after peeling off changes to find the orginal fare class, eg. -CH, -IN, when its pattern is '-abc'
insert into zz_ws.temp_map_fbcx_spec (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, g16.ff_nbr, fbcm.carr_cd, left(fc_fbc, length(fc_fbc) - (length(fbcm.fbc_rule)-1)), fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
join zz_ws.temp_tbl_fc_tar_spec t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
join zz_ws.atpco_g16 g16 on (g16.carr_cd = t.carr_cd and g16.ff_nbr = t.tar_nbr)
join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = g16.frt_nbr and fbcm.carr_cd = g16.carr_cd)
# join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd)
where left(fbcm.fbc_rule, 1) = '-'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


-- can only use the rule to find the orginal fare class
#######################################  insert the FBC after peeling off changes to find the orginal fare class, eg. F-, when its pattern is 'X-'
insert into zz_ws.temp_map_fbcx_spec (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, g16.ff_nbr, fbcm.carr_cd, r1.fare_cls, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
straight_join zz_ws.temp_tbl_fc_tar_spec t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.atpco_g16 g16 on (g16.carr_cd = t.carr_cd and g16.ff_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = g16.frt_nbr and fbcm.carr_cd = g16.carr_cd)
# straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd)
straight_join zz_ws.temp_fbcx_spec fbcx on (fbcx.tar_nbr = fbcm.tar_nbr and fbcx.carr_cd = fbcm.carr_cd and fbcx.fbc_rule = fbcm.fbc_rule)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.tar_nbr = fbcx.tar_nbr and r1.carr_cd = fbcx.carr_cd and r1.rule_nbr = fbcx.rule_nbr)
where right(fbcm.fbc_rule, 1) = '-'
and left(fc_fbc, length(fbcm.fbc_rule) - 1) = left(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and right(fc_fbc, length(fc_fbc) - (length(fbcm.fbc_rule) - 1)) = right(r1.fare_cls, length(r1.fare_cls) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


#######################################  insert the FBC after peeling off changes to find the orginal fare class,  -- eg. *XYZ, when its pattern is '*XYZ'
insert into zz_ws.temp_map_fbcx_spec (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, g16.ff_nbr, fbcm.carr_cd, r1.fare_cls, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
straight_join zz_ws.temp_tbl_fc_tar_spec t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.atpco_g16 g16 on (g16.carr_cd = t.carr_cd and g16.ff_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = g16.frt_nbr and fbcm.carr_cd = g16.carr_cd)
# straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd)
straight_join zz_ws.temp_fbcx_spec fbcx on (fbcx.tar_nbr = fbcm.tar_nbr and fbcx.carr_cd = fbcm.carr_cd and fbcx.fbc_rule = fbcm.fbc_rule)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.tar_nbr = fbcx.tar_nbr and r1.carr_cd = fbcx.carr_cd and r1.rule_nbr = fbcx.rule_nbr)
where left(fbcm.fbc_rule, 1) = '*'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and left(fc_fbc, 1) = left(r1.fare_cls, 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH

-- eg. YRT (ie. when a fare class is completely replaced by another code)
insert into zz_ws.temp_map_fbcx_spec (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, g16.ff_nbr, fbcm.carr_cd, r1.fare_cls, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
straight_join zz_ws.temp_tbl_fc_tar_spec t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.atpco_g16 g16 on (g16.carr_cd = t.carr_cd and g16.ff_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = g16.frt_nbr and fbcm.carr_cd = g16.carr_cd)
# straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd)
straight_join zz_ws.temp_fbcx_spec fbcx on (fbcx.tar_nbr = fbcm.tar_nbr and fbcx.carr_cd = fbcm.carr_cd and fbcx.fbc_rule = fbcm.fbc_rule)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.tar_nbr = fbcx.tar_nbr and r1.carr_cd = fbcx.carr_cd and r1.rule_nbr = fbcx.rule_nbr)
where instr(fbcm.fbc_rule, '-') = 0
and instr(fbcm.fbc_rule, '*') = 0
and fc_fbc = fbcm.fbc_rule
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


#######################################  insert the ticketing code matching into the table temp_map_fbcx_spec
-- if record 1 has a different ticketing code, then need to add it to the match
drop table if exists zz_ws.temp_map_r1_tkt_cd;

create table zz_ws.temp_map_r1_tkt_cd engine = MyISAM
select distinct r1.tar_nbr, r1.carr_cd, r1.fare_cls, r1s.tkt_cd
from atpco_fare.atpco_r1_fare_cls r1
join atpco_fare.atpco_r1_fare_cls_sup r1s on (r1.rule_id = r1s.rule_id)
where r1.fare_cls <> r1s.tkt_cd
and r1s.tkt_cd <> '';

alter table zz_ws.temp_map_r1_tkt_cd
add index idx (tar_nbr asc, carr_cd asc, tkt_cd asc);

insert into zz_ws.temp_map_fbcx_spec (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match)
select m.doc_nbr_prime, m.fc_cpn_nbr, m.fc_fbc, m.fc_tkt_dsg, m.frt_nbr, g16.ff_nbr, m.carr_cd, r.fare_cls
from zz_ws.temp_map_fbcx_spec m
join zz_ws.temp_map_r1_tkt_cd r on (r.tar_nbr = m.frt_nbr and r.carr_cd = m.carr_cd and r.tkt_cd = m.fbc_match)
join zz_ws.atpco_g16 g16 on (g16.carr_cd = m.carr_cd and g16.frt_nbr = m.frt_nbr)
where m.fbc_match <> ''
and m.fc_fbc = m.fbc_match;	-- ticket code modifier will only modify the fare class, not the ticket code from Record 1

#######################################  insert the ticketing code matching into the table temp_map_fbcx_spec
/*
-- populate fare tariff

update zz_ws.temp_map_fbcx_spec m
join zz_ws.atpco_g16 g16 on (g16.carr_cd = m.carr_cd and g16.frt_nbr = m.frt_nbr)
set m.fft_nbr = g16.ff_nbr;
*/
-- add index and optimize table for faster matching

alter table zz_ws.temp_map_fbcx_spec
add index idx (doc_nbr_prime asc, fc_cpn_nbr asc);

optimize table zz_ws.temp_map_fbcx_spec;


# ############################################################################# create table to speed up the Add-on processing #############################################################################################

drop table if exists zz_ws.temp_map_fbcx_addon;

CREATE TABLE zz_ws.temp_map_fbcx_addon (
  doc_nbr_prime bigint(20) NOT NULL,
  fc_cpn_nbr tinyint(3) unsigned NOT NULL,
  fc_fbc varchar(15) NOT NULL,
  fc_tkt_dsg varchar(15) DEFAULT NULL,
  frt_nbr char(3) not null DEFAULT '',
  fft_nbr char(3) not null DEFAULT '',
  carr_cd char(2) not null DEFAULT '',
  fbc_match varchar(15) not null DEFAULT '',
  fbc_rule varchar(15) not null DEFAULT ''
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;


#######################################  insert the FBC directly when fbcx_rule = ''
insert into zz_ws.temp_map_fbcx_addon (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, t.ff_nbr, fbcm.carr_cd, fc_fbc, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
join zz_ws.temp_tbl_fc_tar_addon t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.frt_nbr and fbcm.carr_cd = t.carr_cd)
where fbcm.fbc_rule = ''
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


#######################################  insert the FBC after peeling off changes to find the orginal fare class, eg. -CH, -IN, when its pattern is '-abc'
insert into zz_ws.temp_map_fbcx_addon (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, t.ff_nbr, fbcm.carr_cd, left(fc_fbc, length(fc_fbc) - (length(fbcm.fbc_rule)-1)), fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
join zz_ws.temp_tbl_fc_tar_addon t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.frt_nbr and fbcm.carr_cd = t.carr_cd)
where left(fbcm.fbc_rule, 1) = '-'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


-- can only use the rule to find the orginal fare class
#######################################  insert the FBC after peeling off changes to find the orginal fare class, eg. F-, when its pattern is 'X-'
insert into zz_ws.temp_map_fbcx_addon (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, t.ff_nbr, fbcm.carr_cd, r1.fare_cls, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
straight_join zz_ws.temp_tbl_fc_tar_addon t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.frt_nbr and fbcm.carr_cd = t.carr_cd)
straight_join zz_ws.temp_fbcx_spec fbcx on (fbcx.tar_nbr = fbcm.tar_nbr and fbcx.carr_cd = fbcm.carr_cd and fbcx.fbc_rule = fbcm.fbc_rule)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.tar_nbr = fbcx.tar_nbr and r1.carr_cd = fbcx.carr_cd and r1.rule_nbr = fbcx.rule_nbr)
where right(fbcm.fbc_rule, 1) = '-'
and left(fc_fbc, length(fbcm.fbc_rule) - 1) = left(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and right(fc_fbc, length(fc_fbc) - (length(fbcm.fbc_rule) - 1)) = right(r1.fare_cls, length(r1.fare_cls) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


#######################################  insert the FBC after peeling off changes to find the orginal fare class,  -- eg. *XYZ, when its pattern is '*XYZ'
insert into zz_ws.temp_map_fbcx_addon (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, t.ff_nbr, fbcm.carr_cd, r1.fare_cls, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
straight_join zz_ws.temp_tbl_fc_tar_addon t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.frt_nbr and fbcm.carr_cd = t.carr_cd)
straight_join zz_ws.temp_fbcx_spec fbcx on (fbcx.tar_nbr = fbcm.tar_nbr and fbcx.carr_cd = fbcm.carr_cd and fbcx.fbc_rule = fbcm.fbc_rule)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.tar_nbr = fbcx.tar_nbr and r1.carr_cd = fbcx.carr_cd and r1.rule_nbr = fbcx.rule_nbr)
where left(fbcm.fbc_rule, 1) = '*'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and left(fc_fbc, 1) = left(r1.fare_cls, 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


-- eg. YRT (ie. when a fare class is completely replaced by another code)
insert into zz_ws.temp_map_fbcx_addon (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fbcm.tar_nbr, t.ff_nbr, fbcm.carr_cd, r1.fare_cls, fbcm.fbc_rule
from zz_ws.temp_tbl_fc_all fc
straight_join zz_ws.temp_tbl_fc_tar_addon t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_spec_tar fbcm on (fbcm.tar_nbr = t.frt_nbr and fbcm.carr_cd = t.carr_cd)
straight_join zz_ws.temp_fbcx_spec fbcx on (fbcx.tar_nbr = fbcm.tar_nbr and fbcx.carr_cd = fbcm.carr_cd and fbcx.fbc_rule = fbcm.fbc_rule)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.tar_nbr = fbcx.tar_nbr and r1.carr_cd = fbcx.carr_cd and r1.rule_nbr = fbcx.rule_nbr)
where instr(fbcm.fbc_rule, '-') = 0
and instr(fbcm.fbc_rule, '*') = 0
and fc_fbc = fbcm.fbc_rule
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH


#######################################  insert the ticketing code matching into the table temp_map_fbcx_addon
-- if record 1 has a different ticketing code, then need to add it to the match
drop table if exists zz_ws.temp_map_r1_tkt_cd;

create table zz_ws.temp_map_r1_tkt_cd engine = MyISAM
select distinct r1.tar_nbr, r1.carr_cd, r1.fare_cls, r1s.tkt_cd
from atpco_fare.atpco_r1_fare_cls r1
join atpco_fare.atpco_r1_fare_cls_sup r1s on (r1.rule_id = r1s.rule_id)
where r1.fare_cls <> r1s.tkt_cd
and r1s.tkt_cd <> '';

alter table zz_ws.temp_map_r1_tkt_cd
add index idx (tar_nbr asc, carr_cd asc, tkt_cd asc);

insert into zz_ws.temp_map_fbcx_addon (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, frt_nbr, fft_nbr, carr_cd, fbc_match)
select m.doc_nbr_prime, m.fc_cpn_nbr, m.fc_fbc, m.fc_tkt_dsg, m.frt_nbr, g16.ff_nbr, m.carr_cd, r.fare_cls
from zz_ws.temp_map_fbcx_addon m
join zz_ws.temp_map_r1_tkt_cd r on (r.tar_nbr = m.frt_nbr and r.carr_cd = m.carr_cd and r.tkt_cd = m.fbc_match)
join zz_ws.atpco_g16 g16 on (g16.carr_cd = m.carr_cd and g16.frt_nbr = m.frt_nbr)
where m.fbc_match <> ''
and m.fc_fbc = m.fbc_match;	-- ticket code modifier will only modify the fare class, not the ticket code from Record 1

#######################################  insert the ticketing code matching into the table temp_map_fbcx_addon
-- populate fare tariff
/*
update zz_ws.temp_map_fbcx_addon m
join zz_ws.atpco_g16 g16 on (g16.carr_cd = m.carr_cd and g16.frt_nbr = m.frt_nbr)
set m.fft_nbr = g16.ff_nbr;
*/

-- add index and optimize table for faster matching

alter table zz_ws.temp_map_fbcx_addon
add index idx (doc_nbr_prime asc, fc_cpn_nbr asc);

optimize table zz_ws.temp_map_fbcx_addon;


# ############################################################################# create table to speed up the FBR processing #############################################################################################
# ============================================================================================================================================================================================================================= #
#######################################  to speed up fare matching, create a simple fbc table
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists zz_ws.temp_fc_fbc;

create table zz_ws.temp_fc_fbc engine = MyISAM
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, fc_orig_cntry, fc_dest_cntry, fc_carr_cd, mod_tour_cd
FROM zz_ws.temp_tbl_fc_all;

ALTER TABLE `zz_ws`.`temp_fc_fbc` 
ADD COLUMN `fbc_intact` CHAR(1) NOT NULL DEFAULT '' AFTER `mod_tour_cd`,
ADD COLUMN `fbc_append` CHAR(1) NOT NULL DEFAULT '' AFTER `fbc_intact`,
ADD COLUMN `fbc_replace` CHAR(1) NOT NULL DEFAULT '' AFTER `fbc_append`,
ADD COLUMN `fbc_mod_head` CHAR(1) NOT NULL DEFAULT '' AFTER `fbc_replace`,
ADD COLUMN `fbc_mod_tail` CHAR(1) NOT NULL DEFAULT '' AFTER `fbc_mod_head`,
ADD INDEX `idx_fc` (`doc_nbr_prime` ASC, `fc_cpn_nbr` ASC);


#######################################  table with FBC code not changed from fare class # -------- blank ----------------

drop table if exists zz_ws.temp_fbcx_fbr_blank;

create table zz_ws.temp_fbcx_fbr_blank engine = MyISAM
select tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule, count(*) as cnt
from zz_ws.temp_fbcx_fbr
where fbc_rule = ''
group by tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule;

alter table zz_ws.temp_fbcx_fbr_blank
add index `idx` (tar_nbr asc, carr_cd asc, rule_nbr asc);

alter table zz_ws.temp_fbcx_fbr_blank
add index `idx2` (tar_nbr asc, carr_cd asc, dsg_rule asc);

optimize table zz_ws.temp_fbcx_fbr_blank;

#######################################  table with FBC code # -------- append, like '-CH'  ----------------
drop table if exists zz_ws.temp_fbcx_fbr_append;

create table zz_ws.temp_fbcx_fbr_append engine = MyISAM
select tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule, count(*) as cnt
from zz_ws.temp_fbcx_fbr
where left(fbc_rule, 1) = '-'
group by tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule;

alter table zz_ws.temp_fbcx_fbr_append
add index `idx` (tar_nbr asc, carr_cd asc, rule_nbr asc);

alter table zz_ws.temp_fbcx_fbr_append
add index `idx2` (tar_nbr asc, carr_cd asc, dsg_rule asc);

optimize table zz_ws.temp_fbcx_fbr_append;

#######################################  table with FBC code # -------- replace, like 'YRT'  ----------------
drop table if exists zz_ws.temp_fbcx_fbr_replace;

create table zz_ws.temp_fbcx_fbr_replace engine = MyISAM
select tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule, count(*) as cnt
from zz_ws.temp_fbcx_fbr
where fbc_rule <> ''
and instr(fbc_rule, '-') = 0
and instr(fbc_rule, '*') = 0
group by tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule;

alter table zz_ws.temp_fbcx_fbr_replace
add index `idx` (tar_nbr asc, carr_cd asc, rule_nbr asc);

alter table zz_ws.temp_fbcx_fbr_replace
add index `idx2` (tar_nbr asc, carr_cd asc, dsg_rule asc);

optimize table zz_ws.temp_fbcx_fbr_replace;

#######################################  table with FBC code # -------- modify, like 'F-' or '*XYZ'  ----------------
drop table if exists zz_ws.temp_fbcx_fbr_modify;

create table zz_ws.temp_fbcx_fbr_modify engine = MyISAM
select tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule, count(*) as cnt
from zz_ws.temp_fbcx_fbr
where fbc_rule <> ''
and (right(fbc_rule, 1) =  '-' or left(fbc_rule, 1) = '*')
group by tar_nbr, carr_cd, rule_nbr, fbc_rule, dsg_rule;

alter table zz_ws.temp_fbcx_fbr_modify
add index `idx` (tar_nbr asc, carr_cd asc, rule_nbr asc);

alter table zz_ws.temp_fbcx_fbr_modify
add index `idx2` (tar_nbr asc, carr_cd asc, dsg_rule asc);

optimize table zz_ws.temp_fbcx_fbr_modify;


####################################### create fbc mapping to tariff and rule
# --------------------------------------------------------------------------------------------------------------------------------

drop table if exists zz_ws.temp_map_fbcx_fbr;

CREATE TABLE zz_ws.temp_map_fbcx_fbr (
  doc_nbr_prime bigint(20) NOT NULL,
  fc_cpn_nbr tinyint(3) unsigned NOT NULL,
  fc_fbc varchar(15) NOT NULL,
  fc_tkt_dsg varchar(15) DEFAULT NULL,
  mod_tour_cd varchar(15) DEFAULT NULL,
  frt_nbr char(3) not null DEFAULT '',
  carr_cd char(2) not null DEFAULT '',
  rule_nbr char(4) not null DEFAULT '',
  fbcx_mode char(1) not null DEFAULT '',
  fbc_match varchar(15) not null DEFAULT '',
  fbc_rule varchar(15) not null DEFAULT '',
  tkt_cd_ind char(1) not null DEFAULT ''
    
  -- UNIQUE INDEX `idx` (`doc_nbr_prime` ASC, `fc_cpn_nbr` ASC, `frt_nbr` ASC, `fbc_rule` ASC)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

# ------------------------------------------------------------------------------------------------------------------------
-- use the FBC directly, fbcx_rule = ''
/* old code, for reference only
insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, tkt_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, tkt_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '', fc_fbc, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_fbr_blank fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd)
left join zz_ws.temp_map_tour_cd tc on (tc.tar_nbr = fbcm.tar_nbr and tc.carr_cd = fbcm.carr_cd and tc.rule_nbr = fbcm.rule_nbr)
where (fbcm.dsg_rule = fc_tkt_dsg or fbcm.dsg_rule = '')
and if(tc.tour_cd is null, fc.tkt_tour_cd = '', tc.tour_cd = fc.tkt_tour_cd);
*/

# use tour code for the searching, CX cases
insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '', fc_fbc, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_map_tour_cd tc on (tc.tour_cd = fc.mod_tour_cd and tc.tar_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_fbr_blank fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.rule_nbr = tc.rule_nbr)
where mod_tour_cd <> ''
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH

# mark it as using tour code
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_intact = 'C'
where fbcx_mode = '';

# use ticketing designator for the searching, WS cases
insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '', fc_fbc, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_fbr_blank fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.dsg_rule = fc_tkt_dsg)
where fc.fbc_intact = ''
and fc_tkt_dsg <> '';

# mark it as using ticketing designator
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_intact = 'D'
where fbcx_mode = ''
and fc.fbc_intact = '';


drop table if exists zz_ws.temp_map_r1_tkt_cd;

create table zz_ws.temp_map_r1_tkt_cd engine = MyISAM
select distinct r1.carr_cd, r1.fare_cls, r1s.tkt_cd
from atpco_fare.atpco_r1_fare_cls r1
join atpco_fare.atpco_r1_fare_cls_sup r1s on (r1.rule_id = r1s.rule_id)
where r1.fare_cls <> r1s.tkt_cd
and r1s.tkt_cd <> '';

alter table zz_ws.temp_map_r1_tkt_cd
add index `idx` (tkt_cd asc, carr_cd asc);

update zz_ws.temp_map_fbcx_fbr m
join zz_ws.temp_map_r1_tkt_cd r on (r.carr_cd = m.carr_cd and r.tkt_cd = m.fbc_match)
set m.tkt_cd_ind = 'Y'
where m.fbc_match <> ''
and m.fc_fbc = m.fbc_match;	-- ticket code modifier will only modify the fare class, not the ticket code from Record 1


# ------------------------------------------------------------------------------------------------------------------------
-- use the FBC after peeling off changes, eg. -CH, -IN

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '-', left(fc_fbc, length(fc_fbc) - (length(fbcm.fbc_rule)-1)), fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_map_tour_cd tc on (tc.tour_cd = fc.mod_tour_cd and tc.tar_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_fbr_append fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.rule_nbr = tc.rule_nbr)
where mod_tour_cd <> ''
and left(fbcm.fbc_rule, 1) = '-'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH

# mark it as using tour code
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_append = 'C'
where fbcx_mode = '-';

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '-', left(fc_fbc, length(fc_fbc) - (length(fbcm.fbc_rule)-1)), fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_fbr_append fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.dsg_rule = fc_tkt_dsg)
where fc.fbc_append = ''
and fc_tkt_dsg <> ''
and left(fbcm.fbc_rule, 1) = '-'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1);

# mark it as using ticketing designator
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_append = 'D'
where fbcx_mode = '-'
and fc.fbc_append = '';

# ------------------------------------------------------------------------------------------------------------------------
-- eg. YRT (ie. when a fare class is completely replaced by another code)

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, 'X', fc_fbc, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_map_tour_cd tc on (tc.tour_cd = fc.mod_tour_cd and tc.tar_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_fbr_replace fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.rule_nbr = tc.rule_nbr)
where mod_tour_cd <> ''
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH

# mark it as using tour code
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_replace = 'C'
where fbcx_mode = 'X';

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, 'X', fc_fbc, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_fbr_replace fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.dsg_rule = fc_tkt_dsg)
where fc.fbc_replace = ''
and fc_tkt_dsg <> '';

# mark it as using ticketing designator
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_replace = 'D'
where fbcx_mode = 'X'
and fc.fbc_replace = '';


# ------------------------------------------------------------------------------------------------------------------------
-- can only use the rule to find a match -- eg. F-

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '*', fbcm.fbc_rule, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_map_tour_cd tc on (tc.tour_cd = fc.mod_tour_cd and tc.tar_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_fbr_modify fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.rule_nbr = tc.rule_nbr)
where mod_tour_cd <> ''
and right(fbcm.fbc_rule, 1) = '-'
and left(fc_fbc, length(fbcm.fbc_rule) - 1) = left(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH

# mark it as using tour code
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_mod_head = 'C'
where fbcx_mode = '*'
and right(fbc_rule, 1) = '-';

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '*', fbcm.fbc_rule, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_fbr_modify fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.dsg_rule = fc_tkt_dsg)
where fc.fbc_mod_head = ''
and fc_tkt_dsg <> ''
and right(fbcm.fbc_rule, 1) = '-'
and left(fc_fbc, length(fbcm.fbc_rule) - 1) = left(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1);

# mark it as using ticketing designator
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_mod_head = 'D'
where fbcx_mode = '*'
and right(fbc_rule, 1) = '-'
and fc.fbc_mod_head = '';

# ------------------------------------------------------------------------------------------------------------------------
-- for rules like *ABC, replacing the remaining the of the FBC

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '*', fbcm.fbc_rule, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_map_tour_cd tc on (tc.tour_cd = fc.mod_tour_cd and tc.tar_nbr = t.tar_nbr)
straight_join zz_ws.temp_fbcx_fbr_modify fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.rule_nbr = tc.rule_nbr)
where mod_tour_cd <> ''
and left(fbcm.fbc_rule, 1) = '*'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1)
and (fbcm.dsg_rule = fc_tkt_dsg or (fbcm.dsg_rule = '' and fc_tkt_dsg in ('IN', 'CH')));	# GDS (1A) may add only ticketing designator for IN and CH

# mark it as using tour code
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_mod_tail = 'C'
where fbcx_mode = '*'
and left(fbc_rule, 1) = '*';

insert into zz_ws.temp_map_fbcx_fbr (doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, frt_nbr, carr_cd, rule_nbr, fbcx_mode, fbc_match, fbc_rule)
select distinct doc_nbr_prime, fc_cpn_nbr, fc_fbc, fc_tkt_dsg, mod_tour_cd, fbcm.tar_nbr, fbcm.carr_cd, fbcm.rule_nbr, '*', fbcm.fbc_rule, fbcm.fbc_rule
from zz_ws.temp_fc_fbc fc
straight_join zz_ws.temp_tbl_fc_tar_fbr t on (t.orig_cntry = fc.fc_orig_cntry and t.dest_cntry = fc.fc_dest_cntry and t.carr_cd = fc.fc_carr_cd)
straight_join zz_ws.temp_fbcx_fbr_modify fbcm on (fbcm.tar_nbr = t.tar_nbr and fbcm.carr_cd = t.carr_cd and fbcm.dsg_rule = fc_tkt_dsg)
where fc.fbc_mod_tail = ''
and fc_tkt_dsg <> ''
and left(fbcm.fbc_rule, 1) = '*'
and right(fc_fbc, length(fbcm.fbc_rule) - 1) = right(fbcm.fbc_rule, length(fbcm.fbc_rule) - 1);

# mark it as using ticketing designator
update zz_ws.temp_fc_fbc fc
join zz_ws.temp_map_fbcx_fbr fbcx on (fbcx.doc_nbr_prime = fc.doc_nbr_prime and fbcx.fc_cpn_nbr = fc.fc_cpn_nbr)
set fc.fbc_mod_tail = 'D'
where fbcx_mode = '*'
and left(fbc_rule, 1) = '*'
and fc.fbc_mod_tail = '';


-- add index and optimize table for faster matching

alter table zz_ws.temp_map_fbcx_fbr
add index `idx` (doc_nbr_prime asc, fc_cpn_nbr asc);

optimize table zz_ws.temp_map_fbcx_fbr;



######################build the p06  plus table

# ---------------------------------------------------------------------------------------------------------
-- create pre-map for zone code for P06, to allow fast matching

drop table if exists zz_ws.temp_tbl_fc_ond_city;

create table zz_ws.temp_tbl_fc_ond_city engine = MyISAM
select distinct fc_carr_cd, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry
from zz_ws.temp_tbl_fc_all f;

-- zone numbers specified in the add-on fares
drop table if exists zz_ws.temp_tbl_zone_addon;

create table zz_ws.temp_tbl_zone_addon engine = MyISAM
select distinct carr_cd, tar_nbr, addon_zone as zone_nbr, dest_city as addon_city, ftnt
from atpco_fare.atpco_addon;

ALTER TABLE zz_ws.temp_tbl_zone_addon 
ADD INDEX idx (carr_cd ASC, tar_nbr ASC, addon_city ASC);

-- zone numbers specified for the specified fares
drop table if exists zz_ws.temp_tbl_cda_p06;

create table zz_ws.temp_tbl_cda_p06 engine = MyISAM
select distinct carr_cd, tar_nbr, zone_nbr, city_cd as spec_city
from atpco_fare.atpco_cda_p06;

ALTER TABLE zz_ws.temp_tbl_cda_p06 
ADD INDEX idx (carr_cd ASC, tar_nbr ASC, spec_city ASC);

-- for each city pair, general the possible zone numbers used, to limit the searching

drop table if exists zz_ws.temp_tbl_p06_zone_map;

create table zz_ws.temp_tbl_p06_zone_map engine = MyISAM

-- orgin add-on
select a.carr_cd, a.tar_nbr, addon_city as orig_city, spec_city as dest_city, a.zone_nbr, a.ftnt
from zz_ws.temp_tbl_fc_ond_city f
straight_join zz_ws.temp_tbl_fc_tar_addon t on (t.carr_cd = f.fc_carr_cd and t.orig_cntry = f.fc_orig_cntry and t.dest_cntry = f.fc_dest_cntry)
straight_join zz_ws.temp_tbl_zone_addon a on (a.carr_cd = f.fc_carr_cd and a.tar_nbr = t.afz_nbr and a.addon_city = f.fc_orig)
straight_join zz_ws.temp_tbl_cda_p06 s on (s.carr_cd = f.fc_carr_cd and s.tar_nbr = t.afz_p06_nbr and s.spec_city = f.fc_dest)
where a.zone_nbr = s.zone_nbr
and a.ftnt <> 'F'

union

-- destination add-on
select a.carr_cd, a.tar_nbr, spec_city as orig_city, addon_city as dest_city, a.zone_nbr, a.ftnt
from zz_ws.temp_tbl_fc_ond_city f
straight_join zz_ws.temp_tbl_fc_tar_addon t on (t.carr_cd = f.fc_carr_cd and t.orig_cntry = f.fc_orig_cntry and t.dest_cntry = f.fc_dest_cntry)
straight_join zz_ws.temp_tbl_zone_addon a on (a.carr_cd = f.fc_carr_cd and a.tar_nbr = t.afz_nbr and a.addon_city = f.fc_dest)
straight_join zz_ws.temp_tbl_cda_p06 s on (s.carr_cd = f.fc_carr_cd and s.tar_nbr = t.afz_p06_nbr and s.spec_city = f.fc_orig)
where
a.zone_nbr = s.zone_nbr
and a.ftnt <> 'T'
;

ALTER TABLE zz_ws.temp_tbl_p06_zone_map 
ADD INDEX idx (carr_cd ASC, tar_nbr ASC, orig_city ASC, dest_city ASC);

############################################################################################################################################################

# optimise a set of tables used for fare matching, just in case they are not optimized

optimize table atpco_fare.atpco_r8_fbr;
optimize table atpco_fare.atpco_r8_fbr_state;
optimize table atpco_fare.atpco_r2_cat25_ctrl;
optimize table atpco_fare.atpco_r2_cat25_ctrl_state;
optimize table atpco_fare.atpco_r2_cat25_ctrl_sup;
optimize table atpco_fare.atpco_cat25;
optimize table atpco_fare.atpco_t989_base_fare;
optimize table atpco_fare.atpco_fare;
optimize table atpco_fare.atpco_fare_state;
optimize table atpco_fare.atpco_r1_fare_cls;
optimize table atpco_fare.atpco_r1_fare_cls_state;
optimize table atpco_fare.atpco_r1_fare_cls_sup;


select 'fm_pre_dynm finished';

END