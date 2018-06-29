CREATE DEFINER=`raxuser`@`%` PROCEDURE `ws_fm_post3_dump2audit`(in in_audit_batch  char(8))
BEGIN

declare r_cat int(5) default 19; -- for loopig between cats
declare amt_bnd decimal (6, 3) default 0.001; -- fare amount matching boundry

##################################### optimize table 
optimize table  ws_dw.sales_tkt_fc;
optimize table  zz_ws.temp_tbl_fc_fare_map_chk ;

# ############################################################################################################## check cat 35 or cat 27  ##################################################################################
#####################################  CAT 35 + CAT 27 Checking for tourbox

/* 
the logic of tour code and b code
OK indicator: 1 if here is a tour code in ticket and we find a proper tour code in cat27 or cat35, set to 'y'
None indcator: if cat27 o cat35 does not ocntain tour code/B code then set it to 'y'
NA indicator: if there is no tour code or we cannt find a proper tour code, set it to 'y'
*/

-- for specified fare matching, set it default to "" (ie. N/A)
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
set ck.cat35_tourcd_ok_ind = "N",
ck.cat27_tourcd_ok_ind = "N",
ck.tourcd_na_ind = "Y",
ck.f_tourcd_none = "N";		-- set to Y for N/A, then set it to false if there are matched ones

# for non-FBR, set indicators on if tour code is found
-- check cat 35
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 35 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 35)
join atpco_fare.atpco_cat35 r3 on (r2s.tbl_nbr = r3.cat_id)
join atpco_fare.atpco_cat35_sup r3s on (r3.cat_id = r3s.cat_id and r3s.tour_box = mp.mod_tour_cd)
left join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.cat35_tourcd_ok_ind = "Y",
ck.fare_tour_cd = r3s.tour_box
where r3s.tour_box <> ""
and (mp.c25_r3_cat_id = 0 or fbr_r3.cat_ovrd35 = 'B')		# 2018-04-18, changed by TS, 2018-06-19, the null is not allowed, will be zero
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
left join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 35 and r2_mp.min_seq_ind = "Y")
left join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
left join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 35)
left join atpco_fare.atpco_cat35 r3 on (r2s.tbl_nbr = r3.cat_id)
left join atpco_fare.atpco_cat35_sup r3s on (r3.cat_id = r3s.cat_id )
left join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.f_tourcd_none = "Y"
#ck.fare_tour_cd = r3s.tour_box -- 2018-05-22 remove it
where (mp.c25_r3_cat_id = 0 or fbr_r3.cat_ovrd35 = 'B')		# 2018-04-18, changed by TS
 and ( r3s.tour_box = '' or r3s.tour_box is null )
;

-- check cat 27
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 27 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 27)
join atpco_fare.atpco_cat27 r3 on (r2s.tbl_nbr = r3.cat_id and r3.tour_nbr = mp.mod_tour_cd)
left join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.cat27_tourcd_ok_ind =  "Y",
ck.fare_tour_cd = r3.tour_nbr
where r3.tour_nbr <> ""
and (mp.c25_r3_cat_id = 0 or fbr_r3.cat_ovrd27 = 'B')		# 2018-04-18, changed by TS
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
left join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 27 and r2_mp.min_seq_ind = "Y")
left join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
left join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 27)
left join atpco_fare.atpco_cat27 r3 on (r2s.tbl_nbr = r3.cat_id)
left join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.f_tourcd_none =  "Y"
#ck.fare_tour_cd = r3.tour_nbr -- 2018-05-22 remove it
where (mp.c25_r3_cat_id = 0 or fbr_r3.cat_ovrd27 = 'B')		# 2018-04-18, changed by TS
and ( r3.tour_nbr = '' or r3.tour_nbr is null )
;

# for FBR, set indicators on if tour code is found		# 2018-04-18, added by TS
-- check cat 35
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 35 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 35)
join atpco_fare.atpco_cat35 r3 on (r2s.tbl_nbr = r3.cat_id)
join atpco_fare.atpco_cat35_sup r3s on (r3.cat_id = r3s.cat_id and r3s.tour_box = mp.mod_tour_cd)
join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.cat35_tourcd_ok_ind = "Y",
ck.fare_tour_cd = r3s.tour_box
where r3s.tour_box <> ""
and fbr_r3.cat_ovrd35 = 'X'
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
left join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 35 and r2_mp.min_seq_ind = "Y")
left join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
left join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 35)
left join atpco_fare.atpco_cat35 r3 on (r2s.tbl_nbr = r3.cat_id)
left join atpco_fare.atpco_cat35_sup r3s on (r3.cat_id = r3s.cat_id)
left join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.f_tourcd_none = "Y"
where fbr_r3.cat_ovrd35 = 'X'
and ( r3s.tour_box = '' or r3s.tour_box is null )
;

-- check cat 27
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 27 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 27)
join atpco_fare.atpco_cat27 r3 on (r2s.tbl_nbr = r3.cat_id and r3.tour_nbr = mp.mod_tour_cd)
join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.cat27_tourcd_ok_ind = "Y",
ck.fare_tour_cd = r3.tour_nbr
where r3.tour_nbr <> ""
and fbr_r3.cat_ovrd27 = 'X'
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
left join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 27 and r2_mp.min_seq_ind = "Y")
left join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
left join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 27)
left join atpco_fare.atpco_cat27 r3 on (r2s.tbl_nbr = r3.cat_id)
left join atpco_fare.atpco_cat25 fbr_r3 on (fbr_r3.cat_id = mp.c25_r3_cat_id)
set ck.f_tourcd_none = "Y"
where fbr_r3.cat_ovrd27 = 'X'
and ( r3.tour_nbr = '' or r3.tour_nbr is null )
;

#####################################  check the tour code
update zz_ws.temp_tbl_fc_fare_map_chk ck
set tourcd_ok_ind = if(cat35_tourcd_ok_ind = "Y" or cat27_tourcd_ok_ind = "Y", "Y",
						if(mod_tour_cd = "" and cat35_tourcd_ok_ind = "" and cat27_tourcd_ok_ind = "", "Y", "N"));

#####################################  create a qualified tour code veriation table
drop table if exists zz_ws.temp_tbl_fc_tourcd_ok;

create table zz_ws.temp_tbl_fc_tourcd_ok ENGINE = MyISAM
select distinct doc_nbr_prime, fc_cpn_nbr
from zz_ws.temp_tbl_fc_fare_map_chk
where mod_tour_cd <> ""
and tourcd_ok_ind = "Y";

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_tourcd_ok ok on (ck.doc_nbr_prime = ok.doc_nbr_prime and ck.fc_cpn_nbr = ok.fc_cpn_nbr)
set ck.tourcd_na_ind = "N";

# ############################################################################################################## check cat18 for B CODE  ##################################################################################
# ============================================================================================================================================================================================================================= #
#####################################  set the default value

-- for specified fare matching, set it default to "" (ie. N/A)
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
set ck.bcode_ok_ind = "",
ck.bcode_na_ind = "Y",
ck.f_bcode_none = "N";		-- set to Y for N/A, then set it to false if there are matched ones

-- check cat 18
-- specified
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 18 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 18)
join atpco_fare.atpco_cat18 r3 on (r2s.tbl_nbr = r3.cat_id)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and fc.fc_cpn_nbr = mp.fc_cpn_nbr and fc.trnsc_date = mp.trnsc_date and fc.carr_cd = mp.doc_carr_nbr 
set ck.bcode_ok_ind = if( INSTR(fc.tkt_endorse_cd, r3.endorse_txt) > 0 and fc.tkt_endorse_cd <> '', "Y", if(r3.endorse_txt = "" and fc.tkt_endorse_cd = "", "Y", "N"))
;
-- FBR
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 18 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 18)
join atpco_fare.atpco_cat18 r3 on (r2s.tbl_nbr = r3.cat_id)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and fc.fc_cpn_nbr = mp.fc_cpn_nbr and fc.trnsc_date = mp.trnsc_date and fc.carr_cd = mp.doc_carr_nbr 
set ck.bcode_ok_ind = if( INSTR(fc.tkt_endorse_cd, r3.endorse_txt) > 0 and fc.tkt_endorse_cd <> '', "Y", if(r3.endorse_txt = "" and fc.tkt_endorse_cd = "", "Y", "N"))
;

-- specified
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 18 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 18)
join atpco_fare.atpco_cat18 r3 on (r2s.tbl_nbr = r3.cat_id)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and fc.fc_cpn_nbr = mp.fc_cpn_nbr and fc.trnsc_date = mp.trnsc_date and fc.carr_cd = mp.doc_carr_nbr 
set ck.f_bcode_none = if( INSTR(fc.tkt_endorse_cd, r3.endorse_txt) > 0 and fc.tkt_endorse_cd = '', "Y",  "N")
;
-- FBR
update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = 18 and r2_mp.min_seq_ind = "Y")
join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 18)
join atpco_fare.atpco_cat18 r3 on (r2s.tbl_nbr = r3.cat_id)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and fc.fc_cpn_nbr = mp.fc_cpn_nbr and fc.trnsc_date = mp.trnsc_date and fc.carr_cd = mp.doc_carr_nbr 
set ck.f_bcode_none = if( INSTR(fc.tkt_endorse_cd, r3.endorse_txt) > 0 and fc.tkt_endorse_cd = '', "Y", "N")
;

#####################################  create a qualified bcode code veriation table
drop table if exists zz_ws.temp_tbl_fc_bcode_ok;

create table zz_ws.temp_tbl_fc_bcode_ok ENGINE = MyISAM
select distinct c.doc_nbr_prime, c.fc_cpn_nbr
from zz_ws.temp_tbl_fc_fare_map_chk c
join ws_dw.sales_tkt_fc fc on c.doc_nbr_prime = fc.doc_nbr_prime and fc.fc_cpn_nbr = c.fc_cpn_nbr
where fc.tkt_endorse_cd <> ""
and bcode_ok_ind = "Y";

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_bcode_ok ok on (ck.doc_nbr_prime = ok.doc_nbr_prime and ck.fc_cpn_nbr = ok.fc_cpn_nbr)
set ck.bcode_na_ind = "N";

# ############################################################################################################## cat 19 to 22 looping for discount ##################################################################################
# ============================================================================================================================================================================================================================= #
#####################################  create table
drop table if exists zz_ws.temp_tbl_fc_cat_fbr;
drop table if exists zz_ws.temp_tbl_fc_cat_spec;

-- change on 2018-05-22, create table by mysql workbench creating function
CREATE TABLE if not exists zz_ws.temp_tbl_fc_cat_fbr (
  fc_fare_map_id int(11) NOT NULL,
  rule_id int(11) unsigned NOT NULL DEFAULT '0',
  pax_type char(3) DEFAULT NULL,
  fare_ind char(1) DEFAULT NULL,
  base_pct decimal(7,4) DEFAULT NULL,
  spec_fare1_amt decimal(14,4) DEFAULT NULL,
  spec_fare1_curr char(3) DEFAULT NULL,
  fbc_rule varchar(25) DEFAULT NULL,
  dsg_rule varchar(29) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE if not exists zz_ws.temp_tbl_fc_cat_spec (
  fc_fare_map_id int(11) NOT NULL,
  rule_id int(11) unsigned NOT NULL DEFAULT '0',
  pax_type char(3) DEFAULT NULL,
  fare_ind char(1) DEFAULT NULL,
  base_pct decimal(7,4) DEFAULT NULL,
  spec_fare1_amt decimal(14,4) DEFAULT NULL,
  spec_fare1_curr char(3) DEFAULT NULL,
  fbc_rule varchar(25) DEFAULT NULL,
  dsg_rule varchar(29) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

#####################################  start the looping
set @r_cat := 19;

while @r_cat <= 22 Do

set @s = CONCAT('
update zz_ws.temp_tbl_fc_fare_map mp
join zz_ws.temp_tbl_fc_fare_map_chk ck on (ck.fc_fare_map_id = mp.fc_fare_map_id)
join atpco_fare.atpco_cat25 r3 on (r3.cat_id = mp.c25_r3_cat_id)
set ck.fbr_disc_ovrd = r3.cat_ovrd', 
@r_cat, 
' where mp.c25_r3_cat_id > 0;');

PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- using the specified fares

set @s = CONCAT('
insert into zz_ws.temp_tbl_fc_cat_spec 
select ck.fc_fare_map_id, r2.rule_id, r3.pax_type, r3.fare_ind, r3.base_pct, r3.spec_fare1_amt, r3.spec_fare1_curr, 
concat(
    -- before the ticketing code modifier
    (case
        when r3.rslt_tkt_cd <> '''' then r3.rslt_tkt_cd
        when r3.rslt_fare_cls <> '''' then r3.rslt_fare_cls
        else ''''
    end),
    -- append the ticketing code modifier
    (case r3.tkt_cd_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, tcm <> 3''
    end)
 ) as fbc_rule,
 
 concat(r3.tkt_dsg,
    -- append the ticketing code modifier
    (case r3.tkt_dsg_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, dsg_mod <> 3''
    end)
) as dsg_rule

from zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = @r_cat and r2_mp.min_seq_ind = ''Y'')
straight_join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
straight_join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = @r_cat)
straight_join atpco_fare.atpco_cat', 
@r_cat, 
' r3 on (r2s.tbl_nbr = r3.cat_id and r3.no_appl = '''')
where (mp.map_type <> ''R''                                    -- matched to specified fares or constructed fares
    or (mp.map_type = ''R'' and ck.fbr_disc_ovrd = ''B'')        -- fare by rule, but use base fare
    or (mp.map_type = ''R'' and ck.fbr_disc_ovrd = ''''))        -- Blank = Provisions apply in combination with like category provisions in the base Fare rule.
;');

PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

# ######################################## alterative general rule

set @s = CONCAT('
insert into zz_ws.temp_tbl_fc_cat_spec
select ck.fc_fare_map_id, r2.rule_id, r3.pax_type, r3.fare_ind, r3.base_pct, r3.spec_fare1_amt, r3.spec_fare1_curr, 
concat(
    -- before the ticketing code modifier
    (case
        when r3.rslt_tkt_cd <> '''' then r3.rslt_tkt_cd
        when r3.rslt_fare_cls <> '''' then r3.rslt_fare_cls
        else ''''
    end),
    -- append the ticketing code modifier
    (case r3.tkt_cd_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, tcm <> 3''
    end)
 ) as fbc_rule,
 
 concat(r3.tkt_dsg,
    -- append the ticketing code modifier
    (case r3.tkt_dsg_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, dsg_mod <> 3''
    end)
) as dsg_rule

from zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_fare_map_sr1 r1_mp on (r1_mp.fc_fare_map_id = ck.fc_fare_map_id and r1_mp.min_seq_ind = ''Y'')
straight_join zz_ws.temp_tbl_fc_fare_map_sr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = @r_cat and r2_mp.min_seq_ind = ''Y'')
straight_join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
straight_join atpco_fare.atpco_r2_cat_ctrl r2a on 
(r2a.carr_cd = r2.carr_cd and r2a.tar_nbr = r2.gr_src_tar_nbr and r2a.rule_nbr = r2.gr_rule_nbr and ( r1_mp.fare_type = r2a.fare_type or r2a.fare_type = '''' or r1_mp.fare_type = '''' ) and r2a.cat_nbr = @r_cat and r2a.proc_ind in (''N'', ''R''))
-- not fully correct but should be enough as alternate general rule is general
straight_join atpco_fare.atpco_r2_cat_ctrl_state r2at on (r2at.rule_id = r2a.rule_id)
straight_join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2s.rule_id = r2a.rule_id and r2s.cat_nbr = @r_cat)
straight_join atpco_fare.atpco_cat', 
@r_cat, 
' r3 on (r2s.tbl_nbr = r3.cat_id and r3.no_appl = '''')
where (mp.map_type <> ''R''                                    -- matched to specified fares or constructed fares
    or (mp.map_type = ''R'' and ck.fbr_disc_ovrd = ''B'')        -- fare by rule, but use base fare
    or (mp.map_type = ''R'' and ck.fbr_disc_ovrd = ''''))        -- Blank = Provisions apply in combination with like category provisions in the base Fare rule.
;');

PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

# ######################################## alterative general rule

-- disc using FBR


set @s = CONCAT('
insert into zz_ws.temp_tbl_fc_cat_fbr
select ck.fc_fare_map_id, r2.rule_id, r3.pax_type, r3.fare_ind, r3.base_pct, r3.spec_fare1_amt, r3.spec_fare1_curr, 
concat(
    -- before the ticketing code modifier
    (case
        when r3.rslt_tkt_cd <> '''' then r3.rslt_tkt_cd
        when r3.rslt_fare_cls <> '''' then r3.rslt_fare_cls
        else ''''
    end),
    -- append the ticketing code modifier
    (case r3.tkt_cd_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, tcm <> 3''
    end)
 ) as fbc_rule,
 
 concat(r3.tkt_dsg,
    -- append the ticketing code modifier
    (case r3.tkt_dsg_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, dsg_mod <> 3''
    end)
) as dsg_rule

from zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = @r_cat and r2_mp.min_seq_ind = "Y")
straight_join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
straight_join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = @r_cat)
straight_join atpco_fare.atpco_cat', 
@r_cat, 
' r3 on (r2s.tbl_nbr = r3.cat_id and r3.no_appl = '''')
where ((mp.map_type = "R" and ck.fbr_disc_ovrd = "X")                                -- fare by rule, override
    or (mp.map_type = "R" and ck.fbr_disc_ovrd = "" and ck.disc_r2_id is null))        -- Blank, if not set during checking with specified fare, then try again with fbr rule
;');

PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;


set @s = CONCAT('
insert into zz_ws.temp_tbl_fc_cat_fbr
select ck.fc_fare_map_id, r2.rule_id, r3.pax_type, r3.fare_ind, r3.base_pct, r3.spec_fare1_amt, r3.spec_fare1_curr, 
concat(
    -- before the ticketing code modifier
    (case
        when r3.rslt_tkt_cd <> '''' then r3.rslt_tkt_cd
        when r3.rslt_fare_cls <> '''' then r3.rslt_fare_cls
        else ''''
    end),
    -- append the ticketing code modifier
    (case r3.tkt_cd_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, tcm <> 3''
    end)
 ) as fbc_rule,
 
 concat(r3.tkt_dsg,
    -- append the ticketing code modifier
    (case r3.tkt_dsg_mod
        when '''' then ''''
        when ''3'' then if(r3.base_pct = 1.00, ''00'', 100 - round(r3.base_pct*100, 0))
        else ''Error, dsg_mod <> 3''
    end)
) as dsg_rule

from zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_fare_map_fr1 r1_mp on (r1_mp.fc_fare_map_id = ck.fc_fare_map_id )
straight_join zz_ws.temp_tbl_fc_fare_map_fr2 r2_mp on (r2_mp.fc_fare_map_id = ck.fc_fare_map_id and r2_mp.r2_cat_nbr = @r_cat and r2_mp.min_seq_ind = "Y")
straight_join atpco_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
straight_join atpco_fare.atpco_r2_cat_ctrl r2a on 
(r2a.carr_cd = r2.carr_cd and r2a.tar_nbr = r2.gr_src_tar_nbr and r2a.rule_nbr = r2.gr_rule_nbr and (r1_mp.rslt_fare_type = r2a.fare_type or r1_mp.rslt_fare_type = '''' or r2a.fare_type = '''' ) and r2a.cat_nbr = @r_cat and r2a.proc_ind in (''N'', ''R''))
-- not fully correct but should be enough as alternate general rule is general
straight_join atpco_fare.atpco_r2_cat_ctrl_state r2at on (r2at.rule_id = r2a.rule_id)
straight_join atpco_fare.atpco_r2_cat_ctrl_sup r2s on (r2s.rule_id = r2a.rule_id and r2s.cat_nbr = @r_cat)
straight_join atpco_fare.atpco_cat',
@r_cat, 
' r3 on (r2s.tbl_nbr = r3.cat_id and r3.no_appl = '''')
where ((mp.map_type = "R" and ck.fbr_disc_ovrd = "X")                                -- fare by rule, override
    or (mp.map_type = "R" and ck.fbr_disc_ovrd = "" and ck.disc_r2_id is null))        -- Blank, if not set during checking with specified fare, then try again with fbr rule
;');

PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

set @r_cat := @r_cat + 1;
END While;

ALTER TABLE zz_ws.temp_tbl_fc_cat_spec ADD INDEX `idx` (`fc_fare_map_id` ASC);
optimize table zz_ws.temp_tbl_fc_cat_spec;
ALTER TABLE zz_ws.temp_tbl_fc_cat_fbr ADD INDEX `idx` (`fc_fare_map_id` ASC);
optimize table zz_ws.temp_tbl_fc_cat_fbr;

-- change in 2018-05-22, the following codes do not need to be looped

############################## for SPEC cat19-22 discount 
# if the fc matches to the tkt code or dsg patten, then we are sure it is the cat that discounts it
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_cat_spec cx on (cx.fc_fare_map_id = ck.fc_fare_map_id)
set ck.disc_r2_id = cx.rule_id,
ck.disc_fare_ind = cx.fare_ind,
ck.disc_base_pct = cx.base_pct,
ck.disc_spec_amt = cx.spec_fare1_amt,
ck.disc_spec_curr = cx.spec_fare1_curr,
ck.fare_pax_type = cx.pax_type
where
if(cx.dsg_rule = '' and cx.fbc_rule = '', false,
    (mp.fc_tkt_dsg = cx.dsg_rule)
    and
    (case
        when left(cx.fbc_rule,1) = '*' then right(mp.fc_fbc, length(cx.fbc_rule)-1) = right(cx.fbc_rule, length(cx.fbc_rule)-1)
        when left(cx.fbc_rule,1) = '-' then right(mp.fc_fbc, length(cx.fbc_rule)-1) = right(cx.fbc_rule, length(cx.fbc_rule)-1)
        when right(cx.fbc_rule,1) = '-' then left(mp.fc_fbc, length(cx.fbc_rule)-1) = left(cx.fbc_rule, length(cx.fbc_rule)-1)
        else if(cx.fbc_rule <> '', mp.fc_fbc = cx.fbc_rule, true)
    end)
)
;

# other wise, we use the pax type supplied from analysing sales
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_cat_spec cx on (cx.fc_fare_map_id = ck.fc_fare_map_id)
set ck.disc_r2_id = cx.rule_id,
ck.disc_fare_ind = cx.fare_ind,
ck.disc_base_pct = cx.base_pct,
ck.disc_spec_amt = cx.spec_fare1_amt,
ck.disc_spec_curr = cx.spec_fare1_curr,
ck.fare_pax_type = cx.pax_type
where ck.disc_r2_id is null            # ie. have not been updated by the previous matching
and (mp.fc_pax_type = cx.pax_type or ( mp.fc_pax_type = 'ADT' and cx.pax_type = '' ) )    # then matches to pax type
;

############################## for FBR cat19-22 discount
# if the fc matches to the tkt code or dsg patten, then we are sure it is the cat that discounts it
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_cat_fbr cx on (cx.fc_fare_map_id = ck.fc_fare_map_id)
set ck.disc_r2_id = cx.rule_id,
ck.disc_fare_ind = cx.fare_ind,
ck.disc_base_pct = cx.base_pct,
ck.disc_spec_amt = cx.spec_fare1_amt,
ck.disc_spec_curr = cx.spec_fare1_curr,
ck.fare_pax_type = cx.pax_type
where
if(cx.dsg_rule = '' and cx.fbc_rule = '', false,
    (mp.fc_tkt_dsg = cx.dsg_rule)
    and
    (case
        when left(cx.fbc_rule,1) = '*' then right(mp.fc_fbc, length(cx.fbc_rule)-1) = right(cx.fbc_rule, length(cx.fbc_rule)-1)
        when left(cx.fbc_rule,1) = '-' then right(mp.fc_fbc, length(cx.fbc_rule)-1) = right(cx.fbc_rule, length(cx.fbc_rule)-1)
        when right(cx.fbc_rule,1) = '-' then left(mp.fc_fbc, length(cx.fbc_rule)-1) = left(cx.fbc_rule, length(cx.fbc_rule)-1)
        else if(cx.fbc_rule <> '', mp.fc_fbc = cx.fbc_rule, true)
    end)
)
;

# other wise, we use the pax type supplied from analysing sales
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_cat_fbr cx on (cx.fc_fare_map_id = ck.fc_fare_map_id)
set ck.disc_r2_id = cx.rule_id,
ck.disc_fare_ind = cx.fare_ind,
ck.disc_base_pct = cx.base_pct,
ck.disc_spec_amt = cx.spec_fare1_amt,
ck.disc_spec_curr = cx.spec_fare1_curr,
ck.fare_pax_type = cx.pax_type
where ck.disc_r2_id is null            # ie. have not been updated by the previous matching
and (mp.fc_pax_type = cx.pax_type or ( mp.fc_pax_type = 'ADT' and cx.pax_type = '' ) )   # then matches to pax type
;

# ##############################################################################################################   Financial calculations      ##################################################################################
# ============================================================================================================================================================================================================================= #

#####################################   initialize
optimize table zz_ws.temp_tbl_fc_fare_map;
-- firstly retrieve from all specified fares
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map_sr1 r1mp on (r1mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_r1_fare_cls r1 on (r1.rule_id = r1mp.r1_rule_id and r1mp.min_seq_ind = "Y")
set ck.fare_dis_type = r1.dis_type;

-- then check if the tags were overwritten by CAT25
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_cat25 c25 on (c25.cat_id = mp.c25_r3_cat_id)
set ck.fare_dis_type = if(c25.rslt_fare_disp_type = "", ck.fare_dis_type, c25.rslt_fare_disp_type)
where mp.c25_r3_cat_id > 0 and mp.c25_r3_cat_id<>"";

update zz_ws.temp_tbl_fc_fare_map_chk
set spec_fare_curr = "",
oadd_fare_curr = "",
dadd_fare_curr = "",
fbr_fare_curr = "",
fare_rt_ind = "",
fare_dir_ind = '';

# ------------------------------------------------------------------------------------------------
/*
the logic of currency exchange
1 if all fare components incluing specified amount, addon amoutn etc. are at the same currency, use BSR (simple rue)
2 otherwise use ROE and BSR both (complex rule)
*/
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join genie.iata_icer cer on (cer.curr_frm = f.orig_fare_curr and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)
set 
spec_fare_amt_tkt_alt = if( cer.bsr is null, f.orig_fare_amt, f.orig_fare_amt * cer.bsr ),
ck.int_dom_ind = f.int_dom_ind
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join genie.iata_iroe rf on ( rf.eff_year = year(mp.trnsc_date) and rf.eff_month = month(mp.trnsc_date) and rf.curr_cd = f.orig_fare_curr )
left join genie.iata_iroe rp on ( rp.eff_year = year(mp.trnsc_date) and rp.eff_month = month(mp.trnsc_date) and rp.curr_cd = mp.fc_curr_cd )
left join genie.iata_icer cer on (cer.curr_frm = mp.fc_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)

set spec_fare_amt_nuc = (@v1 := f.orig_fare_amt * (1.00 + ck.fc_mile_plus) / rf.roe ),
spec_fare_amt_fc = (@v2 := @v1 * rp.roe ),
spec_fare_amt_tkt = if( cer.bsr is null, (@v3 := @v2 ),  (@v3 := @v2 * cer.bsr) ) ,
spec_fare_curr = orig_fare_curr,
ck.fc_curr = mp.fc_curr_cd,
ck.int_dom_ind = f.int_dom_ind
;

-- halve the fare if the fare is for RT
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
set fare_rt_ind = if(f.ow_rt_ind = 1 or f.ow_rt_ind = 3 or (f.ow_rt_ind = 2 and f.global in ("RW", "CT")), 1, 2),
fare_dir_ind = 
	(case mp.map_di_ind
		when 'F' then
			case f.di
				when 'F' then 'F'
				when 'T' then 'R'
				else 'B'	# when fare di is ''/blank, between or bi-directional
			end
		when 'R' then
			case f.di
				when 'F' then 'R'
				when 'T' then 'F'
				else 'B'	# when fare di is ''/blank, between or bi-directional
			end
		else ''
	end)
where map_type <> "R"; -- For FBR, must not halve the specified fares for now, even ow_rt_ind = 2, must wait until FBR calculation has completed

update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
set spec_fare_amt_tkt = round(spec_fare_amt_tkt /2, 2),
spec_fare_amt_tkt_alt = round(spec_fare_amt_tkt_alt /2, 2)
where fare_rt_ind = '2' and mp.map_type <> "R";

#####################################  addon calculation

-- add-on fare, orign add-on

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join atpco_fare.atpco_addon f on (f.fare_id = mp.oadd_fare_id)
left join genie.iata_icer cer on (cer.curr_frm = f.addon_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)

set oadd_fare_amt_tkt_alt = if( cer.bsr is null, f.addon_amt / if(f.ow_rt_ind = 2, 2, 1), f.addon_amt / if(f.ow_rt_ind = 2, 2, 1) * cer.bsr)
#where f.addon_curr_cd <> ck.tkt_curr_cd
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join atpco_fare.atpco_addon f on (f.fare_id = mp.oadd_fare_id)
left join genie.iata_iroe rf on ( rf.eff_year = year(mp.trnsc_date) and rf.eff_month = month(mp.trnsc_date) and rf.curr_cd = f.addon_curr_cd)
left join genie.iata_iroe rp on ( rp.eff_year = year(mp.trnsc_date) and rp.eff_month = month(mp.trnsc_date) and rp.curr_cd = mp.fc_curr_cd)
left join genie.iata_icer cer on (cer.curr_frm = mp.fc_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)

set oadd_fare_amt_nuc = (@v1 := f.addon_amt / if(f.ow_rt_ind = 2, 2, 1)  / rf.roe ),
oadd_fare_amt_fc = (@v2 := @v1 * rp.roe ),
oadd_fare_amt_tkt = if( cer.bsr is null, (@v3 := @v2 ),  (@v3 := @v2 * cer.bsr) ) ,
oadd_fare_curr = f.addon_curr_cd
;

-- add-on fare, dest add-on

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join atpco_fare.atpco_addon f on (f.fare_id = mp.dadd_fare_id)
left join genie.iata_icer cer on (cer.curr_frm = f.addon_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)

set dadd_fare_amt_tkt_alt = if( cer.bsr is null, f.addon_amt / if(f.ow_rt_ind = 2, 2, 1),  (f.addon_amt / if(f.ow_rt_ind = 2, 2, 1) * cer.bsr) )
#where f.addon_curr_cd <> ck.tkt_curr_cd
;

update zz_ws.temp_tbl_fc_fare_map_chk ck
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
join atpco_fare.atpco_addon f on (f.fare_id = mp.dadd_fare_id)
left join genie.iata_iroe rf on ( rf.eff_year = year(mp.trnsc_date) and rf.eff_month = month(mp.trnsc_date) and rf.curr_cd = f.addon_curr_cd)
left join genie.iata_iroe rp on ( rp.eff_year = year(mp.trnsc_date) and rp.eff_month = month(mp.trnsc_date) and rp.curr_cd = mp.fc_curr_cd)
left join genie.iata_icer cer on (cer.curr_frm = mp.fc_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)

set dadd_fare_amt_nuc = (@v1 := f.addon_amt / if(f.ow_rt_ind = 2, 2, 1)  / rf.roe ),
dadd_fare_amt_fc = (@v2 := @v1 * rp.roe ),
dadd_fare_amt_tkt = if( cer.bsr is null, (@v3 := @v2 ),  (@v3 := @v2 * cer.bsr) ) ,
dadd_fare_curr = f.addon_curr_cd
;



#####################################  FBR calculation
-- FBR

-- must calculate the fare first, then decide if it should be halved, becase fbr could modify the ow_rt_ind
-- C: calculated
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
straight_join atpco_fare.atpco_cat25 c25 on (c25.cat_id = mp.c25_r3_cat_id)
set fbr_fare_amt_tkt = spec_fare_amt_tkt * c25.fcalc_pct,
fbr_fare_amt_tkt_alt = spec_fare_amt_tkt_alt * c25.fcalc_pct,
fbr_fare_curr = spec_fare_curr
where c25.fcalc_ind in ( "C")
;

-- Not C, calculate the specified amount
/*
the logic of specified amount selection:
1 if there is one amout and one currency apply it
2 if there are ultiple currencies (typically 2), apply the currency that matches the currency in the original city. If none of them matches, then fail the case 
*/
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
straight_join atpco_fare.atpco_cat25 c25 on (c25.cat_id = mp.c25_r3_cat_id)
straight_join genie.iata_iroe rf on rf.eff_year = year(mp.trnsc_date) and rf.eff_month = month(mp.trnsc_date)  -- it must exist or must fail the record
and rf.curr_cd =  ( @curr := if( c25.fcalc_spec_curr2 = mp.fc_curr_cd, c25.fcalc_spec_curr2, 
if( c25.fcalc_spec_curr1 = mp.fc_curr_cd or c25.fcalc_spec_curr2 = '', c25.fcalc_spec_curr1, null) 
) )
straight_join genie.iata_iroe rp on ( rp.eff_year = year(mp.trnsc_date) and rp.eff_month = month(mp.trnsc_date) and rp.curr_cd = mp.fc_curr_cd)
left join genie.iata_icer cer on (cer.curr_frm = mp.fc_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)
set fbr_fixed_amt_nuc = ( @v1 := if( c25.fcalc_spec_curr2 = mp.fc_curr_cd, c25.fcalc_spec_amt2, 
if( c25.fcalc_spec_curr1 = mp.fc_curr_cd or c25.fcalc_spec_curr2 = '', c25.fcalc_spec_amt1, null) 
) / rf.roe ),
fbr_fare_curr_fixed = if( c25.fcalc_spec_curr2 = mp.fc_curr_cd, c25.fcalc_spec_curr2, 
if( c25.fcalc_spec_curr1 = mp.fc_curr_cd or c25.fcalc_spec_curr2 = '', c25.fcalc_spec_curr1, null) 
),
fbr_fixed_amt_fc = (@v2 := @v1 * rp.roe ),
fbr_fixed_amt_tkt = if( ck.tkt_curr_cd = @curr ,
 if( c25.fcalc_spec_curr2 = mp.fc_curr_cd, c25.fcalc_spec_amt2, 
if( c25.fcalc_spec_curr1 = mp.fc_curr_cd or c25.fcalc_spec_curr2 = '', c25.fcalc_spec_amt1, null) 
), 
 if( cer.bsr is null, (@v3 := @v2 ),  (@v3 := @v2 * cer.bsr) ) )   -- if tkt_curr = cat25_curr then fixed_amt = cat25_amt, or it will be converted according to icer.bsr
where c25.fcalc_ind not in ( "C")
;

-- combine the percentage part and the specified part according to calculated types
-- G: calculated after substracting a specified amount
-- B: calculated after adding a specified amount
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
straight_join atpco_fare.atpco_cat25 c25 on (c25.cat_id = mp.c25_r3_cat_id)
set fbr_fare_amt_tkt = ( spec_fare_amt_tkt + ( fbr_fixed_amt_tkt * if( c25.fcalc_ind  = "B", 1, -1)) ) * c25.fcalc_pct,
fbr_fare_amt_tkt_alt = ( spec_fare_amt_tkt_alt + ( fbr_fixed_amt_tkt * if( c25.fcalc_ind  = "B", 1, -1)) ) * c25.fcalc_pct,
fbr_fare_curr = f.orig_fare_curr
where c25.fcalc_ind in ( "G", "B");

-- A: add calculated to specified
-- M: subtract specified from calculated
-- S: Specified
-- K: Specified in alternate currency
-- BSR is used insted of ROE, may need to improve one day
-- fcalc_spec_amt2 is not considered at the moment, it should be used when we consider which currency/pos to use

-- This is not entirely correct, for the fixed amount, it is not converted using ROE.
-- The risk is low because FBR tends to be for a specific country, for the same base fare (with the same currency code)
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_cat25 c25 on (c25.cat_id = mp.c25_r3_cat_id)
#left join genie.iata_icer cer on (cer.curr_frm = mp.fc_curr_cd and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)
set fbr_fare_amt_tkt = round(spec_fare_amt_tkt * if(c25.fcalc_ind in ("S", "K"), 0.0, c25.fcalc_pct) + fbr_fixed_amt_tkt * if(c25.fcalc_ind = "M", -1.0, 1.0), 2),
fbr_fare_amt_tkt_alt = round(spec_fare_amt_tkt_alt * if(c25.fcalc_ind in ("S", "K"), 0.0, c25.fcalc_pct) + fbr_fixed_amt_tkt * if(c25.fcalc_ind = "M", -1.0, 1.0), 2),
fbr_fare_curr = spec_fare_curr,
fbr_spec_pct = round( fbr_fixed_amt_tkt / (spec_fare_amt_tkt * if(c25.fcalc_ind in ("S", "K"), 0.0, c25.fcalc_pct) + fbr_fixed_amt_tkt * if(c25.fcalc_ind = "M", -1.0, 1.0)), 4),
fbr_spec_pct_alt = round( fbr_fixed_amt_tkt / (spec_fare_amt_tkt_alt * if(c25.fcalc_ind in ("S", "K"), 0.0, c25.fcalc_pct) + fbr_fixed_amt_tkt * if(c25.fcalc_ind = "M", -1.0, 1.0)), 4)
where c25.fcalc_ind in ("A", "M", "S", "K");

/*
-- Other methods are not implemented yet
*/


-- determine the one-way return indicator, just for easier comparison to see if there is a discount
-- this can only be done after fbr_amount is computed
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
set fare_rt_ind = if(f.ow_rt_ind = 1 or f.ow_rt_ind = 3 or (f.ow_rt_ind = 2 and f.global in ("RW", "CT")), 1, 2),
fare_dir_ind = 
	(case mp.map_di_ind
		when 'F' then
			case f.di
				when 'F' then 'F'
				when 'T' then 'R'
				else 'B'	# when fare di is ''/blank
			end
		when 'R' then
			case f.di
				when 'F' then 'R'
				when 'T' then 'F'
				else 'B'	# when fare di is ''/blank
			end
		else ''
	end)
-- set fare_rt_ind = if(f.ow_rt_ind = 1 or f.ow_rt_ind = 3 or (f.ow_rt_ind = 2 and f.global in ("RW", "CT")), "N", "Y")
where map_type = "R";

-- if reslting fare ow_rt is modified and hence ow > rt or rt > ow
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_cat25 c25 on (c25.cat_id = mp.c25_r3_cat_id)
set fare_rt_ind = if(c25.rslt_fare_ow_rt_ind = 1 or c25.rslt_fare_ow_rt_ind = 3 or (c25.rslt_fare_ow_rt_ind = 2 and c25.rslt_fare_global in ("RW", "CT")), 1, 2)
where c25.rslt_fare_ow_rt_ind <> "";

-- and fare_rt_ind <> if(c25.rslt_fare_ow_rt_ind = 1 or c25.rslt_fare_ow_rt_ind = 3 or (c25.rslt_fare_ow_rt_ind = 2 and c25.rslt_fare_global in ("RW", "CT")), 1, 2) ;

 /*
update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join atpco_fare.atpco_cat25 c25 on ( mp.c25_r3_cat_id = c25.cat_id )
straight_join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
set
fare_rt_ind =
if(c25.rslt_fare_ow_rt_ind ='', 
if(f.ow_rt_ind = 1 or f.ow_rt_ind = 3 or (f.ow_rt_ind = 2 and f.global in ("RW", "CT")), "N", "Y"), 
if(c25.rslt_fare_ow_rt_ind = 1 or c25.rslt_fare_ow_rt_ind = 3 or (c25.rslt_fare_ow_rt_ind = 2 and c25.rslt_fare_global in ("RW", "CT")), "N", "Y")) 
where mp.map_type = "R";
*/

update zz_ws.temp_tbl_fc_fare_map_chk ck
set fbr_fare_amt_tkt = round( fbr_fare_amt_tkt /2, 3),
fbr_fare_amt_tkt_alt = round( fbr_fare_amt_tkt_alt /2, 3)
where fare_rt_ind = '2'
and fbr_fare_amt_tkt is not null
-- we only devide fbr fare amount by 2
;

#####################################  discount calculation
-- determine if disc modified the amount the pax should pay

/*
the currency exchange calculatio follow the similar rule as simple/complex (search simple rule)
*/

update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)

left join genie.iata_iroe rf on ( rf.eff_year = year(mp.trnsc_date) and rf.eff_month = month(mp.trnsc_date) and rf.curr_cd = ck.disc_spec_curr)
left join genie.iata_iroe rp on ( rp.eff_year = year(mp.trnsc_date) and rp.eff_month = month(mp.trnsc_date) and rp.curr_cd = mp.fc_curr_cd)
left join genie.iata_icer cer on (cer.curr_frm = ck.disc_spec_curr and cer.curr_to = ck.tkt_curr_cd and cer.eff_date = mp.trnsc_date)

set disc_fare_amt_nuc = ( @v1 := (ck.disc_spec_amt / rf.roe) / if(fare_rt_ind = "Y", 2.0, 1.0) ),
disc_fare_amt_fc = ( @v2 := @v1 * rp.roe),
disc_fare_amt_tkt = if( cer.bsr is null, (@v3 := @v2 ),  (@v3 := @v2 * cer.bsr) ),
disc_fare_amt_tkt_alt = round((ck.disc_spec_amt) / if(fare_rt_ind = "Y", 2.0, 1.0), 2)
where disc_r2_id is not null
and disc_fare_ind = "S"
and ck.disc_spec_curr <> ck.tkt_curr_cd;		-- specified fixed amount

update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
set disc_fare_amt_tkt = round((ck.disc_spec_amt) / if(fare_rt_ind = "Y", 2.0, 1.0), 2),
disc_fare_amt_tkt_alt = round((ck.disc_spec_amt) / if(fare_rt_ind = "Y", 2.0, 1.0), 2)
where disc_r2_id is not null
and disc_fare_ind = "S"
and ck.disc_spec_curr = ck.tkt_curr_cd;		-- specified fixed amount

update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
set disc_fare_amt_tkt = round(if(mp.map_type in ("S", "C"), (ck.spec_fare_amt_tkt + ck.oadd_fare_amt_tkt + ck.dadd_fare_amt_tkt), ck.fbr_fare_amt_tkt) * ck.disc_base_pct, 2),
disc_fare_amt_tkt_alt = round(if(mp.map_type in ("S", "C"), (ck.spec_fare_amt_tkt_alt + ck.oadd_fare_amt_tkt + ck.dadd_fare_amt_tkt), ck.fbr_fare_amt_tkt_alt) * ck.disc_base_pct, 2)

where disc_r2_id is not null
and disc_fare_ind in ( "C", "R");		-- calculated based on percentage

##################################### determing the amount to use for later checking
-- if all currency the same, then this fare omponent can be regarded as possile for simple rule, otherwise apply the complex rule
update zz_ws.temp_tbl_fc_fare_map_chk ck
set final_fare_amt = if( disc_fare_amt_tkt is not null, disc_fare_amt_tkt, if(fbr_fare_amt_tkt is not null, fbr_fare_amt_tkt, spec_fare_amt_tkt + oadd_fare_amt_tkt + dadd_fare_amt_tkt )),
final_fare_amt_alt = if( disc_fare_amt_tkt_alt is not null, disc_fare_amt_tkt_alt, if(fbr_fare_amt_tkt_alt is not null, fbr_fare_amt_tkt_alt, spec_fare_amt_tkt_alt + oadd_fare_amt_tkt_alt + dadd_fare_amt_tkt_alt )),
o_same_curr_ind = if( oadd_fare_curr = "" or oadd_fare_curr = spec_fare_curr,  '1', '0'), 
d_same_curr_ind = if( dadd_fare_curr = "" or dadd_fare_curr = spec_fare_curr,  '1', '0'),
dis_same_curr_ind = if( disc_spec_curr = "" or disc_spec_curr = spec_fare_curr,  '1', '0'),
same_curr_ind = if( dadd_fare_curr = "" or dadd_fare_curr = spec_fare_curr,  '1', '0') and if( oadd_fare_curr = "" or oadd_fare_curr = spec_fare_curr,  '1', '0') and if( disc_spec_curr = "" or disc_spec_curr = spec_fare_curr,  '1', '0')
;

# =============================================================================================================================================================================================================================

drop table if exists zz_ws.temp_tbl_fc_seq;

CREATE TABLE zz_ws.temp_tbl_fc_seq (
  doc_nbr_prime BIGINT NOT NULL,
  carr_cd CHAR(3) NOT NULL,
  trnsc_date DATE NOT NULL,
  fc_seq_nbr TINYINT NOT NULL AUTO_INCREMENT,
  fc_cpn_nbr TINYINT NOT NULL,
  fc_cpns varchar(45) NOT NULL,

  UNIQUE INDEX idx (doc_nbr_prime ASC, carr_cd ASC, trnsc_date ASC, fc_seq_nbr ASC))
ENGINE = MyISAM;

#####################################  decide the sequence
-- Need to pick the right "fare" if there are multiple matches
-- create a table with all sequences (fc_cpn_nbr can leave gaps in the sequence)

insert into zz_ws.temp_tbl_fc_seq (doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, fc_cpns)
select distinct doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, fc_cpns
from ws_dw.sales_tkt_fc
where doc_nbr_prime not in (select doc_nbr_prime from ws_dw.sales_tkt_fc_err)				-- it is not harmful to run it but why?
order by doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr;

optimize table zz_ws.temp_tbl_fc_seq;

drop table if exists zz_ws.temp_tbl_fc_agg;

CREATE TABLE zz_ws.temp_tbl_fc_agg (
  doc_nbr_prime BIGINT NOT NULL,
  carr_cd CHAR(3) NOT NULL,
  trnsc_date DATE NOT NULL,

  tkt_fare_amt decimal(14,4) NOT NULL DEFAULT 0.0,
  eff_comm_rate DECIMAL(5,4) NOT NULL DEFAULT 0.0,
  tkt_curr_cd CHAR(3) NOT NULL DEFAULT "",
  tkt_schrg_amt decimal(14,4) NOT NULL DEFAULT 0.0,
  match_err_adj decimal(4,3) NOT NULL DEFAULT 0,		-- adjustment if surcharge is stated in a different currency to the tkt_curr_cd

  fc_cnt TINYINT NOT NULL DEFAULT 0,
  fc_amt_sum decimal(14,4) NOT NULL DEFAULT 0.0,
  fc_amt_cnt TINYINT NOT NULL DEFAULT 0,

  match_ind CHAR(1) NOT NULL DEFAULT "N",
  chosen_ind CHAR(1) NOT NULL DEFAULT "N",

  UNIQUE INDEX idx (doc_nbr_prime ASC, carr_cd ASC, trnsc_date ASC))
ENGINE = MyISAM;

insert into zz_ws.temp_tbl_fc_agg (doc_nbr_prime, carr_cd, trnsc_date, fc_cnt)
select doc_nbr_prime, carr_cd, trnsc_date, max(fc_seq_nbr) as fc_cnt
from zz_ws.temp_tbl_fc_seq
group by doc_nbr_prime, carr_cd, trnsc_date;

optimize table zz_ws.temp_tbl_fc_agg;

update zz_ws.temp_tbl_fc_agg a
join ws_dw.sales_trnsc x on (x.trnsc_nbr = a.doc_nbr_prime and x.carr_cd = a.carr_cd and x.trnsc_date = a.trnsc_date)
set a.tkt_fare_amt = x.fare_amt,
a.eff_comm_rate = x.eff_comm_rate,
a.tkt_curr_cd = x.doc_curr_cd;


#####################################  fare component amount aggregation
drop table if exists zz_ws.temp_tbl_fc_agg_amt;

create table zz_ws.temp_tbl_fc_agg_amt engine = MyISAM
select doc_nbr_prime, carr_cd, trnsc_date, max(fc_cpn_nbr) as fc_cnt, sum(fc_amt) as fc_amt_sum, sum(if(fc_amt > 0, 1, 0)) as fc_amt_cnt		-- HOW DOES THAT WORK?
from ws_dw.sales_tkt_fc
where doc_nbr_prime not in (select doc_nbr_prime from ws_dw.sales_tkt_fc_err)
group by doc_nbr_prime, carr_cd, trnsc_date;

update zz_ws.temp_tbl_fc_agg a
join zz_ws.temp_tbl_fc_agg_amt m on (m.doc_nbr_prime = a.doc_nbr_prime and m.carr_cd = a.carr_cd and m.trnsc_date = a.trnsc_date)				-- HOW DOES THAT WORK?
set a.fc_amt_sum = m.fc_amt_sum,
a.fc_amt_cnt = m.fc_amt_cnt;

#####################################  calculate the surcharge

/*
the logic of surcharge currency: 
the currency of surcharge is decided at the combination stage
if the combination folows the simply rule, the surcharge currency is the original ciy currency as the fc currency
if the combination follow the cocmlex rule, the surcharge currency is nuc
*/
drop table if exists zz_ws.sales_tkt_fc_schrg;

create table zz_ws.sales_tkt_fc_schrg engine = MyISAM
select distinct s.*
from ws_dw.sales_tkt_fc_schrg s
join zz_ws.temp_tbl_fc_fare_matching m on s.doc_nbr_prime = m.doc_nbr_prime and s.carr_cd = m.doc_carr_nbr and s.trnsc_date = m.trnsc_date;

drop table if exists zz_ws.temp_tbl_fc_agg_schrg;

create table zz_ws.temp_tbl_fc_agg_schrg engine = MyISAM
select s.doc_nbr_prime, s.carr_cd, s.trnsc_date, sum(s.schrg_amt) as fcs_schrg_amt, sum(s.schrg_amt) as orig_schrg_amt,
convert(0, decimal(13, 3)) as fc_schrg_amt, convert("", char(3)) as fc_schrg_curr,
convert(0, decimal(13, 3)) as tkt_schrg_amt, convert("", char(3)) as tkt_schrg_curr,
convert(0, decimal(13, 3)) as tkt_schrg_amt_alt, convert("", char(3)) as orig_schrg_curr, convert("", char(3)) as orig_schrg_curr_alt
from zz_ws.sales_tkt_fc_schrg s 
group by s.doc_nbr_prime, s.carr_cd, s.trnsc_date;

alter table zz_ws.temp_tbl_fc_agg_schrg
add index idx_tbl_agg_schrg(doc_nbr_prime, carr_cd, trnsc_date);

optimize table zz_ws.temp_tbl_fc_agg_schrg;

update zz_ws.temp_tbl_fc_agg_schrg sc
join ws_dw.sales_tkt_fc fc on (fc.doc_nbr_prime = sc.doc_nbr_prime and fc.fc_cpn_nbr = 1)
join genie.iata_iroe re on ( re.eff_year = year(fc.trnsc_date) and re.eff_month = month(fc.trnsc_date) and re.curr_cd = fc.fc_curr_cd)
straight_join ws_dw.sales_tkt tkt on sc.doc_nbr_prime = tkt.doc_nbr_prime and sc.carr_cd = tkt.carr_cd and sc.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join genie.iata_rnd r on t.rpt_cntry_cd = r.cntry_cd and fc.tkt_curr_cd = r.curr_cd
set sc.fc_schrg_amt = sc.fcs_schrg_amt * re.roe,
sc.fc_schrg_curr = fc_curr_cd
;

-- from fc schrg currency to tkt currency
update zz_ws.temp_tbl_fc_agg a
straight_join ws_dw.sales_tkt tkt on a.doc_nbr_prime = tkt.doc_nbr_prime and a.carr_cd = tkt.carr_cd and a.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join genie.iata_rnd r on t.rpt_cntry_cd = r.cntry_cd and a.tkt_curr_cd = r.curr_cd

join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = a.doc_nbr_prime and s.carr_cd = a.carr_cd and s.trnsc_date = a.trnsc_date)
straight_join genie.iata_icer cer on (cer.curr_frm = s.fc_schrg_curr and cer.curr_to = a.tkt_curr_cd and cer.eff_date = a.trnsc_date)
set s.tkt_schrg_amt = s.fc_schrg_amt * cer.bsr,
s.tkt_schrg_curr = a.tkt_curr_cd,
s.tkt_schrg_amt_alt = s.orig_schrg_amt * cer.bsr,
s.orig_schrg_curr = 'NUC',
s.orig_schrg_curr_alt = s.fc_schrg_curr
;

-- from fc schrg currency to tkt currency
update zz_ws.temp_tbl_fc_agg a
straight_join ws_dw.sales_tkt tkt on a.doc_nbr_prime = tkt.doc_nbr_prime and a.carr_cd = tkt.carr_cd and a.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join genie.iata_rnd r on t.rpt_cntry_cd = r.cntry_cd and a.tkt_curr_cd = r.curr_cd

join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = a.doc_nbr_prime and s.carr_cd = a.carr_cd and s.trnsc_date = a.trnsc_date)
#left join genie.iata_icer cer on (cer.curr_frm = s.fc_schrg_curr and cer.curr_to = a.tkt_curr_cd and cer.eff_date = a.trnsc_date)
set s.tkt_schrg_amt = s.fc_schrg_amt,
s.tkt_schrg_curr = a.tkt_curr_cd,
s.tkt_schrg_amt_alt = s.orig_schrg_amt,
s.orig_schrg_curr = 'NUC',
s.orig_schrg_curr_alt = s.fc_schrg_curr
where s.fc_schrg_curr = a.tkt_curr_cd
;


########################################## Plus
/*
logic of the currency of plus is the same as the surcharge
*/
drop table if exists zz_ws.sales_tkt_fc_plus;

create table zz_ws.sales_tkt_fc_plus engine = MyISAM
select distinct s.*
from ws_dw.sales_tkt_fc_plus s
join zz_ws.temp_tbl_fc_fare_matching m on s.doc_nbr_prime = m.doc_nbr_prime and s.carr_cd = m.doc_carr_nbr and s.trnsc_date = m.trnsc_date;

drop table if exists zz_ws.temp_tbl_fc_agg_plus;

create table zz_ws.temp_tbl_fc_agg_plus engine = MyISAM
select s.doc_nbr_prime, s.carr_cd, s.trnsc_date, sum(s.plus_amt) as fcs_plus_amt, sum(s.plus_amt) as orig_plus_amt,
convert(0, decimal(14, 4)) as fc_plus_amt, convert("", char(3)) as fc_plus_curr,
convert(0, decimal(14, 4)) as tkt_plus_amt, convert("", char(3)) as tkt_plus_curr,
convert(0, decimal(14, 4)) as tkt_plus_amt_alt, convert("", char(3)) as orig_plus_curr, convert("", char(3)) as orig_plus_curr_alt
from zz_ws.sales_tkt_fc_plus s 
group by s.doc_nbr_prime, s.carr_cd, s.trnsc_date;

alter table zz_ws.temp_tbl_fc_agg_plus
add index idx_tbl_agg_schrg(doc_nbr_prime, carr_cd, trnsc_date);

update zz_ws.temp_tbl_fc_agg_plus sc
join ws_dw.sales_tkt_fc fc on (fc.doc_nbr_prime = sc.doc_nbr_prime and fc.fc_cpn_nbr = 1)
join genie.iata_iroe re on ( re.eff_year = year(fc.trnsc_date) and re.eff_month = month(fc.trnsc_date) and re.curr_cd = fc.fc_curr_cd)
straight_join ws_dw.sales_tkt tkt on sc.doc_nbr_prime = tkt.doc_nbr_prime and sc.carr_cd = tkt.carr_cd and sc.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join genie.iata_rnd r on t.rpt_cntry_cd = r.cntry_cd and fc.tkt_curr_cd = r.curr_cd
set sc.fc_plus_amt = sc.fcs_plus_amt * re.roe,
sc.fc_plus_curr = fc_curr_cd
;

/*
-- from fc schrg currency to tkt currency
update zz_ws.temp_tbl_fc_agg a
straight_join ws_dw.sales_tkt tkt on a.doc_nbr_prime = tkt.doc_nbr_prime and a.carr_cd = tkt.carr_cd and a.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join genie.iata_rnd r on t.rpt_cntry_cd = r.cntry_cd and a.tkt_curr_cd = r.curr_cd

join zz_ws.temp_tbl_fc_agg_plus s on (s.doc_nbr_prime = a.doc_nbr_prime and s.carr_cd = a.carr_cd and s.trnsc_date = a.trnsc_date)
straight_join genie.iata_icer cer on (cer.curr_frm = s.fc_plus_curr and cer.curr_to = a.tkt_curr_cd and cer.eff_date = a.trnsc_date)
set s.tkt_plus_amt =    round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( s.fc_plus_amt * cer.bsr / 0.1 ) * 0.1 , floor( s.fc_plus_amt * cer.bsr / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( s.fc_plus_amt * cer.bsr / 0.1 ) * 0.1 , floor( s.fc_plus_amt * cer.bsr / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( s.fc_plus_amt * cer.bsr / 0.1 ) * 0.1 , floor( s.fc_plus_amt * cer.bsr / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci),
s.tkt_plus_curr = a.tkt_curr_cd,
s.tkt_plus_amt_alt =    round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( s.orig_plus_amt * cer.bsr / 0.1 ) * 0.1 , floor( s.orig_plus_amt * cer.bsr / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( s.orig_plus_amt * cer.bsr / 0.1 ) * 0.1 , floor( s.orig_plus_amt * cer.bsr / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( s.orig_plus_amt * cer.bsr / 0.1 ) * 0.1 , floor( s.orig_plus_amt * cer.bsr / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci),
s.orig_plus_curr = 'NUC',
s.orig_plus_curr_alt = s.fc_plus_curr
;

-- from fc schrg currency to tkt currency
update zz_ws.temp_tbl_fc_agg a
straight_join ws_dw.sales_tkt tkt on a.doc_nbr_prime = tkt.doc_nbr_prime and a.carr_cd = tkt.carr_cd and a.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join genie.iata_rnd r on t.rpt_cntry_cd = r.cntry_cd and a.tkt_curr_cd = r.curr_cd

join zz_ws.temp_tbl_fc_agg_plus s on (s.doc_nbr_prime = a.doc_nbr_prime and s.carr_cd = a.carr_cd and s.trnsc_date = a.trnsc_date)
#straight_join genie.iata_icer cer on (cer.curr_frm = s.fc_plus_curr and cer.curr_to = a.tkt_curr_cd and cer.eff_date = a.trnsc_date)
set s.tkt_plus_amt =    round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( s.fc_plus_amt  / 0.1 ) * 0.1 , floor( s.fc_plus_amt  / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( s.fc_plus_amt  / 0.1 ) * 0.1 , floor( s.fc_plus_amt  / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( s.fc_plus_amt  / 0.1 ) * 0.1 , floor( s.fc_plus_amt  / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci),
s.tkt_plus_curr = a.tkt_curr_cd,
s.tkt_plus_amt_alt =    round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( s.orig_plus_amt  / 0.1 ) * 0.1 , floor( s.orig_plus_amt  / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( s.orig_plus_amt  / 0.1 ) * 0.1 , floor( s.orig_plus_amt  / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( s.orig_plus_amt  / 0.1 ) * 0.1 , floor( s.orig_plus_amt  / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci),
s.orig_plus_curr = 'NUC',
s.orig_plus_curr_alt = s.fc_plus_curr
where s.fc_plus_curr = a.tkt_curr_cd
;
*/

-- from fc schrg currency to tkt currency
update zz_ws.temp_tbl_fc_agg a
straight_join ws_dw.sales_tkt tkt on a.doc_nbr_prime = tkt.doc_nbr_prime and a.carr_cd = tkt.carr_cd and a.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date

join zz_ws.temp_tbl_fc_agg_plus s on (s.doc_nbr_prime = a.doc_nbr_prime and s.carr_cd = a.carr_cd and s.trnsc_date = a.trnsc_date)
straight_join genie.iata_icer cer on (cer.curr_frm = s.fc_plus_curr and cer.curr_to = a.tkt_curr_cd and cer.eff_date = a.trnsc_date)
set s.tkt_plus_amt = s.fc_plus_amt * cer.bsr,
	s.tkt_plus_curr = a.tkt_curr_cd,
	s.tkt_plus_amt_alt = s.orig_plus_amt * cer.bsr,
	s.orig_plus_curr = 'NUC',
	s.orig_plus_curr_alt = s.fc_plus_curr
;

-- from fc schrg currency to tkt currency
update zz_ws.temp_tbl_fc_agg a
straight_join ws_dw.sales_tkt tkt on a.doc_nbr_prime = tkt.doc_nbr_prime and a.carr_cd = tkt.carr_cd and a.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date

join zz_ws.temp_tbl_fc_agg_plus s on (s.doc_nbr_prime = a.doc_nbr_prime and s.carr_cd = a.carr_cd and s.trnsc_date = a.trnsc_date)
#straight_join genie.iata_icer cer on (cer.curr_frm = s.fc_plus_curr and cer.curr_to = a.tkt_curr_cd and cer.eff_date = a.trnsc_date)
set s.tkt_plus_amt = s.fc_plus_amt,
	s.tkt_plus_curr = a.tkt_curr_cd,
	s.tkt_plus_amt_alt = s.orig_plus_amt,
	s.orig_plus_curr = 'NUC',
	s.orig_plus_curr_alt = s.fc_plus_curr
where s.fc_plus_curr = a.tkt_curr_cd;
###################################### determing the amount paid

update zz_ws.temp_tbl_fc_fare_map_chk ck
straight_join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = ck.fc_fare_map_id)
straight_join zz_ws.temp_tbl_fc_agg ag on (ag.doc_nbr_prime = mp.doc_nbr_prime and ag.carr_cd = mp.doc_carr_nbr and ag.trnsc_date = mp.trnsc_date)
set ck.fc_paid_amt = round(ck.fc_fcs_amt / ag.fc_amt_sum * ((ag.tkt_fare_amt - ag.tkt_schrg_amt) * if(ck.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0)), 2)
where ag.fc_cnt = ag.fc_amt_cnt;		-- all fc_amt is calculated, no missing, exclude MIT/BIT cases

-- ALTER TABLE zz_ws.temp_tbl_fc_cnt
-- ADD INDEX idx (doc_nbr_prime ASC);


###################################### combination of 1 pricing unit
-- generate all fare combination with 1 fare component

drop table if exists zz_ws.temp_tbl_fc_comb_1fc;

CREATE TABLE zz_ws.temp_tbl_fc_comb_1fc (
  doc_nbr_prime BIGINT NOT NULL,
  carr_cd CHAR(3) NOT NULL,
  trnsc_date DATE NOT NULL,
  comb_seq_nbr INTEGER NOT NULL AUTO_INCREMENT,
  chosen_ind char(1) NOT NULL DEFAULT "N",

  tkt_fare_amt decimal(14,4) DEFAULT NULL,
  eff_comm_rate decimal(5,4) DEFAULT NULL,
  tkt_schrg_amt decimal(14,4) NOT NULL DEFAULT 0.0,
  tkt_curr_cd char(3) DEFAULT NULL,
  tkt_pu_map char(1) DEFAULT NULL,		-- map for pricing units
  tkt_owrt_map char(1) DEFAULT NULL,	-- 1 for 1 way, 2 for 1/2 return
  tkt_di_map char(1) DEFAULT NULL,		-- F: match to fare di, R: reverse to fare di, B: non-dir/between

  match_pfct_ind char(1) DEFAULT "",
  match_err_pct decimal(4,3) DEFAULT NULL,
  net_fare_amt decimal(14,4) DEFAULT NULL, 
  match_amt_pct decimal(4,3) DEFAULT NULL,
  calc_amt decimal(14,4) DEFAULT NULL,
  calc_rnd decimal(14,4) DEFAULT NULL,
  
  cat14_ok_ind char(1) not null DEFAULT "",
  cat15_ok_ind char(1) not null DEFAULT "",

  fc_cpn_nbr1 TINYINT DEFAULT NULL,
  fc_fare_map_id1 int(11) DEFAULT NULL,
  fare_dis_type1 char(1) not null DEFAULT "",
  fare_rt_ind1 char(1) not null DEFAULT "",
  fc_cpns1 varchar(45) not null DEFAULT "",
  fare_amt1 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt1 decimal(14,4) DEFAULT NULL,
  fc_paid_amt1 decimal(14,4) DEFAULT NULL,

  orig_schrg_amt decimal(14,4) DEFAULT NULL,
  orig_schrg_curr char(3) DEFAULT NULL,
  tkt_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_curr char(3) DEFAULT NULL,
  
 -- pricing unit 2018-06-25 
  pu_cpns1 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind1 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id1 INT NOT NULL DEFAULT 0,

  UNIQUE INDEX idx (doc_nbr_prime ASC, carr_cd ASC, trnsc_date ASC, comb_seq_nbr ASC))
ENGINE = MyISAM;

update zz_ws.temp_tbl_fc_agg
set match_ind = "N",
chosen_ind = "N"
where fc_cnt = 1;


drop table if exists zz_ws.temp_tbl_fc_comb_2fc;

CREATE TABLE zz_ws.temp_tbl_fc_comb_2fc (
  doc_nbr_prime BIGINT NOT NULL,
  carr_cd CHAR(3) NOT NULL,
  trnsc_date DATE NOT NULL,
  comb_seq_nbr INTEGER NOT NULL AUTO_INCREMENT,
  chosen_ind char(1) NOT NULL DEFAULT "N",

  tkt_fare_amt decimal(14,4) DEFAULT NULL,
  eff_comm_rate decimal(5,4) DEFAULT NULL,
  tkt_schrg_amt decimal(14,4) NOT NULL DEFAULT 0.0,
  tkt_curr_cd char(3) DEFAULT NULL,
  tkt_pu_map char(2) DEFAULT NULL,		-- map for pricing units
  tkt_owrt_map char(2) DEFAULT NULL,	-- 1 for 1 way, 2 for 1/2 return
  tkt_di_map char(2) DEFAULT NULL,		-- F: match to fare di, R: reverse to fare di, B: non-dir/between

  match_pfct_ind char(1) DEFAULT "",
  match_err_pct decimal(4,3) DEFAULT NULL,
  net_fare_amt decimal(14,4) DEFAULT NULL, 
  match_amt_pct decimal(4,3) DEFAULT NULL,
  calc_amt decimal(14,4) DEFAULT NULL,
  calc_rnd decimal(14,4) DEFAULT NULL,
  cat14_ok_ind char(1) not null DEFAULT "",
  cat15_ok_ind char(1) not null DEFAULT "",

  fc_cpn_nbr1 TINYINT DEFAULT NULL,
  fc_fare_map_id1 int(11) DEFAULT NULL,
  fare_dis_type1 char(1) not null DEFAULT "",
  fare_rt_ind1 char(1) not null DEFAULT "",
  fc_cpns1 varchar(45) not null DEFAULT "",
  fare_amt1 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt1 decimal(14,4) DEFAULT NULL,
  fc_paid_amt1 decimal(14,4) DEFAULT NULL,

  fc_cpn_nbr2 TINYINT DEFAULT NULL,
  fc_fare_map_id2 int(11) DEFAULT NULL,
  fare_dis_type2 char(1) not null DEFAULT "",
  fare_rt_ind2 char(1) not null DEFAULT "",
  fc_cpns2 varchar(45) not null DEFAULT "",
  fare_amt2 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt2 decimal(14,4) DEFAULT NULL,
  fc_paid_amt2 decimal(14,4) DEFAULT NULL,

  orig_schrg_amt decimal(14,4) DEFAULT NULL,
  orig_schrg_curr char(3) DEFAULT NULL,
  tkt_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_curr char(3) DEFAULT NULL,
  
 -- pricing unit 2018-06-25 
  pu_cpns1 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind1 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id1 INT NOT NULL DEFAULT 0,
  
  pu_cpns2 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind2 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id2 INT NOT NULL DEFAULT 0,

  UNIQUE INDEX idx (doc_nbr_prime ASC, carr_cd ASC, trnsc_date ASC, comb_seq_nbr ASC))
ENGINE = MyISAM;

update zz_ws.temp_tbl_fc_agg
set match_ind = "N",
chosen_ind = "N"
where fc_cnt = 2;

drop table if exists zz_ws.temp_tbl_fc_comb_3fc;

CREATE TABLE zz_ws.temp_tbl_fc_comb_3fc (
  doc_nbr_prime BIGINT NOT NULL,
  carr_cd CHAR(3) NOT NULL,
  trnsc_date DATE NOT NULL,
  comb_seq_nbr INTEGER NOT NULL AUTO_INCREMENT,
  chosen_ind char(1) NOT NULL DEFAULT "N",

  tkt_fare_amt decimal(14,4) DEFAULT NULL,
  eff_comm_rate decimal(5,4) DEFAULT NULL,
  tkt_schrg_amt decimal(14,4) NOT NULL DEFAULT 0.0,
  tkt_curr_cd char(3) DEFAULT NULL,
  tkt_pu_map char(3) DEFAULT NULL,		-- map for pricing units
  tkt_owrt_map char(3) DEFAULT NULL,	-- 1 for 1 way, 2 for 1/2 return
  tkt_di_map char(3) DEFAULT NULL,		-- F: match to fare di, R: reverse to fare di, B: non-dir/between

  match_pfct_ind char(1) DEFAULT "",
  match_err_pct decimal(4,3) DEFAULT NULL,
  net_fare_amt decimal(14,4) DEFAULT NULL, 
  match_amt_pct decimal(4,3) DEFAULT NULL,
  calc_amt decimal(14,4) DEFAULT NULL,
  calc_rnd decimal(14,4) DEFAULT NULL,
  cat14_ok_ind char(1) not null DEFAULT "",
  cat15_ok_ind char(1) not null DEFAULT "",

  fc_cpn_nbr1 TINYINT DEFAULT NULL,
  fc_fare_map_id1 int(11) DEFAULT NULL,
  fare_dis_type1 char(1) not null DEFAULT "",
  fare_rt_ind1 char(1) not null DEFAULT "",
  fc_cpns1 varchar(45) not null DEFAULT "",
  fare_amt1 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt1 decimal(14,4) DEFAULT NULL,
  fc_paid_amt1 decimal(14,4) DEFAULT NULL,

  fc_cpn_nbr2 TINYINT DEFAULT NULL,
  fc_fare_map_id2 int(11) DEFAULT NULL,
  fare_dis_type2 char(1) not null DEFAULT "",
  fare_rt_ind2 char(1) not null DEFAULT "",
  fc_cpns2 varchar(45) not null DEFAULT "",
  fare_amt2 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt2 decimal(14,4) DEFAULT NULL,
  fc_paid_amt2 decimal(14,4) DEFAULT NULL,

  fc_cpn_nbr3 TINYINT DEFAULT NULL,
  fc_fare_map_id3 int(11) DEFAULT NULL,
  fare_dis_type3 char(1) not null DEFAULT "",
  fare_rt_ind3 char(1) not null DEFAULT "",
  fc_cpns3 varchar(45) not null DEFAULT "",
  fare_amt3 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt3 decimal(14,4) DEFAULT NULL,
  fc_paid_amt3 decimal(14,4) DEFAULT NULL,

  orig_schrg_amt decimal(14,4) DEFAULT NULL,
  orig_schrg_curr char(3) DEFAULT NULL,
  tkt_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_curr char(3) DEFAULT NULL,
  
 -- pricing unit 2018-06-25 
  pu_cpns1 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind1 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id1 INT NOT NULL DEFAULT 0,
  
  pu_cpns2 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind2 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id2 INT NOT NULL DEFAULT 0,
  
  pu_cpns3 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind3 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id3 INT NOT NULL DEFAULT 0,
  
-- to_orig_dist1 int(11) NOT NULL DEFAULT 0,
-- to_orig_dist2 int(11) NOT NULL DEFAULT 0,
  UNIQUE INDEX idx (doc_nbr_prime ASC, carr_cd ASC, trnsc_date ASC, comb_seq_nbr ASC))
ENGINE = MyISAM;

update zz_ws.temp_tbl_fc_agg
set match_ind = "N",
chosen_ind = "N"
where fc_cnt = 3;

drop table if exists zz_ws.temp_tbl_fc_comb_4fc;

CREATE TABLE zz_ws.temp_tbl_fc_comb_4fc (
  doc_nbr_prime BIGINT NOT NULL,
  carr_cd CHAR(3) NOT NULL,
  trnsc_date DATE NOT NULL,
  comb_seq_nbr INTEGER NOT NULL AUTO_INCREMENT,
  chosen_ind char(1) NOT NULL DEFAULT "N",
  fc2_fc3_1pu_ind char(1) NOT NULL DEFAULT "N",		# indication if fare component 2 and 3 can be 1 fare component

  tkt_fare_amt decimal(14,4) DEFAULT NULL,
  eff_comm_rate decimal(5,4) DEFAULT NULL,
  tkt_schrg_amt decimal(14,4) NOT NULL DEFAULT 0.0,
  tkt_curr_cd char(3) DEFAULT NULL,
  tkt_pu_map char(4) DEFAULT NULL,		-- map for pricing units
  tkt_owrt_map char(4) DEFAULT NULL,	-- 1 for 1 way, 2 for 1/2 return
  tkt_di_map char(4) DEFAULT NULL,		-- F: match to fare di, R: reverse to fare di, B: non-dir/between

  match_pfct_ind char(1) DEFAULT "",
  match_err_pct decimal(4,3) DEFAULT NULL,
  net_fare_amt decimal(14,4) DEFAULT NULL, 
  match_amt_pct decimal(4,3) DEFAULT NULL,
  calc_amt decimal(14,4) DEFAULT NULL,
  calc_rnd decimal(14,4) DEFAULT NULL,
  cat14_ok_ind char(1) not null DEFAULT "",
  cat15_ok_ind char(1) not null DEFAULT "",

  fc_cpn_nbr1 TINYINT DEFAULT NULL,
  fc_fare_map_id1 int(11) DEFAULT NULL,
  fare_dis_type1 char(1) not null DEFAULT "",
  fare_rt_ind1 char(1) not null DEFAULT "",
  fc_cpns1 varchar(45) not null DEFAULT "",
  fare_amt1 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt1 decimal(14,4) DEFAULT NULL,
  fc_paid_amt1 decimal(14,4) DEFAULT NULL,

  fc_cpn_nbr2 TINYINT DEFAULT NULL,
  fc_fare_map_id2 int(11) DEFAULT NULL,
  fare_dis_type2 char(1) not null DEFAULT "",
  fare_rt_ind2 char(1) not null DEFAULT "",
  fc_cpns2 varchar(45) not null DEFAULT "",
  fare_amt2 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt2 decimal(14,4) DEFAULT NULL,
  fc_paid_amt2 decimal(14,4) DEFAULT NULL,

  fc_cpn_nbr3 TINYINT DEFAULT NULL,
  fc_fare_map_id3 int(11) DEFAULT NULL,
  fare_dis_type3 char(1) not null DEFAULT "",
  fare_rt_ind3 char(1) not null DEFAULT "",
  fc_cpns3 varchar(45) not null DEFAULT "",
  fare_amt3 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt3 decimal(14,4) DEFAULT NULL,
  fc_paid_amt3 decimal(14,4) DEFAULT NULL,

  fc_cpn_nbr4 TINYINT DEFAULT NULL,
  fc_fare_map_id4 int(11) DEFAULT NULL,
  fare_dis_type4 char(1) not null DEFAULT "",
  fare_rt_ind4 char(1) not null DEFAULT "",
  fc_cpns4 varchar(45) not null DEFAULT "",
  fare_amt4 decimal(14,4) DEFAULT NULL,
  fc_fcs_amt4 decimal(14,4) DEFAULT NULL,
  fc_paid_amt4 decimal(14,4) DEFAULT NULL,

  orig_schrg_amt decimal(14,4) DEFAULT NULL,
  orig_schrg_curr char(3) DEFAULT NULL,
  tkt_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_amt decimal(14,4) DEFAULT NULL,
  orig_plus_curr char(3) DEFAULT NULL,
  
 -- pricing unit 2018-06-25 
  pu_cpns1 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind1 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id1 INT NOT NULL DEFAULT 0,
  
  pu_cpns2 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind2 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id2 INT NOT NULL DEFAULT 0,
  
  pu_cpns3 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind3 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id3 INT NOT NULL DEFAULT 0,
  
  pu_cpns4 VARCHAR(45) NOT NULL DEFAULT '' ,
  pu_io_ind4 CHAR(1) NOT NULL DEFAULT '' ,
  exp_fare_map_id4 INT NOT NULL DEFAULT 0,
   
-- open_jaw_ind char(1) DEFAULT NULL,
-- to_orig_dist1 int(11) NOT NULL DEFAULT 0,
-- to_orig_dist2 int(11) NOT NULL DEFAULT 0,
-- to_orig_dist3 int(11) NOT NULL DEFAULT 0,

  UNIQUE INDEX idx (doc_nbr_prime ASC, carr_cd ASC, trnsc_date ASC, comb_seq_nbr ASC))
ENGINE = MyISAM;

update zz_ws.temp_tbl_fc_agg
set match_ind = "N",
chosen_ind = "N"
where fc_cnt = 4;

set @amt_bnd := 0.005;

while @amt_bnd <= 0.21 Do

optimize table zz_ws.temp_tbl_fc_agg ;
optimize table ws_dw.sales_trnsc ;

###################################### 100% percent match

insert into zz_ws.temp_tbl_fc_comb_1fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate, tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd,
cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1
, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr_alt, ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ), p.orig_plus_amt, p.orig_plus_curr_alt,  
'1' as tkt_pu_map,
ck1.fare_rt_ind as tkt_owrt_map,
ck1.fare_dir_ind as tkt_di_map,
if( @amt_bnd < 0.01, "Y", "N"), ck1.match_err_pct, 
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
ck1.cat14_ok_ind, ck1.cat15_ok_ind,
ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt_alt, ck1.fc_fcs_amt, ck1.fc_paid_amt
from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )

where ag.fc_cnt = 1
and concat(ck1.fare_rt_ind, ck1.fare_dir_ind) in ('1F', '1B')		# must be just an ow fare, match to the fare direction or fare has no direction
and ck1.same_curr_ind = '1'
and
(@v2 := if(ck1.final_fare_amt_alt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ) - ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) )) * if(ck1.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
(@v1 := 
if(ck1.int_dom_ind = 'D', round(ck1.final_fare_amt_alt, r.deci),
round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( ck1.final_fare_amt_alt / 0.1 ) * 0.1 , floor( ck1.final_fare_amt_alt / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( ck1.final_fare_amt_alt / 0.1 ) * 0.1 , floor( ck1.final_fare_amt_alt / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( ck1.final_fare_amt_alt / 0.1 ) * 0.1 , floor( ck1.final_fare_amt_alt / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ),3)) ) between (1 - @amt_bnd) and (1 + @amt_bnd )
and ag.chosen_ind <> "Y"
;	-- must be just an ow fare


insert into zz_ws.temp_tbl_fc_comb_1fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate,tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd,
cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1
, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr, ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ), p.orig_plus_amt, p.orig_plus_curr,  
'1' as tkt_pu_map,
ck1.fare_rt_ind as tkt_owrt_map,
ck1.fare_dir_ind as tkt_di_map,
if( @amt_bnd < 0.01, "Y", "N"), ck1.match_err_pct, 
@v_n, round(@v2, 3),
   @v1,
   r.fare_rnd,
ck1.cat14_ok_ind, ck1.cat15_ok_ind,
ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt, ck1.fc_fcs_amt, ck1.fc_paid_amt
from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )

where ag.fc_cnt = 1
and concat(ck1.fare_rt_ind, ck1.fare_dir_ind) in ('1F', '1B')		# must be just an ow fare, match to the fare direction or fare has no direction
and ck1.same_curr_ind = '0'
and
(@v2 := if(ck1.final_fare_amt_alt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ) - ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ) ) * if(ck1.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
(@v1 := 
if(ck1.int_dom_ind = 'D', round(ck1.final_fare_amt, r.deci),
round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( ck1.final_fare_amt / 0.1 ) * 0.1 , floor( ck1.final_fare_amt / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( ck1.final_fare_amt / 0.1 ) * 0.1 , floor( ck1.final_fare_amt / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( ck1.final_fare_amt / 0.1 ) * 0.1 , floor( ck1.final_fare_amt / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ),
3)) ) between (1 - @amt_bnd) and (1 + @amt_bnd )
and ag.chosen_ind <> "Y"
   ;	-- must be just an ow fare

optimize table zz_ws.temp_tbl_fc_comb_1fc;

# set the indictor for the mapped ones, then don"t look for less accurate ones
update zz_ws.temp_tbl_fc_agg ag
join zz_ws.temp_tbl_fc_comb_1fc mp on (mp.doc_nbr_prime = ag.doc_nbr_prime and mp.carr_cd = ag.carr_cd and mp.trnsc_date = ag.trnsc_date)
set ag.match_ind = "Y", ag.chosen_ind = "Y";


# ############################################################################################################## 2 combinations  ##################################################################################
-- generate all fare combination with 2 fare components

# ------------------------------------------------------------------------------------------------
# choose the most accurate ones first
insert into zz_ws.temp_tbl_fc_comb_2fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate,tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd, cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1,
fc_cpn_nbr2, fc_fare_map_id2, fare_dis_type2, fare_rt_ind2, fc_cpns2, fare_amt2, fc_fcs_amt2, fc_paid_amt2
)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr, ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ), p.orig_plus_amt, p.orig_plus_curr,  
if(concat(ck1.fare_rt_ind, ck2.fare_rt_ind) = '11' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R', '12', '11') as tkt_pu_map, 	# '12' means PU1 + PU2
concat(ck1.fare_rt_ind, ck2.fare_rt_ind) as tkt_owrt_map,
concat(ck1.fare_dir_ind, ck2.fare_dir_ind) as tkt_di_map,

if( @amt_bnd < 0.01, "Y", "N"),
round((ck1.match_err_pct+ck2.match_err_pct)/2, 3),
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
if(ck1.cat14_ok_ind = "Y" and ck2.cat14_ok_ind = "Y", "Y", "N"), 
if(ck1.cat15_ok_ind = "Y" and ck2.cat15_ok_ind = "Y", "Y", "N"),

ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt, ck1.fc_fcs_amt, ck1.fc_paid_amt,
ck2.fc_cpn_nbr, ck2.fc_fare_map_id, ck2.fare_dis_type, ck2.fare_rt_ind, q2.fc_cpns, ck2.final_fare_amt, ck2.fc_fcs_amt, ck2.fc_paid_amt

from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
	and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
	and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp1 on (mp1.fc_fare_map_id = ck1.fc_fare_map_id)

straight_join zz_ws.temp_tbl_fc_seq q2 on (q2.doc_nbr_prime = ag.doc_nbr_prime and q2.trnsc_date = ag.trnsc_date and q2.fc_seq_nbr = 2)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck2 on (ck2.doc_nbr_prime = q2.doc_nbr_prime and ck2.fc_cpn_nbr = q2.fc_cpn_nbr
	and (ck2.tourcd_ok_ind = "Y" or ck2.tourcd_na_ind = "Y" or ck2.f_tourcd_none = "Y") 
	and (ck2.bcode_ok_ind = "Y" or ck2.bcode_na_ind = "Y" or ck2.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp2 on (mp2.fc_fare_map_id = ck2.fc_fare_map_id)

where ag.fc_cnt = 2
and (
		# 2 PUs, must be all one-way fares, and no reverse of the fare
		if (concat(ck1.fare_rt_ind, ck2.fare_rt_ind) = '11' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R',
			true,
			
		# 1 PU, the 2nd seg must be either a return, or, 2nd seg is bidirection then 1st seg must be a half return, or 
		# and must be a return/open jaw
		if (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)),										
			left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD'),
			false)
		)
	)
and 
not		-- fcs in one ticket are not in the same currency
(
(ck1.spec_fare_curr like ck2.spec_fare_curr)
and 
(ck1.same_curr_ind = '1' and ck2.same_curr_ind = '1')
) -- completely revise
and
(@v2 := if(ck1.final_fare_amt + ck2.final_fare_amt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ) - ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) )) 
* if(ck1.fare_dis_type = "C"or ck2.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
     (@v1 := 
     if(ck1.int_dom_ind = 'D' and ck2.int_dom_ind = 'D', round(ck1.final_fare_amt + ck2.final_fare_amt, r.deci),
     round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ),
3)) ) between (1 - @amt_bnd) and (1 + @amt_bnd ) 
and ag.chosen_ind <> "Y"
;

insert into zz_ws.temp_tbl_fc_comb_2fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate,tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd, cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1,
fc_cpn_nbr2, fc_fare_map_id2, fare_dis_type2, fare_rt_ind2, fc_cpns2, fare_amt2, fc_fcs_amt2, fc_paid_amt2
)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr_alt, ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ), p.orig_plus_amt, p.orig_plus_curr_alt,  
if(concat(ck1.fare_rt_ind, ck2.fare_rt_ind) = '11' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R', '12', '11') as tkt_pu_map, 	# '12' means PU1 + PU2
concat(ck1.fare_rt_ind, ck2.fare_rt_ind) as tkt_owrt_map,
concat(ck1.fare_dir_ind, ck2.fare_dir_ind) as tkt_di_map,

if( @amt_bnd < 0.01, "Y", "N"),
round((ck1.match_err_pct+ck2.match_err_pct)/2, 3),
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
if(ck1.cat14_ok_ind = "Y" and ck2.cat14_ok_ind = "Y", "Y", "N"), 
if(ck1.cat15_ok_ind = "Y" and ck2.cat15_ok_ind = "Y", "Y", "N"),

ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt_alt, ck1.fc_fcs_amt, ck1.fc_paid_amt,
ck2.fc_cpn_nbr, ck2.fc_fare_map_id, ck2.fare_dis_type, ck2.fare_rt_ind, q2.fc_cpns, ck2.final_fare_amt_alt, ck2.fc_fcs_amt, ck2.fc_paid_amt

from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
	and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
	and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp1 on (mp1.fc_fare_map_id = ck1.fc_fare_map_id)

straight_join zz_ws.temp_tbl_fc_seq q2 on (q2.doc_nbr_prime = ag.doc_nbr_prime and q2.trnsc_date = ag.trnsc_date and q2.fc_seq_nbr = 2)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck2 on (ck2.doc_nbr_prime = q2.doc_nbr_prime and ck2.fc_cpn_nbr = q2.fc_cpn_nbr
	and (ck2.tourcd_ok_ind = "Y" or ck2.tourcd_na_ind = "Y" or ck2.f_tourcd_none = "Y") 
	and (ck2.bcode_ok_ind = "Y" or ck2.bcode_na_ind = "Y" or ck2.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp2 on (mp2.fc_fare_map_id = ck2.fc_fare_map_id)

where ag.fc_cnt = 2
and (
		# 2 PUs, must be all one-way fares, and no reverse of the fare
		if (concat(ck1.fare_rt_ind, ck2.fare_rt_ind) = '11' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R',
			true,
			
		# 1 PU, the 2nd seg must be either a return, or, 2nd seg is bidirection then 1st seg must be a half return, or 
		# and must be a return/open jaw
		if (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)),										
			left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD'),
			false)
		)
	)
and ck1.spec_fare_curr like ck2.spec_fare_curr		-- fcs in one ticket are in the same currency
and (ck1.same_curr_ind = '1' and ck2.same_curr_ind = '1')
and
(@v2 :=  if(ck1.final_fare_amt_alt + ck2.final_fare_amt_alt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ) - ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ) ) 
* if(ck1.fare_dis_type = "C"or ck2.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
     (@v1 := 
		if(ck1.int_dom_ind = 'D' and ck2.int_dom_ind = 'D', round(ck1.final_fare_amt_alt + ck2.final_fare_amt_alt, r.deci),
          round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ),
3))) between (1 - @amt_bnd) and (1 + @amt_bnd ) 
 and ag.chosen_ind <> "Y"
;
   
optimize table zz_ws.temp_tbl_fc_comb_2fc;

# set the indictor for the mapped ones, then don"t look for less accurate ones
update zz_ws.temp_tbl_fc_agg ag
join zz_ws.temp_tbl_fc_comb_2fc mp on (mp.doc_nbr_prime = ag.doc_nbr_prime and mp.carr_cd = ag.carr_cd and mp.trnsc_date = ag.trnsc_date)
set ag.match_ind = "Y", ag.chosen_ind = "Y";



# ############################################################################################################## 3 combinations  ##################################################################################
-- generate all fare combination with 3 fare components
# ------------------------------------------------------------------------------------------------

# choose the most accurate ones first
insert into zz_ws.temp_tbl_fc_comb_3fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate,tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd, cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1,
fc_cpn_nbr2, fc_fare_map_id2, fare_dis_type2, fare_rt_ind2, fc_cpns2, fare_amt2, fc_fcs_amt2, fc_paid_amt2,
fc_cpn_nbr3, fc_fare_map_id3, fare_dis_type3, fare_rt_ind3, fc_cpns3, fare_amt3, fc_fcs_amt3, fc_paid_amt3
)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr, ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ), p.orig_plus_amt, p.orig_plus_curr,  
        
	# 3 PUs, must be all one-way fares, and no reverse of the fare
	if (concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind) = '111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R',
		'123',

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
        '111',

	# 2 PU, seg 1 + 2, seg 3 is 1 way
    # the 2nd seg must be either a return, or, 2nd seg is bidirection then 1st seg must be a half return
	# and 1 & 2 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2))) 
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        '112',

	# 2 PU, seg 1 + 3, seg 2 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 1st seg must be a half return
	# and 1 & 3 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '121',

	# 2 PU, seg 2 + 3, seg 1 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 2nd seg must be a half return
	# and 2 & 3 must be a return/open jaw
    if ((ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2))) 
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
		'122',
        ''
	))))) as tkt_pu_map,

concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind) as tkt_owrt_map,
concat(ck1.fare_dir_ind, ck2.fare_dir_ind, ck3.fare_dir_ind) as tkt_di_map,

if( @amt_bnd < 0.01, "Y", "N"),
round((ck1.match_err_pct + ck2.match_err_pct + ck3.match_err_pct) / 3, 3),
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
if(ck1.cat14_ok_ind = "Y" and ck2.cat14_ok_ind = "Y" and ck3.cat14_ok_ind = "Y", "Y", "N"),
if(ck1.cat15_ok_ind = "Y" and ck2.cat15_ok_ind = "Y" and ck3.cat15_ok_ind = "Y", "Y", "N"),

ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt, ck1.fc_fcs_amt, ck1.fc_paid_amt,
ck2.fc_cpn_nbr, ck2.fc_fare_map_id, ck2.fare_dis_type, ck2.fare_rt_ind, q2.fc_cpns, ck2.final_fare_amt, ck2.fc_fcs_amt, ck2.fc_paid_amt,
ck3.fc_cpn_nbr, ck3.fc_fare_map_id, ck3.fare_dis_type, ck3.fare_rt_ind, q3.fc_cpns, ck3.final_fare_amt, ck3.fc_fcs_amt, ck3.fc_paid_amt

from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
	and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
	and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp1 on (mp1.fc_fare_map_id = ck1.fc_fare_map_id)

straight_join zz_ws.temp_tbl_fc_seq q2 on (q2.doc_nbr_prime = ag.doc_nbr_prime and q2.trnsc_date = ag.trnsc_date and q2.fc_seq_nbr = 2)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck2 on (ck2.doc_nbr_prime = q2.doc_nbr_prime and ck2.fc_cpn_nbr = q2.fc_cpn_nbr
	and (ck2.tourcd_ok_ind = "Y" or ck2.tourcd_na_ind = "Y" or ck2.f_tourcd_none = "Y") 
	and (ck2.bcode_ok_ind = "Y" or ck2.bcode_na_ind = "Y" or ck2.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp2 on (mp2.fc_fare_map_id = ck2.fc_fare_map_id)

straight_join zz_ws.temp_tbl_fc_seq q3 on (q3.doc_nbr_prime = ag.doc_nbr_prime and q3.trnsc_date = ag.trnsc_date and q3.fc_seq_nbr = 3)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck3 on (ck3.doc_nbr_prime = q3.doc_nbr_prime and ck3.fc_cpn_nbr = q3.fc_cpn_nbr 
	and (ck3.tourcd_ok_ind = "Y" or ck3.tourcd_na_ind = "Y" or ck3.f_tourcd_none = "Y") 
	and (ck3.bcode_ok_ind = "Y" or ck3.bcode_na_ind = "Y" or ck3.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp3 on (mp3.fc_fare_map_id = ck3.fc_fare_map_id)

where ag.fc_cnt = 3
and
	# 3 PUs, must be all one-way fares, and no reverse of the fare
	if (concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind) = '111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R',
		true,

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
        true,

	# 2 PU, seg 1 + 2, seg 3 is 1 way
    # the 2nd seg must be either a return, or, 2nd seg is bidirection then 1st seg must be a half return
	# and 1 & 2 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2))) 
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 1 + 3, seg 2 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 1st seg must be a half return
	# and 1 & 3 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 2 + 3, seg 1 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 2nd seg must be a half return
	# and 2 & 3 must be a return/open jaw
    if ((ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2))) 
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
		true,
        false
	)))))

and 
not (		-- fcs in one ticket are not in the same currency
((ck1.spec_fare_curr like ck2.spec_fare_curr) and (ck1.spec_fare_curr like ck3.spec_fare_curr))
and (ck1.same_curr_ind = '1' and ck2.same_curr_ind = '1' and ck3.same_curr_ind = '1')
) -- not (A and B)
and
(@v2 := if(ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ) - ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ) ) 
* if(ck1.fare_dis_type = "C"or ck2.fare_dis_type = "C" or ck3.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
   ( @v1 := 
	if(ck1.int_dom_ind = 'D' and ck2.int_dom_ind = 'D' and ck3.int_dom_ind = 'D', round(ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt, r.deci),
   round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ), 
3)))  between (1 - @amt_bnd) and (1 + @amt_bnd ) 
and ag.chosen_ind <> "Y"
;


insert into zz_ws.temp_tbl_fc_comb_3fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate, tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd, cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1,
fc_cpn_nbr2, fc_fare_map_id2, fare_dis_type2, fare_rt_ind2, fc_cpns2, fare_amt2, fc_fcs_amt2, fc_paid_amt2,
fc_cpn_nbr3, fc_fare_map_id3, fare_dis_type3, fare_rt_ind3, fc_cpns3, fare_amt3, fc_fcs_amt3, fc_paid_amt3
)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr_alt, ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ), p.orig_plus_amt, p.orig_plus_curr_alt,  
        
	# 3 PUs, must be all one-way fares, and no reverse of the fare
	if (concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind) = '111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R',
		'123',

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
        '111',

	# 2 PU, seg 1 + 2, seg 3 is 1 way
    # the 2nd seg must be either a return, or, 2nd seg is bidirection then 1st seg must be a half return
	# and 1 & 2 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2))) 
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        '112',

	# 2 PU, seg 1 + 3, seg 2 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 1st seg must be a half return
	# and 1 & 3 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '121',

	# 2 PU, seg 2 + 3, seg 1 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 2nd seg must be a half return
	# and 2 & 3 must be a return/open jaw
    if ((ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2))) 
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
		'122',
        ''
	))))) as tkt_pu_map,

concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind) as tkt_owrt_map,
concat(ck1.fare_dir_ind, ck2.fare_dir_ind, ck3.fare_dir_ind) as tkt_di_map,

if( @amt_bnd < 0.01, "Y", "N"),
round((ck1.match_err_pct + ck2.match_err_pct + ck3.match_err_pct) / 3, 3),
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
if(ck1.cat14_ok_ind = "Y" and ck2.cat14_ok_ind = "Y" and ck3.cat14_ok_ind = "Y", "Y", "N"),
if(ck1.cat15_ok_ind = "Y" and ck2.cat15_ok_ind = "Y" and ck3.cat15_ok_ind = "Y", "Y", "N"),

ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt_alt, ck1.fc_fcs_amt, ck1.fc_paid_amt,
ck2.fc_cpn_nbr, ck2.fc_fare_map_id, ck2.fare_dis_type, ck2.fare_rt_ind, q2.fc_cpns, ck2.final_fare_amt_alt, ck2.fc_fcs_amt, ck2.fc_paid_amt,
ck3.fc_cpn_nbr, ck3.fc_fare_map_id, ck3.fare_dis_type, ck3.fare_rt_ind, q3.fc_cpns, ck3.final_fare_amt_alt, ck3.fc_fcs_amt, ck3.fc_paid_amt

from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
	and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
	and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp1 on (mp1.fc_fare_map_id = ck1.fc_fare_map_id)

straight_join zz_ws.temp_tbl_fc_seq q2 on (q2.doc_nbr_prime = ag.doc_nbr_prime and q2.trnsc_date = ag.trnsc_date and q2.fc_seq_nbr = 2)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck2 on (ck2.doc_nbr_prime = q2.doc_nbr_prime and ck2.fc_cpn_nbr = q2.fc_cpn_nbr
	and (ck2.tourcd_ok_ind = "Y" or ck2.tourcd_na_ind = "Y" or ck2.f_tourcd_none = "Y") 
	and (ck2.bcode_ok_ind = "Y" or ck2.bcode_na_ind = "Y" or ck2.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp2 on (mp2.fc_fare_map_id = ck2.fc_fare_map_id)

straight_join zz_ws.temp_tbl_fc_seq q3 on (q3.doc_nbr_prime = ag.doc_nbr_prime and q3.trnsc_date = ag.trnsc_date and q3.fc_seq_nbr = 3)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck3 on (ck3.doc_nbr_prime = q3.doc_nbr_prime and ck3.fc_cpn_nbr = q3.fc_cpn_nbr 
	and (ck3.tourcd_ok_ind = "Y" or ck3.tourcd_na_ind = "Y" or ck3.f_tourcd_none = "Y") 
	and (ck3.bcode_ok_ind = "Y" or ck3.bcode_na_ind = "Y" or ck3.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp3 on (mp3.fc_fare_map_id = ck3.fc_fare_map_id)

where ag.fc_cnt = 3
and
	# 3 PUs, must be all one-way fares, and no reverse of the fare
	if (concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind) = '111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R',
		true,

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
        true,

	# 2 PU, seg 1 + 2, seg 3 is 1 way
    # the 2nd seg must be either a return, or, 2nd seg is bidirection then 1st seg must be a half return
	# and 1 & 2 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2))) 
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 1 + 3, seg 2 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 1st seg must be a half return
	# and 1 & 3 must be a return/open jaw
    if ((ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 2 + 3, seg 1 is 1 way
    # the 3rd seg must be either a return, or, 3rd seg is bidirection then 2nd seg must be a half return
	# and 2 & 3 must be a return/open jaw
    if ((ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2))) 
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
		true,
        false
	)))))

and ((ck1.spec_fare_curr like ck2.spec_fare_curr) and (ck1.spec_fare_curr like ck3.spec_fare_curr))		-- fcs in one ticket are in the same currency
and (ck1.same_curr_ind = '1' and ck2.same_curr_ind = '1' and ck3.same_curr_ind = '1')
and
(@v2 :=  if(ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ) - ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ) ) 
* if(ck1.fare_dis_type = "C"or ck2.fare_dis_type = "C" or ck3.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
   ( @v1 := 
   	if(ck1.int_dom_ind = 'D' and ck2.int_dom_ind = 'D' and ck3.int_dom_ind = 'D', round(ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt, r.deci),
		round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil( if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ),
3)) )  between (1 - @amt_bnd) and (1 + @amt_bnd ) 
and ag.chosen_ind <> "Y"
;

optimize table zz_ws.temp_tbl_fc_comb_3fc;

# set the indictor for the mapped ones, then don"t look for less accurate ones
update zz_ws.temp_tbl_fc_agg ag
join zz_ws.temp_tbl_fc_comb_3fc mp on (mp.doc_nbr_prime = ag.doc_nbr_prime and mp.carr_cd = ag.carr_cd and mp.trnsc_date = ag.trnsc_date)
set ag.match_ind = "Y", ag.chosen_ind = "Y";


# ############################################################################################################## 4 combinations  ##################################################################################
-- generate all fare combination with 4 fare components


-- choose the most accurate ones first
insert into zz_ws.temp_tbl_fc_comb_4fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate,tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd, cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1,
fc_cpn_nbr2, fc_fare_map_id2, fare_dis_type2, fare_rt_ind2, fc_cpns2, fare_amt2, fc_fcs_amt2, fc_paid_amt2,
fc_cpn_nbr3, fc_fare_map_id3, fare_dis_type3, fare_rt_ind3, fc_cpns3, fare_amt3, fc_fcs_amt3, fc_paid_amt3,
fc_cpn_nbr4, fc_fare_map_id4, fare_dis_type4, fare_rt_ind4, fc_cpns4, fare_amt4, fc_fcs_amt4, fc_paid_amt4
-- open_jaw_ind
)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr, ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ), p.orig_plus_amt, p.orig_plus_curr,  

	# 4 PUs, must be all one-way fares, and no reverse of the fare
	if( concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind, ck4.fare_rt_ind) = '1111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R' and ck4.fare_dir_ind <> 'R',
		'1234',

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if( (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
		'1111',

	# 2 PU, seg 1 + 4, seg 2 + 3
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '1221',

	# 2 PU, seg 1 + 2, seg 3 + 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1122',

	# 2 PU, seg 1 + 3, seg 2 + 4, not sure this is a sensible pattern
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
		'1212',

	# 2 PU, seg 1 + 2 + 3, seg 4
    if( ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
		'1112',

	# 2 PU, seg 1 + 2 + 4, seg 3
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        '1121',

	# 2 PU, seg 1 + 3 + 4, seg 2
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        '1211',

	# 2 PU, seg 2 + 3 + 4, seg 1
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp2.fc_orig_city),
		'1222',

	# 3 PU, seg 1 + 2, seg 3, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        '1123',

	# 3 PU, seg 1 + 3, seg 2, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '1213',

	# 3 PU, seg 1 + 4, seg 2, seg 3
    if( (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1231',

	# 3 PU, seg 1, seg 2 + 3, seg 4
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '1223',

	# 3 PU, seg 1, seg 2 + 4, seg 3
    if( (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1232',

	# 3 PU, seg 1, seg 2, seg 3 + 4
    if( (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1233',
        ''
	))))))))))))))) as tkt_pu_map,

concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind, ck4.fare_rt_ind) as tkt_owrt_map,
concat(ck1.fare_dir_ind, ck2.fare_dir_ind, ck3.fare_dir_ind, ck4.fare_dir_ind) as tkt_di_map,

if( @amt_bnd < 0.01, "Y", "N"),
round((ck1.match_err_pct + ck2.match_err_pct + ck3.match_err_pct + ck4.match_err_pct) / 4, 3),
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
if(ck1.cat14_ok_ind = "Y" and ck2.cat14_ok_ind = "Y" and ck3.cat14_ok_ind = "Y" and ck4.cat14_ok_ind = "Y", "Y", "N"),
if(ck1.cat15_ok_ind = "Y" and ck2.cat15_ok_ind = "Y" and ck3.cat15_ok_ind = "Y" and ck4.cat15_ok_ind = "Y", "Y", "N"),

ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt, ck1.fc_fcs_amt, ck1.fc_paid_amt,
ck2.fc_cpn_nbr, ck2.fc_fare_map_id, ck2.fare_dis_type, ck2.fare_rt_ind, q2.fc_cpns, ck2.final_fare_amt, ck2.fc_fcs_amt, ck2.fc_paid_amt,
ck3.fc_cpn_nbr, ck3.fc_fare_map_id, ck3.fare_dis_type, ck3.fare_rt_ind, q3.fc_cpns, ck3.final_fare_amt, ck3.fc_fcs_amt, ck3.fc_paid_amt,
ck4.fc_cpn_nbr, ck4.fc_fare_map_id, ck4.fare_dis_type, ck4.fare_rt_ind, q4.fc_cpns, ck4.final_fare_amt, ck4.fc_fcs_amt, ck4.fc_paid_amt
-- rax.open_jaw(fc2.fc_orig_city,  fc2.fc_dest_city,  fc3.fc_orig_city, fc3.fc_dest_city)

from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp1 on (ck1.fc_fare_map_id = mp1.fc_fare_map_id ) 

straight_join zz_ws.temp_tbl_fc_seq q2 on (q2.doc_nbr_prime = ag.doc_nbr_prime and q2.trnsc_date = ag.trnsc_date and q2.fc_seq_nbr = 2)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck2 on (ck2.doc_nbr_prime = q2.doc_nbr_prime and ck2.fc_cpn_nbr = q2.fc_cpn_nbr
and (ck2.tourcd_ok_ind = "Y" or ck2.tourcd_na_ind = "Y" or ck2.f_tourcd_none = "Y") 
and (ck2.bcode_ok_ind = "Y" or ck2.bcode_na_ind = "Y" or ck2.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp2 on (ck2.fc_fare_map_id = mp2.fc_fare_map_id ) 
join ws_dw.sales_tkt_fc fc2 on mp2.doc_nbr_prime = fc2.doc_nbr_prime and mp2.doc_carr_nbr = fc2.carr_cd and mp2.trnsc_date = fc2.trnsc_date and mp2.fc_cpn_nbr = fc2.fc_cpn_nbr

straight_join zz_ws.temp_tbl_fc_seq q3 on (q3.doc_nbr_prime = ag.doc_nbr_prime and q3.trnsc_date = ag.trnsc_date and q3.fc_seq_nbr = 3)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck3 on (ck3.doc_nbr_prime = q3.doc_nbr_prime and ck3.fc_cpn_nbr = q3.fc_cpn_nbr 
and (ck3.tourcd_ok_ind = "Y" or ck3.tourcd_na_ind = "Y" or ck3.f_tourcd_none = "Y") 
and (ck3.bcode_ok_ind = "Y" or ck3.bcode_na_ind = "Y" or ck3.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp3 on (ck3.fc_fare_map_id = mp3.fc_fare_map_id )
join ws_dw.sales_tkt_fc fc3 on mp3.doc_nbr_prime = fc3.doc_nbr_prime and mp3.doc_carr_nbr = fc3.carr_cd and mp3.trnsc_date = fc3.trnsc_date and mp3.fc_cpn_nbr = fc3.fc_cpn_nbr 

straight_join zz_ws.temp_tbl_fc_seq q4 on (q4.doc_nbr_prime = ag.doc_nbr_prime and q4.trnsc_date = ag.trnsc_date and q4.fc_seq_nbr = 4)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck4 on (ck4.doc_nbr_prime = q4.doc_nbr_prime and ck4.fc_cpn_nbr = q4.fc_cpn_nbr
and (ck4.tourcd_ok_ind = "Y" or ck4.tourcd_na_ind = "Y" or ck4.f_tourcd_none = "Y") 
and (ck4.bcode_ok_ind = "Y" or ck4.bcode_na_ind = "Y" or ck4.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp4 on (ck4.fc_fare_map_id = mp4.fc_fare_map_id ) 

where ag.fc_cnt = 4
-- and (concat(if(ck1.fare_rt_ind = "Y","0","1"), if(ck2.fare_rt_ind = "Y","0","1"), if(ck3.fare_rt_ind = "Y","0","1"), if(ck4.fare_rt_ind = "Y","0","1")) in ("1111", "0000", "1001", "0110"))	-- 1111: all ow, 0000: rt + rt, 1001, ow+rt+ow, 0110, rt + side trips
and
	# 4 PUs, must be all one-way fares, and no reverse of the fare
	if( concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind, ck4.fare_rt_ind) = '1111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R' and ck4.fare_dir_ind <> 'R',
		true,

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if( (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
		true,

	# 2 PU, seg 1 + 4, seg 2 + 3
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 1 + 2, seg 3 + 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 1 + 3, seg 2 + 4, not sure this is a sensible pattern
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
		true,

	# 2 PU, seg 1 + 2 + 3, seg 4
    if( ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
		true,

	# 2 PU, seg 1 + 2 + 4, seg 3
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        true,

	# 2 PU, seg 1 + 3 + 4, seg 2
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        true,

	# 2 PU, seg 2 + 3 + 4, seg 1
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp2.fc_orig_city),
		true,

	# 3 PU, seg 1 + 2, seg 3, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1 + 3, seg 2, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1 + 4, seg 2, seg 3
    if( (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1, seg 2 + 3, seg 4
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1, seg 2 + 4, seg 3
    if( (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1, seg 2, seg 3 + 4
    if( (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,
        false
	)))))))))))))))

and 
not (
( (ck1.spec_fare_curr like ck2.spec_fare_curr) and (ck3.spec_fare_curr = ck4.spec_fare_curr) and (ck2.spec_fare_curr = ck3.spec_fare_curr) )
and (ck1.same_curr_ind = '1' and ck2.same_curr_ind = '1' and ck3.same_curr_ind = '1' and ck4.same_curr_ind = '1')
)
and
(@v2 :=  (if(ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt is not null, s.tkt_schrg_amt, 0) ) - ( if(p.tkt_plus_amt is not null, p.tkt_plus_amt, 0) ) ) 
* if(ck1.fare_dis_type = "C"or ck2.fare_dis_type = "C" or ck3.fare_dis_type = "C" or ck4.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
(@v1 :=
	if(ck1.int_dom_ind = 'D' and ck2.int_dom_ind = 'D' and ck3.int_dom_ind = 'D' and ck4.int_dom_ind = 'D', round(ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt, r.deci),
round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt + ck2.final_fare_amt + ck3.final_fare_amt + ck4.final_fare_amt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ), 
3)) ) )  between (1 - @amt_bnd) and (1 + @amt_bnd ) 
and ag.chosen_ind <> "Y"
;


insert into zz_ws.temp_tbl_fc_comb_4fc
(doc_nbr_prime, carr_cd, trnsc_date, tkt_fare_amt, eff_comm_rate,tkt_curr_cd,
tkt_schrg_amt, orig_schrg_amt, orig_schrg_curr, tkt_plus_amt, orig_plus_amt, orig_plus_curr,
tkt_pu_map, tkt_owrt_map, tkt_di_map,
match_pfct_ind, match_err_pct, net_fare_amt, match_amt_pct, 
calc_amt,
calc_rnd, cat14_ok_ind, cat15_ok_ind,
fc_cpn_nbr1, fc_fare_map_id1, fare_dis_type1, fare_rt_ind1, fc_cpns1, fare_amt1, fc_fcs_amt1, fc_paid_amt1,
fc_cpn_nbr2, fc_fare_map_id2, fare_dis_type2, fare_rt_ind2, fc_cpns2, fare_amt2, fc_fcs_amt2, fc_paid_amt2,
fc_cpn_nbr3, fc_fare_map_id3, fare_dis_type3, fare_rt_ind3, fc_cpns3, fare_amt3, fc_fcs_amt3, fc_paid_amt3,
fc_cpn_nbr4, fc_fare_map_id4, fare_dis_type4, fare_rt_ind4, fc_cpns4, fare_amt4, fc_fcs_amt4, fc_paid_amt4
-- open_jaw_ind
)
select
ag.doc_nbr_prime, ag.carr_cd, ag.trnsc_date, ag.tkt_fare_amt, ag.eff_comm_rate, ag.tkt_curr_cd,
( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ), s.orig_schrg_amt, s.orig_schrg_curr_alt, ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ), p.orig_plus_amt, p.orig_plus_curr_alt,  
	# 4 PUs, must be all one-way fares, and no reverse of the fare
	if( concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind, ck4.fare_rt_ind) = '1111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R' and ck4.fare_dir_ind <> 'R',
		'1234',

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if( (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
		'1111',

	# 2 PU, seg 1 + 4, seg 2 + 3
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '1221',

	# 2 PU, seg 1 + 2, seg 3 + 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1122',

	# 2 PU, seg 1 + 3, seg 2 + 4, not sure this is a sensible pattern
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
		'1212',

	# 2 PU, seg 1 + 2 + 3, seg 4
    if( ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
		'1112',

	# 2 PU, seg 1 + 2 + 4, seg 3
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        '1121',

	# 2 PU, seg 1 + 3 + 4, seg 2
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        '1211',

	# 2 PU, seg 2 + 3 + 4, seg 1
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp2.fc_orig_city),
		'1222',

	# 3 PU, seg 1 + 2, seg 3, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        '1123',

	# 3 PU, seg 1 + 3, seg 2, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '1213',

	# 3 PU, seg 1 + 4, seg 2, seg 3
    if( (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1231',

	# 3 PU, seg 1, seg 2 + 3, seg 4
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        '1223',

	# 3 PU, seg 1, seg 2 + 4, seg 3
    if( (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1232',

	# 3 PU, seg 1, seg 2, seg 3 + 4
    if( (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        '1233',
        ''
	))))))))))))))) as tkt_pu_map,


concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind, ck4.fare_rt_ind) as tkt_owrt_map,
concat(ck1.fare_dir_ind, ck2.fare_dir_ind, ck3.fare_dir_ind, ck4.fare_dir_ind) as tkt_di_map,

if( @amt_bnd < 0.01, "Y", "N"),
round((ck1.match_err_pct + ck2.match_err_pct + ck3.match_err_pct + ck4.match_err_pct) / 4, 3),
@v_n, round(@v2, 3),
@v1,
r.fare_rnd,
if(ck1.cat14_ok_ind = "Y" and ck2.cat14_ok_ind = "Y" and ck3.cat14_ok_ind = "Y" and ck4.cat14_ok_ind = "Y", "Y", "N"),
if(ck1.cat15_ok_ind = "Y" and ck2.cat15_ok_ind = "Y" and ck3.cat15_ok_ind = "Y" and ck4.cat15_ok_ind = "Y", "Y", "N"),

ck1.fc_cpn_nbr, ck1.fc_fare_map_id, ck1.fare_dis_type, ck1.fare_rt_ind, q1.fc_cpns, ck1.final_fare_amt_alt, ck1.fc_fcs_amt, ck1.fc_paid_amt,
ck2.fc_cpn_nbr, ck2.fc_fare_map_id, ck2.fare_dis_type, ck2.fare_rt_ind, q2.fc_cpns, ck2.final_fare_amt_alt, ck2.fc_fcs_amt, ck2.fc_paid_amt,
ck3.fc_cpn_nbr, ck3.fc_fare_map_id, ck3.fare_dis_type, ck3.fare_rt_ind, q3.fc_cpns, ck3.final_fare_amt_alt, ck3.fc_fcs_amt, ck3.fc_paid_amt,
ck4.fc_cpn_nbr, ck4.fc_fare_map_id, ck4.fare_dis_type, ck4.fare_rt_ind, q4.fc_cpns, ck4.final_fare_amt_alt, ck4.fc_fcs_amt, ck4.fc_paid_amt
-- rax.open_jaw(fc2.fc_orig_city,  fc2.fc_dest_city,  fc3.fc_orig_city, fc3.fc_dest_city)

from zz_ws.temp_tbl_fc_agg ag
left join zz_ws.temp_tbl_fc_agg_schrg s on (s.doc_nbr_prime = ag.doc_nbr_prime and s.carr_cd = ag.carr_cd and s.trnsc_date = ag.trnsc_date)
left join zz_ws.temp_tbl_fc_agg_plus p on (p.doc_nbr_prime = ag.doc_nbr_prime and p.carr_cd = ag.carr_cd and p.trnsc_date = ag.trnsc_date)

straight_join ws_dw.sales_tkt tkt on ag.doc_nbr_prime = tkt.doc_nbr_prime and ag.carr_cd = tkt.carr_cd and ag.trnsc_date = tkt.trnsc_date
straight_join ws_dw.sales_trnsc t on t.trnsc_nbr = tkt.trnsc_nbr and t.carr_cd = tkt.carr_cd and t.trnsc_date = tkt.trnsc_date
straight_join zz_ws.iata_rnd_tmp r on ag.tkt_curr_cd = r.curr_cd

straight_join zz_ws.temp_tbl_fc_seq q1 on (q1.doc_nbr_prime = ag.doc_nbr_prime and q1.trnsc_date = ag.trnsc_date and q1.fc_seq_nbr = 1)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck1 on (ck1.doc_nbr_prime = q1.doc_nbr_prime and ck1.fc_cpn_nbr = q1.fc_cpn_nbr 
and (ck1.tourcd_ok_ind = "Y" or ck1.tourcd_na_ind = "Y" or ck1.f_tourcd_none = "Y") 
and (ck1.bcode_ok_ind = "Y" or ck1.bcode_na_ind = "Y" or ck1.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp1 on (ck1.fc_fare_map_id = mp1.fc_fare_map_id ) 

straight_join zz_ws.temp_tbl_fc_seq q2 on (q2.doc_nbr_prime = ag.doc_nbr_prime and q2.trnsc_date = ag.trnsc_date and q2.fc_seq_nbr = 2)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck2 on (ck2.doc_nbr_prime = q2.doc_nbr_prime and ck2.fc_cpn_nbr = q2.fc_cpn_nbr
and (ck2.tourcd_ok_ind = "Y" or ck2.tourcd_na_ind = "Y" or ck2.f_tourcd_none = "Y") 
and (ck2.bcode_ok_ind = "Y" or ck2.bcode_na_ind = "Y" or ck2.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp2 on (ck2.fc_fare_map_id = mp2.fc_fare_map_id ) 
join ws_dw.sales_tkt_fc fc2 on mp2.doc_nbr_prime = fc2.doc_nbr_prime and mp2.doc_carr_nbr = fc2.carr_cd and mp2.trnsc_date = fc2.trnsc_date and mp2.fc_cpn_nbr = fc2.fc_cpn_nbr

straight_join zz_ws.temp_tbl_fc_seq q3 on (q3.doc_nbr_prime = ag.doc_nbr_prime and q3.trnsc_date = ag.trnsc_date and q3.fc_seq_nbr = 3)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck3 on (ck3.doc_nbr_prime = q3.doc_nbr_prime and ck3.fc_cpn_nbr = q3.fc_cpn_nbr 
and (ck3.tourcd_ok_ind = "Y" or ck3.tourcd_na_ind = "Y" or ck3.f_tourcd_none = "Y") 
and (ck3.bcode_ok_ind = "Y" or ck3.bcode_na_ind = "Y" or ck3.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp3 on (ck3.fc_fare_map_id = mp3.fc_fare_map_id )
join ws_dw.sales_tkt_fc fc3 on mp3.doc_nbr_prime = fc3.doc_nbr_prime and mp3.doc_carr_nbr = fc3.carr_cd and mp3.trnsc_date = fc3.trnsc_date and mp3.fc_cpn_nbr = fc3.fc_cpn_nbr 

straight_join zz_ws.temp_tbl_fc_seq q4 on (q4.doc_nbr_prime = ag.doc_nbr_prime and q4.trnsc_date = ag.trnsc_date and q4.fc_seq_nbr = 4)
straight_join zz_ws.temp_tbl_fc_fare_map_chk ck4 on (ck4.doc_nbr_prime = q4.doc_nbr_prime and ck4.fc_cpn_nbr = q4.fc_cpn_nbr
and (ck4.tourcd_ok_ind = "Y" or ck4.tourcd_na_ind = "Y" or ck4.f_tourcd_none = "Y") 
and (ck4.bcode_ok_ind = "Y" or ck4.bcode_na_ind = "Y" or ck4.f_bcode_none = "Y") )
straight_join zz_ws.temp_tbl_fc_fare_map mp4 on (ck4.fc_fare_map_id = mp4.fc_fare_map_id ) 

where ag.fc_cnt = 4
and (concat(if(ck1.fare_rt_ind = "Y","0","1"), if(ck2.fare_rt_ind = "Y","0","1"), if(ck3.fare_rt_ind = "Y","0","1"), if(ck4.fare_rt_ind = "Y","0","1")) in ("1111", "0000", "1001", "0110"))	-- 1111: all ow, 0000: rt + rt, 1001, ow+rt+ow, 0110, rt + side trips

and
	# 4 PUs, must be all one-way fares, and no reverse of the fare
	if( concat(ck1.fare_rt_ind, ck2.fare_rt_ind, ck3.fare_rt_ind, ck4.fare_rt_ind) = '1111' and ck1.fare_dir_ind <> 'R' and ck2.fare_dir_ind <> 'R' and ck3.fare_dir_ind <> 'R' and ck4.fare_dir_ind <> 'R',
		true,

	# 1 PU, the last seg must be either a return, or, last seg is bidirection then 1st and 2nd seg must be a half return
	# and a circle trip
    if( (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
		true,

	# 2 PU, seg 1 + 4, seg 2 + 3
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 1 + 2, seg 3 + 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 2 PU, seg 1 + 3, seg 2 + 4, not sure this is a sensible pattern
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD'))
        and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
		true,

	# 2 PU, seg 1 + 2 + 3, seg 4
    if( ((ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp1.fc_orig_city),
		true,

	# 2 PU, seg 1 + 2 + 4, seg 3
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck2.fare_dir_ind in ('F', 'B')))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp2.fc_orig_city and mp2.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        true,

	# 2 PU, seg 1 + 3 + 4, seg 2
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck1.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (mp1.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp1.fc_orig_city),
        true,

	# 2 PU, seg 2 + 3 + 4, seg 1
    if( ((ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2))) and (ck2.fare_dir_ind in ('F', 'B') and ck3.fare_dir_ind in ('F', 'B')))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
		and (mp2.fc_dest_city = mp3.fc_orig_city and mp3.fc_dest_city = mp4.fc_orig_city and mp4.fc_dest_city = mp2.fc_orig_city),
		true,

	# 3 PU, seg 1 + 2, seg 3, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck2.fare_dir_ind = 'R' or (ck2.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck2.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck2.fare_rt_ind = 2)))
		and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp2.fc_orig_city, mp2.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1 + 3, seg 2, seg 4
    if( (ck1.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1 + 4, seg 2, seg 3
    if( (ck1.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck1.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck1.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp1.fc_orig_city, mp1.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1, seg 2 + 3, seg 4
    if( (ck2.fare_dir_ind <> 'R' and (ck3.fare_dir_ind = 'R' or (ck3.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck3.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck3.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck4.fare_rt_ind = 1 and ck4.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp3.fc_orig_city, mp3.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1, seg 2 + 4, seg 3
    if( (ck2.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck2.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck2.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck3.fare_rt_ind = 1 and ck3.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp2.fc_orig_city, mp2.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,

	# 3 PU, seg 1, seg 2, seg 3 + 4
    if( (ck3.fare_dir_ind <> 'R' and (ck4.fare_dir_ind = 'R' or (ck4.fare_dir_ind = 'B' and (ck3.fare_rt_ind = 2 or ck4.fare_rt_ind = 2)) or (ck3.fare_rt_ind = 2 and ck4.fare_rt_ind = 2)))
		and (ck1.fare_rt_ind = 1 and ck1.fare_dir_ind in ('F', 'B'))
        and (ck2.fare_rt_ind = 1 and ck2.fare_dir_ind in ('F', 'B'))
		and (left(rax.rt_oj(mp3.fc_orig_city, mp3.fc_dest_city, mp4.fc_orig_city, mp4.fc_dest_city), 2) in ('YI', 'YD')),
        true,
        false
	)))))))))))))))

and ( (ck1.spec_fare_curr like ck2.spec_fare_curr) and (ck3.spec_fare_curr = ck4.spec_fare_curr) and (ck2.spec_fare_curr = ck3.spec_fare_curr) )
and (ck1.same_curr_ind = '1' and ck2.same_curr_ind = '1' and ck3.same_curr_ind = '1' and ck4.same_curr_ind = '1')
and
(@v2 := if(ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt = 0, 1, round((@v_n := ag.tkt_fare_amt - ( if(s.tkt_schrg_amt_alt is not null, s.tkt_schrg_amt_alt, 0) ) - ( if(p.tkt_plus_amt_alt is not null, p.tkt_plus_amt_alt, 0) ) ) 
* if(ck1.fare_dis_type = "C"or ck2.fare_dis_type = "C" or ck3.fare_dis_type = "C" or ck4.fare_dis_type = "C", (1 - ag.eff_comm_rate), 1.0) / 
(@v1 :=
	if(ck1.int_dom_ind = 'D' and ck2.int_dom_ind = 'D' and ck3.int_dom_ind = 'D' and ck4.int_dom_ind = 'D', round(ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt, r.deci),
round(case r.fare_rnd_rule
   when 'R' then round(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'D' then floor(if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   when 'U' then ceil( if(r.fare_rnd >=1, floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt) / 0.1 ) * 0.1 , floor( (ck1.final_fare_amt_alt + ck2.final_fare_amt_alt + ck3.final_fare_amt_alt + ck4.final_fare_amt_alt) / (fare_rnd /10) ) * (fare_rnd / 10) )/fare_rnd)*fare_rnd
   end,  r.deci))
   ), 
3)))  between (1 - @amt_bnd) and (1 + @amt_bnd ) 
and ag.chosen_ind <> "Y"
;

optimize table zz_ws.temp_tbl_fc_comb_4fc;


# set the indictor for the mapped ones, then don"t look for less accurate ones
update zz_ws.temp_tbl_fc_agg ag
join zz_ws.temp_tbl_fc_comb_4fc mp on (mp.doc_nbr_prime = ag.doc_nbr_prime and mp.carr_cd = ag.carr_cd and mp.trnsc_date = ag.trnsc_date)
set ag.match_ind = "Y", ag.chosen_ind = "Y";

set @amt_bnd := @amt_bnd + 0.1;

end while;

set @amt_bnd := 0.001;

# ############################################################################################## update the combination unit with price  ##################################################################################


update zz_ws.temp_tbl_fc_comb_1fc
set pu_cpns1 = fc_cpns1,
pu_io_ind1 = 'O';


update zz_ws.temp_tbl_fc_comb_2fc
set
pu_cpns1 = (	case tkt_pu_map
					when '11' then concat(fc_cpns1, ",", fc_cpns2)		# 1 PU
					when '12' then fc_cpns1								# 2 PU
				end),
pu_io_ind1 = (	case tkt_pu_map
					when '11' then 'O'		# 1 PU
					when '12' then 'O'		# 2 PU
				end),
pu_cpns2 = (	case tkt_pu_map
					when '11' then concat(fc_cpns1, ",", fc_cpns2)		# 1 PU
					when '12' then fc_cpns2								# 2 PU
				end),
pu_io_ind2 = (	case tkt_pu_map
					when '11' then 'I'		# 1 PU
					when '12' then 'O'		# 2 PU
				end)
;
                
                

update zz_ws.temp_tbl_fc_comb_3fc
set
pu_cpns1 = (	case tkt_pu_map
					when '111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3)		# 1 PU
					when '112' then concat(fc_cpns1, ",", fc_cpns2)						# 2 PU
					when '121' then concat(fc_cpns1, ",", fc_cpns3)						# 2 PU
					when '122' then fc_cpns1											# 2 PU
					when '123' then fc_cpns1											# 3 PU
				end),
pu_io_ind1 = (	case tkt_pu_map
					when '111' then 'O'		# 1 PU
					when '112' then 'O'		# 2 PU
					when '121' then 'O'		# 2 PU
					when '122' then 'O'		# 2 PU
					when '123' then 'O'		# 3 PU
				end),
pu_cpns2 = (	case tkt_pu_map
					when '111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3)		# 1 PU
					when '112' then concat(fc_cpns1, ",", fc_cpns2)						# 2 PU
					when '121' then fc_cpns2											# 2 PU
					when '122' then concat(fc_cpns2, ",", fc_cpns3)						# 2 PU
					when '123' then fc_cpns2											# 3 PU
				end),
pu_io_ind2 = (	case tkt_pu_map
					when '111' then 'O'		# 1 PU
					when '112' then 'I'		# 2 PU
					when '121' then 'O'		# 2 PU
					when '122' then 'O'		# 2 PU
					when '123' then 'O'		# 3 PU
				end),
pu_cpns3 = (	case tkt_pu_map
					when '111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3)		# 1 PU
					when '112' then fc_cpns3											# 2 PU
					when '121' then concat(fc_cpns1, ",", fc_cpns3)						# 2 PU
					when '122' then concat(fc_cpns2, ",", fc_cpns3)						# 2 PU
					when '123' then fc_cpns3											# 3 PU
				end),
pu_io_ind3 = (	case tkt_pu_map
					when '111' then 'I'		# 1 PU
					when '112' then 'O'		# 2 PU
					when '121' then 'I'		# 2 PU
					when '122' then 'I'		# 2 PU
					when '123' then 'O'		# 3 PU
				end)
;


update zz_ws.temp_tbl_fc_comb_4fc
set
pu_cpns1 = (	case tkt_pu_map
					when '1111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)		# 1 PU

					when '1221' then concat(fc_cpns1, ",", fc_cpns4)											# 2 PU
					when '1122' then concat(fc_cpns1, ",", fc_cpns2)											# 2 PU
					when '1212' then concat(fc_cpns1, ",", fc_cpns3)											# 2 PU

					when '1112' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3)						# 2 PU
					when '1121' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns4)						# 2 PU
					when '1211' then concat(fc_cpns1, ",", fc_cpns3, ",", fc_cpns4)						# 2 PU
					when '1222' then fc_cpns1																	# 2 PU

					when '1123' then concat(fc_cpns1, ",", fc_cpns2)											# 3 PU
					when '1213' then concat(fc_cpns1, ",", fc_cpns3)											# 3 PU
					when '1231' then concat(fc_cpns1, ",", fc_cpns4)											# 3 PU
					when '1223' then fc_cpns1																	# 3 PU
					when '1232' then fc_cpns1																	# 3 PU
					when '1233' then fc_cpns1																	# 3 PU

					when '1234' then fc_cpns1																	# 4 PU
				end),
pu_io_ind1 = (	case tkt_pu_map
					when '1111' then 'O'	# 1 PU

					when '1221' then 'O'	# 2 PU
					when '1122' then 'O'	# 2 PU
					when '1212' then 'O'	# 2 PU

					when '1112' then 'O'	# 2 PU
					when '1121' then 'O'	# 2 PU
					when '1211' then 'O'	# 2 PU
					when '1222' then 'O'	# 2 PU

					when '1123' then 'O'	# 3 PU
					when '1213' then 'O'	# 3 PU
					when '1231' then 'O'	# 3 PU
					when '1223' then 'O'	# 3 PU
					when '1232' then 'O'	# 3 PU
					when '1233' then 'O'	# 3 PU

					when '1234' then 'O'	# 4 PU
				end),
pu_cpns2 = (	case tkt_pu_map
					when '1111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)		# 1 PU

					when '1221' then concat(fc_cpns2, ",", fc_cpns3)											# 2 PU
					when '1122' then concat(fc_cpns1, ",", fc_cpns2)											# 2 PU
					when '1212' then concat(fc_cpns2, ",", fc_cpns4)											# 2 PU

					when '1112' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3)						# 2 PU
					when '1121' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns4)						# 2 PU
					when '1211' then fc_cpns2																	# 2 PU
					when '1222' then concat(fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)						# 2 PU

					when '1123' then concat(fc_cpns1, ",", fc_cpns2)											# 3 PU
					when '1213' then fc_cpns2																	# 3 PU
					when '1231' then fc_cpns2																	# 3 PU
					when '1223' then concat(fc_cpns2, ",", fc_cpns3)											# 3 PU
					when '1232' then concat(fc_cpns2, ",", fc_cpns4)											# 3 PU
					when '1233' then fc_cpns2																	# 3 PU

					when '1234' then fc_cpns2																	# 4 PU
				end),
pu_io_ind2 = (	case tkt_pu_map
					when '1111' then 'O'	# 1 PU

					when '1221' then 'O'	# 2 PU
					when '1122' then 'I'	# 2 PU
					when '1212' then 'O'	# 2 PU

					when '1112' then 'O'	# 2 PU
					when '1121' then 'O'	# 2 PU
					when '1211' then 'O'	# 2 PU
					when '1222' then 'O'	# 2 PU

					when '1123' then 'I'	# 3 PU
					when '1213' then 'O'	# 3 PU
					when '1231' then 'O'	# 3 PU
					when '1223' then 'O'	# 3 PU
					when '1232' then 'O'	# 3 PU
					when '1233' then 'O'	# 3 PU

					when '1234' then 'O'	# 4 PU
				end),
pu_cpns3 = (	case tkt_pu_map
					when '1111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)		# 1 PU

					when '1221' then concat(fc_cpns2, ",", fc_cpns3)											# 2 PU
					when '1122' then concat(fc_cpns3, ",", fc_cpns4)											# 2 PU
					when '1212' then concat(fc_cpns1, ",", fc_cpns3)											# 2 PU

					when '1112' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3)						# 2 PU
					when '1121' then fc_cpns3																	# 2 PU
					when '1211' then concat(fc_cpns1, ",", fc_cpns3, ",", fc_cpns4)						# 2 PU
					when '1222' then concat(fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)						# 2 PU

					when '1123' then fc_cpns3																	# 3 PU
					when '1213' then concat(fc_cpns1, ",", fc_cpns3)											# 3 PU
					when '1231' then fc_cpns3																	# 3 PU
					when '1223' then concat(fc_cpns2, ",", fc_cpns3)											# 3 PU
					when '1232' then fc_cpns3																	# 3 PU
					when '1233' then concat(fc_cpns3, ",", fc_cpns4)											# 3 PU

					when '1234' then fc_cpns3																	# 4 PU
				end),
pu_io_ind3 = (	case tkt_pu_map
					when '1111' then 'O'	# 1 PU

					when '1221' then 'I'	# 2 PU
					when '1122' then 'O'	# 2 PU
					when '1212' then 'I'	# 2 PU

					when '1112' then 'I'	# 2 PU
					when '1121' then 'O'	# 2 PU
					when '1211' then 'O'	# 2 PU
					when '1222' then 'O'	# 2 PU

					when '1123' then 'O'	# 3 PU
					when '1213' then 'I'	# 3 PU
					when '1231' then 'O'	# 3 PU
					when '1223' then 'I'	# 3 PU
					when '1232' then 'O'	# 3 PU
					when '1233' then 'O'	# 3 PU

					when '1234' then 'O'	# 4 PU
				end),
pu_cpns4 = (	case tkt_pu_map
					when '1111' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)		# 1 PU

					when '1221' then concat(fc_cpns1, ",", fc_cpns4)											# 2 PU
					when '1122' then concat(fc_cpns3, ",", fc_cpns4)											# 2 PU
					when '1212' then concat(fc_cpns2, ",", fc_cpns4)											# 2 PU

					when '1112' then fc_cpns4																	# 2 PU
					when '1121' then concat(fc_cpns1, ",", fc_cpns2, ",", fc_cpns4)						# 2 PU
					when '1211' then concat(fc_cpns1, ",", fc_cpns3, ",", fc_cpns4)						# 2 PU
					when '1222' then concat(fc_cpns2, ",", fc_cpns3, ",", fc_cpns4)						# 2 PU

					when '1123' then fc_cpns4																	# 3 PU
					when '1213' then fc_cpns4																	# 3 PU
					when '1231' then concat(fc_cpns1, ",", fc_cpns4)											# 3 PU
					when '1223' then fc_cpns4																	# 3 PU
					when '1232' then concat(fc_cpns2, ",", fc_cpns4)											# 3 PU
					when '1233' then concat(fc_cpns3, ",", fc_cpns4)											# 3 PU

					when '1234' then fc_cpns4																	# 4 PU
				end),
pu_io_ind4 = (	case tkt_pu_map
					when '1111' then 'I'	# 1 PU

					when '1221' then 'I'	# 2 PU
					when '1122' then 'I'	# 2 PU
					when '1212' then 'I'	# 2 PU

					when '1112' then 'O'	# 2 PU
					when '1121' then 'I'	# 2 PU
					when '1211' then 'I'	# 2 PU
					when '1222' then 'I'	# 2 PU

					when '1123' then 'O'	# 3 PU
					when '1213' then 'O'	# 3 PU
					when '1231' then 'I'	# 3 PU
					when '1223' then 'O'	# 3 PU
					when '1232' then 'I'	# 3 PU
					when '1233' then 'I'	# 3 PU

					when '1234' then 'O'	# 4 PU
				end)
;

# ############################################################################################################## 1 combinations  ##################################################################################

delete mp from ws_dw.map_tkt_fare mp
where audit_batch = in_audit_batch  or audit_batch = '';

optimize table ws_dw.map_tkt_fare;

insert into ws_dw.map_tkt_fare
(fare_map_id, doc_nbr_prime, carr_cd, trnsc_date, fare_lockin_date, fc_cpn_nbr, map_type, map_code, map_di_ind, dis_type, pu_cpns, pu_io_ind,
#calc_fare_amt, calc_fare_curr,
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, fare_link_nbr_ver, fare_link_seq_ver,
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id,
oadd_orig_city, oadd_dest_city, oadd_carr_cd, oadd_fare_cls, oadd_tar_nbr, oadd_link_nbr, oadd_link_seq,
dadd_orig_city, dadd_dest_city, dadd_carr_cd, dadd_fare_cls, dadd_tar_nbr, dadd_link_nbr, dadd_link_seq
)
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type1, dp.pu_cpns1, pu_io_ind1, # always outbound for 1 FC ticket
#dp.fare_amt1, dp.tkt_curr_cd,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_1fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id1)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
;

# ############################################################################################################## 2 combinations  ##################################################################################
-- generate all fare combination with 2 fare components

#-----------------------------------------------------------------------------------------------------------------------
# transfer results to the mapping table

insert into ws_dw.map_tkt_fare
(fare_map_id, doc_nbr_prime, carr_cd, trnsc_date, fare_lockin_date, fc_cpn_nbr, map_type, map_code, map_di_ind, dis_type, 
pu_cpns, pu_io_ind,
#calc_fare_amt, calc_fare_curr,
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, fare_link_nbr_ver, fare_link_seq_ver, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id,
oadd_orig_city, oadd_dest_city, oadd_carr_cd, oadd_fare_cls, oadd_tar_nbr, oadd_link_nbr, oadd_link_seq,
dadd_orig_city, dadd_dest_city, dadd_carr_cd, dadd_fare_cls, dadd_tar_nbr, dadd_link_nbr, dadd_link_seq
)
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date,  mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type1,
dp.pu_cpns1, pu_io_ind1,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_2fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id1)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
union
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type2,
dp.pu_cpns2, pu_io_ind2,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_2fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id2)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
;

# ############################################################################################################## 3 combinations  ##################################################################################
-- generate all fare combination with 3 fare components


#-----------------------------------------------------------------------------------------------------------------------
# determine journey turnaround, so that we can determine pu_io

/* old code, no need to compute the distance
update zz_ws.temp_tbl_fc_comb_3fc dp
join zz_ws.temp_tbl_fc_fare_map fc1 on (fc1.fc_fare_map_id = dp.fc_fare_map_id1)
join zz_ws.temp_tbl_fc_fare_map fc2 on (fc2.fc_fare_map_id = dp.fc_fare_map_id2)
join zz_ws.temp_tbl_fc_fare_map fc3 on (fc3.fc_fare_map_id = dp.fc_fare_map_id3)
set 
to_orig_dist1 = if(fc1.fc_dest = fc2.fc_orig, rax.dist_calc2(fc1.fc_orig, fc1.fc_dest), greatest(rax.dist_calc2(fc1.fc_orig, fc1.fc_dest), rax.dist_calc2(fc1.fc_orig, fc2.fc_orig))),
to_orig_dist2 = if(fc2.fc_dest = fc3.fc_orig, rax.dist_calc2(fc1.fc_orig, fc2.fc_dest), greatest(rax.dist_calc2(fc1.fc_orig, fc2.fc_dest), rax.dist_calc2(fc1.fc_orig, fc3.fc_orig)));
*/

#-----------------------------------------------------------------------------------------------------------------------
# transfer results to the mapping table

insert into ws_dw.map_tkt_fare
(fare_map_id, doc_nbr_prime, carr_cd, trnsc_date, fare_lockin_date, fc_cpn_nbr, map_type, map_code, map_di_ind, dis_type, pu_cpns, pu_io_ind,
#calc_fare_amt, calc_fare_curr,
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, fare_link_nbr_ver, fare_link_seq_ver, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id,
oadd_orig_city, oadd_dest_city, oadd_carr_cd, oadd_fare_cls, oadd_tar_nbr, oadd_link_nbr, oadd_link_seq,
dadd_orig_city, dadd_dest_city, dadd_carr_cd, dadd_fare_cls, dadd_tar_nbr, dadd_link_nbr, dadd_link_seq
)
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type1,
dp.pu_cpns1, pu_io_ind1,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_3fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id1)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
union
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type2,
dp.pu_cpns2, pu_io_ind2,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_3fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id2)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
union
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type3,
dp.pu_cpns3, pu_io_ind3,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_3fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id3)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
;

# ############################################################################################################## 4 combinations  ##################################################################################
-- generate all fare combination with 4 fare components
#-----------------------------------------------------------------------------------------------------------------------
# determine journey turnaround, so that we can determine pu_io

/* old code, no need to compute the distance
update zz_ws.temp_tbl_fc_comb_4fc dp
join zz_ws.temp_tbl_fc_fare_map fc1 on (fc1.fc_fare_map_id = dp.fc_fare_map_id1)
join zz_ws.temp_tbl_fc_fare_map fc2 on (fc2.fc_fare_map_id = dp.fc_fare_map_id2)
join zz_ws.temp_tbl_fc_fare_map fc3 on (fc3.fc_fare_map_id = dp.fc_fare_map_id3)
join zz_ws.temp_tbl_fc_fare_map fc4 on (fc4.fc_fare_map_id = dp.fc_fare_map_id4)
set
to_orig_dist1 = if(fc1.fc_dest = fc2.fc_orig, rax.dist_calc2(fc1.fc_orig, fc1.fc_dest), greatest(rax.dist_calc2(fc1.fc_orig, fc1.fc_dest), rax.dist_calc2(fc1.fc_orig, fc2.fc_orig))),
to_orig_dist2 = if(fc2.fc_dest = fc3.fc_orig, rax.dist_calc2(fc1.fc_orig, fc2.fc_dest), greatest(rax.dist_calc2(fc1.fc_orig, fc2.fc_dest), rax.dist_calc2(fc1.fc_orig, fc3.fc_orig))),
to_orig_dist3 = if(fc3.fc_dest = fc4.fc_orig, rax.dist_calc2(fc1.fc_orig, fc3.fc_dest), greatest(rax.dist_calc2(fc1.fc_orig, fc3.fc_dest), rax.dist_calc2(fc1.fc_orig, fc4.fc_orig)));
*/

#-----------------------------------------------------------------------------------------------------------------------
# transfer results to the mapping table

insert into ws_dw.map_tkt_fare
(fare_map_id, doc_nbr_prime, carr_cd, trnsc_date, fare_lockin_date, fc_cpn_nbr, map_type, map_code, map_di_ind, dis_type, pu_cpns, pu_io_ind,
#calc_fare_amt, calc_fare_curr,
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, fare_link_nbr_ver, fare_link_seq_ver, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id,
oadd_orig_city, oadd_dest_city, oadd_carr_cd, oadd_fare_cls, oadd_tar_nbr, oadd_link_nbr, oadd_link_seq,
dadd_orig_city, dadd_dest_city, dadd_carr_cd, dadd_fare_cls, dadd_tar_nbr, dadd_link_nbr, dadd_link_seq
)
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type1,
dp.pu_cpns1, pu_io_ind1,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_4fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id1)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
union
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type2,
dp.pu_cpns2, pu_io_ind2,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_4fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id2)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
union
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type3,
dp.pu_cpns3, pu_io_ind3,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_4fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id3)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
union
select distinct
mp.fc_fare_map_id, mp.doc_nbr_prime, mp.doc_carr_nbr, mp.trnsc_date, mp.fare_lockin_date, mp.fc_cpn_nbr, mp.map_type, map_code, mp.map_di_ind, dp.fare_dis_type4,
dp.pu_cpns4, pu_io_ind4,
if(spec_fare_id=0, fc.fc_orig, f.orig_city), if(spec_fare_id=0, fc.fc_dest, f.dest_city), f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, f.link_nbr_ver, f.link_seq_ver,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, r2.cat_nbr, r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, mp.c25_r3_cat_id,
oa.orig_city, oa.dest_city, oa.carr_cd, oa.fare_cls, oa.tar_nbr, oa.link_nbr, oa.link_seq,
da.orig_city, da.dest_city, da.carr_cd, da.fare_cls, da.tar_nbr, da.link_nbr, da.link_seq
from zz_ws.temp_tbl_fc_comb_4fc dp
join zz_ws.temp_tbl_fc_fare_map mp on (mp.fc_fare_map_id = dp.fc_fare_map_id4)
join ws_dw.sales_tkt_fc fc on mp.doc_nbr_prime = fc.doc_nbr_prime and mp.doc_carr_nbr = fc.carr_cd and mp.trnsc_date = fc.trnsc_date and mp.fc_cpn_nbr = fc.fc_cpn_nbr
left join atpco_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
left join atpco_fare.atpco_r2_cat25_ctrl r2 on (r2.rule_id = mp.cat25_r2_id)
left join atpco_fare.atpco_addon oa on (oa.fare_id = mp.oadd_fare_id)
left join atpco_fare.atpco_addon da on (da.fare_id = mp.dadd_fare_id)
#where dp.chosen_ind = "Y"
;

##################################### update the batch number in the fare main audit 
update ws_dw.map_tkt_fare m
join ws_audit.audit_fare_main a 
on m.doc_nbr_prime = a.doc_nbr_prime and m.carr_cd = a.carr_cd and m.trnsc_date = a.trnsc_date
set m.audit_batch = a.audit_batch
where a.audit_batch = in_audit_batch
; 

##################################### update the map code
update ws_dw.map_tkt_fare m
join zz_ws.temp_tbl_fc_fare_map_chk c
on m.fare_map_id = c.fc_fare_map_id
set 
m.fare_pax_type = c.fare_pax_type,
m.fare_disc_pct = c.disc_base_pct,
m.fare_tour_cd = c.fare_tour_cd,
m.map_code =
case 
when (bcode_ok_ind = 'Y' and tourcd_ok_ind = 'Y') then 'B'
when (bcode_ok_ind = 'Y' ) then 'A'
when (tourcd_ok_ind = 'Y' ) then 'T'
else 'Y'
end 
where m.audit_batch = in_audit_batch
; 

##################################### set selecting indicator
update ws_audit.audit_fare_main m
set fare_selected_ind = 'N'
where m.audit_batch = in_audit_batch;

update ws_audit.audit_fare_main m
set fare_selected_ind = 'Y'
where m.audit_batch = in_audit_batch
and m.doc_nbr_prime in
(
select distinct doc_nbr_prime from ws_dw.map_tkt_fare where audit_batch = in_audit_batch
);

##################################### record the fare_map_id from map_tkt_fare

update zz_ws.temp_tbl_fc_comb_1fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr1 and m.pu_cpns = c.pu_cpns1 and m.fare_map_id = c.fc_fare_map_id1 and m.pu_io_ind = c.pu_io_ind1)
set c.exp_fare_map_id1 = m.map_id;

update zz_ws.temp_tbl_fc_comb_2fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr1 and m.pu_cpns = c.pu_cpns1 and m.fare_map_id = c.fc_fare_map_id1 and m.pu_io_ind = c.pu_io_ind1)
set c.exp_fare_map_id1 = m.map_id;

update zz_ws.temp_tbl_fc_comb_2fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr2 and m.pu_cpns = c.pu_cpns2 and m.fare_map_id = c.fc_fare_map_id2 and m.pu_io_ind = c.pu_io_ind2)
set c.exp_fare_map_id2 = m.map_id;

update zz_ws.temp_tbl_fc_comb_3fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr1 and m.pu_cpns = c.pu_cpns1 and m.fare_map_id = c.fc_fare_map_id1 and m.pu_io_ind = c.pu_io_ind1)
set c.exp_fare_map_id1 = m.map_id;

update zz_ws.temp_tbl_fc_comb_3fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr2 and m.pu_cpns = c.pu_cpns2 and m.fare_map_id = c.fc_fare_map_id2 and m.pu_io_ind = c.pu_io_ind2)
set c.exp_fare_map_id2 = m.map_id;

update zz_ws.temp_tbl_fc_comb_3fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr3 and m.pu_cpns = c.pu_cpns3 and m.fare_map_id = c.fc_fare_map_id3 and m.pu_io_ind = c.pu_io_ind3)
set c.exp_fare_map_id3 = m.map_id;

update zz_ws.temp_tbl_fc_comb_4fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr1 and m.pu_cpns = c.pu_cpns1 and m.fare_map_id = c.fc_fare_map_id1 and m.pu_io_ind = c.pu_io_ind1)
set c.exp_fare_map_id1 = m.map_id;

update zz_ws.temp_tbl_fc_comb_4fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr2 and m.pu_cpns = c.pu_cpns2 and m.fare_map_id = c.fc_fare_map_id2 and m.pu_io_ind = c.pu_io_ind2)
set c.exp_fare_map_id2 = m.map_id;

update zz_ws.temp_tbl_fc_comb_4fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr3 and m.pu_cpns = c.pu_cpns3 and m.fare_map_id = c.fc_fare_map_id3 and m.pu_io_ind = c.pu_io_ind3)
set c.exp_fare_map_id3 = m.map_id;

update zz_ws.temp_tbl_fc_comb_4fc c
join ws_dw.map_tkt_fare m on (m.doc_nbr_prime = c.doc_nbr_prime and m.fc_cpn_nbr = c.fc_cpn_nbr4 and m.pu_cpns = c.pu_cpns4 and m.fare_map_id = c.fc_fare_map_id4 and m.pu_io_ind = c.pu_io_ind4)
set c.exp_fare_map_id4 = m.map_id;

######################################  transfer results to the mapping table
delete from ws_dw.map_tkt_fare_comb_sum where audit_batch = in_audit_batch or audit_batch = '';

insert into ws_dw.map_tkt_fare_comb_sum
(doc_nbr_prime, carr_cd, trnsc_date, 
pu_cpns_map, pu_io_ind_map, map_comb, tkt_pu_map, tkt_owrt_map, tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, fc_cnt, schrg_amt, schrg_curr, plus_amt, plus_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, 
concat(dp.pu_cpns1), concat(dp.pu_io_ind1), concat(dp.exp_fare_map_id1), 
dp.tkt_pu_map, dp.tkt_owrt_map, dp.tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, 1, tkt_schrg_amt, tkt_curr_cd, tkt_plus_amt, tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_1fc dp
#where dp.chosen_ind = "Y"
;

insert into ws_dw.map_tkt_fare_comb_sum
(doc_nbr_prime, carr_cd, trnsc_date, 
pu_cpns_map, pu_io_ind_map, map_comb, tkt_pu_map, tkt_owrt_map, tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, fc_cnt, schrg_amt, schrg_curr, plus_amt, plus_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, 
concat(dp.pu_cpns1, "_", dp.pu_cpns2), concat(dp.pu_io_ind1, dp.pu_io_ind2), concat(dp.exp_fare_map_id1, "_", dp.exp_fare_map_id2), 
dp.tkt_pu_map, dp.tkt_owrt_map, dp.tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, 2, tkt_schrg_amt, tkt_curr_cd, tkt_plus_amt, tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_2fc dp
;

insert into ws_dw.map_tkt_fare_comb_sum
(doc_nbr_prime, carr_cd, trnsc_date, 
pu_cpns_map, pu_io_ind_map, map_comb, tkt_pu_map, tkt_owrt_map, tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, fc_cnt, schrg_amt, schrg_curr, plus_amt, plus_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, 
concat(dp.pu_cpns1, "_", dp.pu_cpns2, "_", dp.pu_cpns3), concat(dp.pu_io_ind1, dp.pu_io_ind2, dp.pu_io_ind3), concat(dp.exp_fare_map_id1, "_", dp.exp_fare_map_id2, "_", dp.exp_fare_map_id3), 
dp.tkt_pu_map, dp.tkt_owrt_map, dp.tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, 3, tkt_schrg_amt, tkt_curr_cd, tkt_plus_amt, tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_3fc dp
;

insert into ws_dw.map_tkt_fare_comb_sum
(doc_nbr_prime, carr_cd, trnsc_date, 
pu_cpns_map, pu_io_ind_map, map_comb, tkt_pu_map, tkt_owrt_map, tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, fc_cnt, schrg_amt, schrg_curr, plus_amt, plus_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, 
concat(dp.pu_cpns1, "_", dp.pu_cpns2, "_", dp.pu_cpns3, "_", dp.pu_cpns4), concat(dp.pu_io_ind1, dp.pu_io_ind2, dp.pu_io_ind3, dp.pu_io_ind4), concat(dp.exp_fare_map_id1, "_", dp.exp_fare_map_id2, "_", dp.exp_fare_map_id3, "_", dp.exp_fare_map_id4), 
dp.tkt_pu_map, dp.tkt_owrt_map, dp.tkt_di_map, net_fare_amt, calc_amt, match_amt_pct, 4, tkt_schrg_amt, tkt_curr_cd, tkt_plus_amt, tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_4fc dp
;

# ############################################################################################################## update the combination table ###############################################################################################################
# ============================================================================================================================================================================================================================= #
######################################  dump tkt fare mapping combination
delete mp from ws_dw.map_tkt_fare_comb mp
where mp.audit_batch = in_audit_batch or audit_batch = '';

optimize table ws_dw.map_tkt_fare_comb ;

insert into ws_dw.map_tkt_fare_comb
(doc_nbr_prime, carr_cd, trnsc_date, map_comb, match_amt_pct, fc_cpn_nbr, fc_fare_map_id, 
calc_fare_amt, calc_fare_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, dp.exp_fare_map_id1, match_amt_pct, dp.fc_cpn_nbr1, dp.exp_fare_map_id1,
dp.fare_amt1, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_1fc dp
#where dp.chosen_ind = "Y"
;

# dump tkt fare mapping combination

insert into ws_dw.map_tkt_fare_comb
(doc_nbr_prime, carr_cd, trnsc_date, map_comb, match_amt_pct, fc_cpn_nbr, fc_fare_map_id, 
calc_fare_amt, calc_fare_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2), dp.match_amt_pct, dp.fc_cpn_nbr1, dp.exp_fare_map_id1,
dp.fare_amt1, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_2fc dp
#where dp.chosen_ind = "Y"
union
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2), dp.match_amt_pct, dp.fc_cpn_nbr2, dp.exp_fare_map_id2,
dp.fare_amt2, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_2fc dp
#where dp.chosen_ind = "Y"
;

insert into ws_dw.map_tkt_fare_comb
(doc_nbr_prime, carr_cd, trnsc_date, map_comb, match_amt_pct, fc_cpn_nbr, fc_fare_map_id, 
calc_fare_amt, calc_fare_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3), dp.match_amt_pct, dp.fc_cpn_nbr1, dp.exp_fare_map_id1,
dp.fare_amt1, dp.tkt_curr_cd, in_audit_batch

from zz_ws.temp_tbl_fc_comb_3fc dp
#where dp.chosen_ind = "Y"
union
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3), dp.match_amt_pct, dp.fc_cpn_nbr2, dp.exp_fare_map_id2,
dp.fare_amt2, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_3fc dp
#where dp.chosen_ind = "Y"
union
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3), dp.match_amt_pct, dp.fc_cpn_nbr3, dp.exp_fare_map_id3,
dp.fare_amt3, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_3fc dp
#where dp.chosen_ind = "Y"
;

# dump tkt fare mapping combination

insert into ws_dw.map_tkt_fare_comb
(doc_nbr_prime, carr_cd, trnsc_date, map_comb, match_amt_pct, fc_cpn_nbr, fc_fare_map_id, 
calc_fare_amt, calc_fare_curr, audit_batch)
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3,"_",dp.exp_fare_map_id4), dp.match_amt_pct, dp.fc_cpn_nbr1, dp.exp_fare_map_id1,
dp.fare_amt1, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_4fc dp
#where dp.chosen_ind = "Y"
union
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3,"_",dp.exp_fare_map_id4), dp.match_amt_pct, dp.fc_cpn_nbr2, dp.exp_fare_map_id2,
dp.fare_amt2, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_4fc dp
#where dp.chosen_ind = "Y"
union
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3,"_",dp.exp_fare_map_id4), dp.match_amt_pct, dp.fc_cpn_nbr3, dp.exp_fare_map_id3,
dp.fare_amt3, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_4fc dp
#where dp.chosen_ind = "Y"
union
select distinct
dp.doc_nbr_prime, dp.carr_cd, dp.trnsc_date, concat(dp.exp_fare_map_id1,"_",dp.exp_fare_map_id2,"_",dp.exp_fare_map_id3,"_",dp.exp_fare_map_id4), dp.match_amt_pct, dp.fc_cpn_nbr4, dp.exp_fare_map_id4,
dp.fare_amt4, dp.tkt_curr_cd, in_audit_batch
from zz_ws.temp_tbl_fc_comb_4fc dp
#where dp.chosen_ind = "Y"
;

optimize table ws_dw.map_tkt_fare_comb;
# ############################################################################################################## update table audit_fare_main ###############################################################################################################

delete mp from ws_dw.map_tkt_fare_schrg mp
where audit_batch = in_audit_batch or audit_batch = '';

optimize table ws_dw.map_tkt_fare_schrg;

insert into ws_dw.map_tkt_fare_schrg (doc_nbr_prime, carr_cd, trnsc_date, fcs_schrg_amt, orig_schrg_amt, fc_schrg_amt,  tkt_schrg_amt, tkt_schrg_curr, orig_schrg_curr_1, orig_schrg_curr_2, audit_batch)
	                           select doc_nbr_prime, carr_cd, trnsc_date, fcs_schrg_amt, orig_schrg_amt, fc_schrg_amt,  tkt_schrg_amt, tkt_schrg_curr, orig_schrg_curr, orig_schrg_curr_alt, in_audit_batch from zz_ws.temp_tbl_fc_agg_schrg;
# ############################################################################################################## update table audit_fare_main ###############################################################################################################
# -----------------------------------------------------------------------
/*
drop table if exists ws_dw.temp_tbl_fc_fare_map_cnt;

create table ws_dw.temp_tbl_fc_fare_map_cnt engine = MyISAM
select doc_nbr_prime, doc_carr_nbr as carr_cd, trnsc_date, fc_cpn_nbr, count(*) as cnt
from zz_ws.temp_tbl_fc_fare_map
group by doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr;
*/
# -----------------------------------------------------------------------

END