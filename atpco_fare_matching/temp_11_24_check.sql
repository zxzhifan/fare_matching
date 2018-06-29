 #$$$$$$$$$$$$$$$$$$$            get fbr and addon
delete from zz_ws_law.temp_tbl_fc_fare_map where map_type = 'R';
 insert into zz_ws_law.temp_tbl_fc_fare_map
fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
cat25_r2_id, cat35_r2_id, 
map_amt_pct)
SELECT distinct
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, fc.tkt_tour_cd,
map_di_ind, 'R', 'F', fc.fc_disc_pct,  fc.fare_id, fc.ftnt,
fc.cat_id, fc.r2_rule_id,
map_amt_pct
 FROM zz_ws_law.tmp_r2 fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
 straight_join ws_fare.atpco_r2_cat_ctrl r2_35 on r2_35.rule_id=fc.r35_rule_id
 #where map_amt_pct between 0.99 and 1.01
 ;
 /*
  insert into zz_ws_law.temp_tbl_fc_fare_map
(doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, 
fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
cat25_r2_id, cat35_r2_id, 
map_amt_pct)
SELECT distinct 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, fc.tkt_tour_cd,
map_di_ind, 'R', 'T', fc.fc_disc_pct,  fc.fare_id, fc.ftnt,
fc.cat_id, fc.r2_rule_id,
map_amt_pct
 FROM zz_ws_law.tmp_r2_m fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
 straight_join ws_fare.atpco_r2_cat_ctrl r2_35 on r2_35.rule_id=fc.r35_rule_id
 #where map_amt_pct between 0.99 and 1.01
 ;
 
  
  insert into zz_ws_law.temp_tbl_fc_fare_map
(doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, 
fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg , fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
cat25_r2_id, cat35_r2_id, 
map_amt_pct)
SELECT distinct 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, fc.tkt_tour_cd,
map_di_ind, 'R', 'T', fc.fc_disc_pct,  fc.fare_id, fc.ftnt,
fc.cat_id, fc.r2_rule_id,
map_amt_pct
 FROM zz_ws_law.tmp_r2_m2 fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
 straight_join ws_fare.atpco_r2_cat_ctrl r2_35 on r2_35.rule_id=fc.r35_rule_id
 #where map_amt_pct between 0.99 and 1.01
 ;
 */
   insert into zz_ws_law.temp_tbl_fc_fare_map
(doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, 
fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
cat25_r2_id, cat35_r2_id, 
map_amt_pct)
SELECT distinct 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, fc.tkt_tour_cd,
map_di_ind, 'R', 'F', fc.fc_disc_pct,  fc.fare_id, fc.ftnt,
fc.cat_id, fc.r2_rule_id,
map_amt_pct
 FROM zz_ws_law.tmp_r2_dsgn_candelete fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id

 #where map_amt_pct between 0.99 and 1.01
 ;
 
 ################################################################################### cat 35 check and cat 27 check table
 
 # =============================================================================================================================================================================================================================
# CAT 35 + CAT 27 Checking for tourbox

-- do a quick clean-up of the tourcodes
update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = replace(tkt_tour_cd, 'ITSCHED CHG', '');

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = replace(std_tour_cd, 'SKED CHNG', '');

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = replace(std_tour_cd, 'ITSCHEDCHG', '');

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = replace(std_tour_cd, 'PAX ', '');

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = replace(std_tour_cd, '/BULK', '');

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = replace(std_tour_cd, 'N/A', '');

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = ''
where std_tour_cd = 'NA';

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = ''
where std_tour_cd = '.';

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = ''
where std_tour_cd = '-';

update zz_ws_law.temp_tbl_fc_fare_map
set std_tour_cd = trim(std_tour_cd);


# Prepare a table for searching for record 1 of CAT27 and CAT35

drop table if exists zz_ws_law.temp_tbl_fc_fare_map_c27c35;

create table zz_ws_law.temp_tbl_fc_fare_map_c27c35 ENGINE = MyISAM
select distinct mp.doc_nbr_prime, mp.trnsc_date, mp.fc_cpn_nbr, mp.spec_fare_id
from zz_ws_law.temp_tbl_fc_fare_map mp
join ws_dw.sales_tkt_fc fc on (fc.doc_nbr_prime = mp.doc_nbr_prime and fc.trnsc_date = mp.trnsc_date and fc.fc_cpn_nbr = mp.fc_cpn_nbr)
where mp.map_type = 'S'	-- only checking for Specified
and fc.tkt_tour_cd <> '';


# ------------------------------------------------------------------------------------------------
# find and determine record 1


drop table if exists zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1;

create table zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1 ENGINE = MyISAM
select distinct mp.doc_nbr_prime, mp.trnsc_date, mp.fc_cpn_nbr, mp.spec_fare_id, r1.seq_nbr as r1_seq_nbr, r1.rule_id as r1_rule_id, convert('Y', char(1)) as min_seq_ind
from zz_ws_law.temp_tbl_fc_fare_map_c27c35 mp
Straight_join ws_dw.sales_tkt_fc fc on (fc.doc_nbr_prime = mp.doc_nbr_prime and fc.trnsc_date = mp.trnsc_date and fc.fc_cpn_nbr = mp.fc_cpn_nbr)
Straight_join ws_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
Straight_join ws_fare.atpco_g16 g on (f.carr_cd = g.carr_cd and f.tar_nbr = g.ff_nbr)
Straight_join ws_fare.atpco_r1_fare_cls r1 on (f.carr_cd = r1.carr_cd and g.frt_nbr = r1.tar_nbr and f.rule_nbr = r1.rule_nbr and f.fare_cls = r1.fare_cls)
Straight_join ws_fare.atpco_r1_fare_cls_state r1t on (r1.rule_id = r1t.rule_id)		-- To get date info
Straight_join genie.iata_airport_city oc on (fc.fc_orig_city = oc.city_cd)
Straight_join genie.iata_airport_city dc on (fc.fc_dest_city = dc.city_cd)
Straight_join genie.ref_atpco_zone oz on (f.orig_cntry = oz.cntry_cd)			-- Get zone and area
Straight_join genie.ref_atpco_zone dz on (f.dest_cntry = dz.cntry_cd)			-- Get zone and area
where
-- Match trnsc_date to record add and cancellation date in rec1 state table
mp.trnsc_date between date_add(r1t.rec_add_date, interval -1 day) and if(r1t.rec_cnx_date = '9999-12-31', r1t.rec_cnx_date, date_add(r1t.rec_cnx_date, interval 1 day))	
-- Match trnsc date to record add and tvl_dis_date in rec1 state table - sale date must be on/before last travel date
and mp.trnsc_date between date_add(r1t.rec_add_date, interval -1 day) and r1t.tvl_dis_date
-- Match journey origin date to tvl_eff_date and tvl_dis_date in rec1 state table	
and fc.jrny_dep_date between r1t.tvl_eff_date and r1t.tvl_dis_date
# Matching OW/RT: Fare to Record 1
-- 1 = Oneway fare that may be doubled or halved
-- 2 = Round Trip Fare
-- 3 = Oneway fare that may not be doubled or halved
-- A Fare with a OW/RT of 1 or 3 = Record 1 with an indicator 1
-- A Fare with a OW/RT of 2 = Record 1 with an OW/RT of 2
and (f.ow_rt_ind = r1.ow_rt_ind or (f.ow_rt_ind = 3 and r1.ow_rt_ind = 1))
# Match routing: Fare and Record 1
-- 00000 - Matches to any MPM Fare
-- 99999 - Matches to a fare with any routing number of mileage
and (f.rtg_nbr = r1.rtg_nbr or r1.rtg_nbr = '99999')
# Match Footnote: Fare to Record 1
and if(r1.ftnt = '', true, if(length(f.ftnt) = 2 and (left(f.ftnt,1) between 'A' and 'Z'), left(f.ftnt,1) = r1.ftnt or right(f.ftnt,1) = r1.ftnt, f.ftnt = r1.ftnt))
# Match Fare City to Loc 1 and Loc 2 in Record 1
and (case r1.loc1_type
		when 'C' then		-- Must be exact match for city/airport code from orig/dest - Use fare orig/dest city
			(case r1.loc2_type
				when '' then fc.fc_orig_city = r1.loc1 or f.dest_city = r1.loc1
				when 'C' then (f.orig_city = r1.loc1 and f.dest_city = r1.loc2)		or (f.dest_city = r1.loc1 and f.orig_city = r1.loc2)			
				when 'N' then (f.orig_city = r1.loc1 and f.dest_cntry = r1.loc2)	or (f.dest_city = r1.loc1 and f.orig_cntry = r1.loc2)
                when 'S' then (f.orig_city = r1.loc1 and dc.us_state_cd = mid(r1.loc2, 3, 2))	or (f.dest_city = r1.loc1 and oc.us_state_cd = mid(r1.loc2, 3, 2))
				when 'Z' then (f.orig_city = r1.loc1 and dz.zone = r1.loc2)			or (f.dest_city = r1.loc1 and oz.zone = r1.loc2)
				when 'A' then (f.orig_city = r1.loc1 and dz.area_cd = r1.loc2)  	or (f.dest_city = r1.loc1 and oz.area_cd = r1.loc2)
				else true
			end)
		when 'N' then		-- Use atpco country code as populated with RU/XU
			(case r1.loc2_type
				when '' then f.orig_cntry = r1.loc1 or f.dest_cntry = r1.loc1
				when 'C' then (f.orig_cntry = r1.loc1 and f.dest_city = r1.loc2)	or (f.dest_cntry = r1.loc1 and f.orig_city = r1.loc2)
				when 'N' then (f.orig_cntry = r1.loc1 and f.dest_cntry = r1.loc2)	or (f.dest_cntry = r1.loc1 and f.orig_cntry = r1.loc2)
                when 'S' then (f.orig_cntry = r1.loc1 and dc.us_state_cd = mid(r1.loc2, 3, 2))	or (f.dest_cntry = r1.loc1 and oc.us_state_cd = mid(r1.loc2, 3, 2))
				when 'Z' then (f.orig_cntry = r1.loc1 and dz.zone = r1.loc2)		or (f.dest_cntry = r1.loc1 and oz.zone = r1.loc2)
				when 'A' then (f.orig_cntry = r1.loc1 and dz.area_cd = r1.loc2)		or (f.dest_cntry = r1.loc1 and oz.area_cd = r1.loc2)
				else true
			end)
		when 'S' then		-- Added State Code for US only
			(case r1.loc2_type
				when '' then oc.us_state_cd = r1.loc1 or dc.us_state_cd = r1.loc1
				when 'C' then (oc.us_state_cd = r1.loc1 and f.dest_city = r1.loc2)		or (dc.us_state_cd = r1.loc1 and f.orig_city = r1.loc2)			
				when 'N' then (oc.us_state_cd = r1.loc1 and f.dest_cntry = r1.loc2)		or (dc.us_state_cd = r1.loc1 and f.orig_cntry = r1.loc2)
                when 'S' then (oc.us_state_cd = r1.loc1 and dc.us_state_cd = mid(r1.loc2, 3, 2))	or (dc.us_state_cd = r1.loc1 and oc.us_state_cd = mid(r1.loc2, 3, 2))
				when 'Z' then (oc.us_state_cd = r1.loc1 and dz.zone = r1.loc2)			or (dc.us_state_cd = r1.loc1 and oz.zone = r1.loc2)
				when 'A' then (oc.us_state_cd = r1.loc1 and dz.area_cd = r1.loc2)  		or (dc.us_state_cd = r1.loc1 and oz.area_cd = r1.loc2)
				else true
			end)
		when 'Z' then		-- Can be multiple zone for 1 country
			(case r1.loc2_type
				when '' then oz.zone = r1.loc1 or dz.zone = r1.loc1
				when 'C' then (oz.zone = r1.loc1 and f.dest_city = r1.loc2)		or (dz.zone = r1.loc1 and f.orig_city = r1.loc2)
				when 'N' then (oz.zone = r1.loc1 and f.dest_cntry = r1.loc2)	or (dz.zone = r1.loc1 and f.orig_cntry = r1.loc2)
                when 'S' then (oz.zone = r1.loc1 and dc.us_state_cd = mid(r1.loc2, 3, 2))	or (dz.zone = r1.loc1 and oc.us_state_cd = mid(r1.loc2, 3, 2))
				when 'Z' then (oz.zone = r1.loc1 and dz.zone = r1.loc2)			or (dz.zone = r1.loc1 and oz.zone = r1.loc2)
				when 'A' then (oz.zone = r1.loc1 and dz.area_cd = r1.loc2)		or (dz.zone = r1.loc1 and oz.area_cd = r1.loc2)
				else true
			end)
		when 'A' then 
			(case r1.loc2_type
				when '' then oz.area_cd = r1.loc1 or dz.area_cd = r1.loc1
				when 'C' then (oz.area_cd = r1.loc1 and f.dest_city = r1.loc2)		or (dz.area_cd = r1.loc1 and f.orig_city = r1.loc2)
				when 'N' then (oz.area_cd = r1.loc1 and f.dest_cntry = r1.loc2)		or (dz.area_cd = r1.loc1 and f.orig_cntry = r1.loc2)
                when 'S' then (oz.area_cd = r1.loc1 and dc.us_state_cd = mid(r1.loc2, 3, 2))	or (dz.area_cd = r1.loc1 and oc.us_state_cd = mid(r1.loc2, 3, 2))
				when 'Z' then (oz.area_cd = r1.loc1 and dz.zone = r1.loc2)			or (dz.area_cd = r1.loc1 and oz.zone = r1.loc2)
				when 'A' then (oz.area_cd = r1.loc1 and dz.area_cd = r1.loc2)		or (dz.area_cd = r1.loc1 and oz.area_cd = r1.loc2)
				else true
			end)
		else true
	end)
and not(fare_type = '' and ssn_type = '' and dow_type = '' and prc_type = '' and dis_type = '' and unavl_ind = '' and txt_tbl_t996 = 0 and seg_cnt = 0)			-- Exclude cancellation record 1
;

ALTER TABLE zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1
ADD INDEX `idx` (`doc_nbr_prime` ASC);

-- Select the lowest sequence for record 1
update zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1 H, zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1 L
set H.min_seq_ind = 'N'
where H.doc_nbr_prime = L.doc_nbr_prime
and H.trnsc_date = L.trnsc_date
and H.fc_cpn_nbr = L.fc_cpn_nbr
and H.spec_fare_id = L.spec_fare_id
and H.r1_seq_nbr > L.r1_seq_nbr;     -- Later sequence not applicable

-- if there are multiple 

# ------------------------------------------------------------------------------------------------
# find and determine record 2

drop table if exists zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2;

create table zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 Engine = 'MYISAM'
select distinct mp.doc_nbr_prime, mp.trnsc_date, mp.fc_cpn_nbr, mp.spec_fare_id, r1_rule_id, r2.seq_nbr as r2_seq_nbr, r2.rule_id as r2_rule_id, r2.cat_nbr as r2_cat_nbr, convert('Y', char(1)) as min_seq_ind
from zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1 mp
Straight_join ws_dw.sales_tkt_fc fc on (fc.doc_nbr_prime = mp.doc_nbr_prime and fc.trnsc_date = mp.trnsc_date and fc.fc_cpn_nbr = mp.fc_cpn_nbr)
straight_join ws_fare.atpco_fare f on (f.fare_id = mp.spec_fare_id)
straight_join ws_fare.atpco_r1_fare_cls r1 on (mp.r1_rule_id = r1.rule_id)
straight_join ws_fare.atpco_r2_cat_ctrl r2 on (r1.carr_cd = r2.carr_cd and r1.tar_nbr = r2.tar_nbr and r1.rule_nbr = r2.rule_nbr and r2.cat_nbr in (27, 35))
Straight_join ws_fare.atpco_r2_cat_ctrl_state r2t on (r2.rule_id = r2t.rule_id)
straight_join genie.iata_airport_city oc on (fc.fc_orig_city = oc.city_cd)			-- Use orig_city_actual as airpt_cd already match to city_cd
straight_join genie.iata_airport_city dc on (fc.fc_dest_city = dc.city_cd)			-- Use dest_city_actual as airpt_cd already match to city_cd
Straight_join genie.ref_atpco_zone oz on (f.orig_cntry = oz.cntry_cd)			-- Get zone and area
Straight_join genie.ref_atpco_zone dz on (f.dest_cntry = dz.cntry_cd)			-- Get zone and area
where mp.min_seq_ind = 'Y'		-- Only pick applicable record 1
-- Match Loc 1 and Loc 2 of Record 2
and (
	case r2.loc1_type
		when 'C' then
			(case r2.loc2_type
				when '' then f.orig_city = r2.loc1 or f.dest_city = r2.loc1
				when 'C' then (f.orig_city = r2.loc1 and f.dest_city = r2.loc2)		or (f.dest_city = r2.loc1 and f.orig_city = r2.loc2)
				when 'N' then (f.orig_city = r2.loc1 and f.dest_cntry = r2.loc2)	or (f.dest_city = r2.loc1 and f.orig_cntry = r2.loc2)
				when 'S' then (f.orig_city = r2.loc1 and dc.us_state_cd = mid(r2.loc2, 3, 2))	or (f.dest_city = r2.loc1 and oc.us_state_cd = mid(r2.loc2, 3, 2))
				when 'Z' then (f.orig_city = r2.loc1 and dz.zone = r2.loc2)				or (f.dest_city = r2.loc1 and oz.zone = r2.loc2)
				when 'A' then (f.orig_city = r2.loc1 and dz.area_cd = r2.loc2)  			or (f.dest_city = r2.loc1 and oz.area_cd = r2.loc2)
				else true
			end)
		when 'N' then
			(case r2.loc2_type
				when '' then f.orig_cntry = r2.loc1 or f.dest_cntry = r2.loc1
				when 'C' then (f.orig_cntry = r2.loc1 and f.dest_city = r2.loc2)	or (f.dest_cntry = r2.loc1 and f.orig_city = r2.loc2)
				when 'N' then (f.orig_cntry = r2.loc1 and f.dest_cntry = r2.loc2)	or (f.dest_cntry = r2.loc1 and f.orig_cntry = r2.loc2)
                when 'S' then (f.orig_cntry = r2.loc1 and dc.us_state_cd = mid(r2.loc2, 3, 2))	or (f.dest_cntry = r2.loc1 and oc.us_state_cd = mid(r2.loc2, 3, 2))
				when 'Z' then (f.orig_cntry = r2.loc1 and dz.zone = r2.loc2)				or (f.dest_cntry = r2.loc1 and oz.zone = r2.loc2)
				when 'A' then (f.orig_cntry = r2.loc1 and dz.area_cd = r2.loc2)			or (f.dest_cntry = r2.loc1 and oz.area_cd = r2.loc2)
				else true
			end)
		when 'S' then
			(case r2.loc2_type
				when '' then oc.us_state_cd = r2.loc1 or dc.us_state_cd = r2.loc1
				when 'C' then (oc.us_state_cd = r2.loc1 and f.dest_city = r2.loc2)		or (dc.us_state_cd = r2.loc1 and f.orig_city = r2.loc2)
				when 'N' then (oc.us_state_cd = r2.loc1 and f.dest_cntry = r2.loc2)		or (dc.us_state_cd = r2.loc1 and f.orig_cntry = r2.loc2)
                when 'S' then (oc.us_state_cd = r2.loc1 and dc.us_state_cd = mid(r2.loc2, 3, 2))	or (dc.us_state_cd = r2.loc1 and oc.us_state_cd = mid(r2.loc2, 3, 2))
				when 'Z' then (oc.us_state_cd = r2.loc1 and dz.zone = r2.loc2)					or (dc.us_state_cd = r2.loc1 and oz.zone = r2.loc2)
				when 'A' then (oc.us_state_cd = r2.loc1 and dz.area_cd = r2.loc2)				or (dc.us_state_cd = r2.loc1 and oz.area_cd = r2.loc2)
				else true
			end)
		when 'Z' then
			(case r2.loc2_type
				when '' then oz.zone = r2.loc1 or dz.zone = r2.loc1
				when 'C' then (oz.zone = r2.loc1 and f.dest_city = r2.loc2)		or (dz.zone = r2.loc1 and f.orig_city = r2.loc2)
				when 'N' then (oz.zone = r2.loc1 and f.dest_cntry = r2.loc2)		or (dz.zone = r2.loc1 and f.orig_cntry = r2.loc2)
                when 'S' then (oz.zone = r2.loc1 and dc.us_state_cd = mid(r2.loc2, 3, 2))	or (dz.zone = r2.loc1 and oc.us_state_cd = mid(r2.loc2, 3, 2))
				when 'Z' then (oz.zone = r2.loc1 and dz.zone = r2.loc2)					or (dz.zone = r2.loc1 and oz.zone = r2.loc2)
				when 'A' then (oz.zone = r2.loc1 and dz.area_cd = r2.loc2)				or (dz.zone = r2.loc1 and oz.area_cd = r2.loc2)
				else true
			end)
		when 'A' then 
			(case r2.loc2_type
				when '' then oz.area_cd = r2.loc1 or dz.area_cd = r2.loc1
				when 'C' then (oz.area_cd = r2.loc1 and f.dest_city = r2.loc2)		or (dz.area_cd = r2.loc1 and f.orig_city = r2.loc2)
				when 'N' then (oz.area_cd = r2.loc1 and f.dest_cntry = r2.loc2)		or (dz.area_cd = r2.loc1 and f.orig_cntry = r2.loc2)
                when 'S' then (oz.area_cd = r2.loc1 and dc.us_state_cd = mid(r2.loc2, 3, 2))	or (dz.area_cd = r2.loc1 and oc.us_state_cd = mid(r2.loc2, 3, 2))
				when 'Z' then (oz.area_cd = r2.loc1 and dz.zone = r2.loc2)					or (dz.area_cd = r2.loc1 and oz.zone = r2.loc2)
				when 'A' then (oz.area_cd = r2.loc1 and dz.area_cd = r2.loc2)				or (dz.area_cd = r2.loc1 and oz.area_cd = r2.loc2)
				else true
			end)
		else true
	end)
and if(r2.fare_cls = '', true, if(instr(r2.fare_cls, '-') = 0, r2.fare_cls = f.fare_cls, f.fare_cls regexp r2.fare_cls_regex))	-- Match fare class
and (r1.fare_type = r2.fare_type or r2.fare_type = '')		-- Match fare type
and (r1.ssn_type = r2.ssn_type or r2.ssn_type = '')			-- Match Season Type
and (r1.dow_type = r2.dow_type or r2.dow_type = '')			-- Match Day of Week Type
# Match OW/RT of Fare Record to Record 2
-- Fare record with a OW/RT indicator of 1 or 3 = Record 2 with a OW/RT indicator of 1 or blank
-- Fare record with a OW/RT of 2 = Record 2 with a OW/RT of 2 or blank
and (f.ow_rt_ind = r2.ow_rt_ind or (f.ow_rt_ind = 3 and r2.ow_rt_ind = 1) or r2.ow_rt_ind = '')
# Match routing: Fare and Record 2
-- 00000 - Matches to any MPM Fare
-- 88888 - Matches to any specified routing number
-- 99999 - Matches to a fare with any routing number of mileage
and (f.rtg_nbr = r2.rtg_nbr or (f.rtg_nbr <> '00000' and r2.rtg_nbr = '88888') or r2.rtg_nbr = '99999')			-- Match Routing number
-- Fare Footnote AC will match to Rec2 AC, CA, A, C or Blank
and if(r2.ftnt = '', true, if(length(f.ftnt) = 2 and (left(f.ftnt,1) between 'A' and 'Z'), 			-- Match footnote
	left(f.ftnt,1) = r2.ftnt or right(f.ftnt,1) = r2.ftnt or 
	if(right(f.ftnt, 1) between 'A' and 'Z', concat(right(f.ftnt,1), left(f.ftnt,1)) = r2.ftnt, false), -- AC=CA, A2<>2A
		f.ftnt = r2.ftnt))
-- Match trnsc_date to record add and cancellation date in rec1 state table
and mp.trnsc_date between date_add(r2t.rec_add_date, interval -1 day) and if(r2t.rec_cnx_date = '9999-12-31', r2t.rec_cnx_date, date_add(r2t.rec_cnx_date, interval 1 day))	
-- Match trnsc date to reco`rd add and tvl_dis_date in rec1 state table - sale date must be on/before last travel date
and mp.trnsc_date between date_add(r2t.rec_add_date, interval -1 day) and r2t.tvl_dis_date
-- Match journey origin date to tvl_eff_date and tvl_dis_date in rec1 state table	
and fc.jrny_dep_date between r2t.tvl_eff_date and r2t.tvl_dis_date
and not (r2.no_app_ind = '' and r2.gr_src_tar_nbr = '000' and r2.gr_rule_nbr = '0000' and r2.gr_app_ind = '' and r2.seg_cnt = 0); 		-- Exclude Cancellation Record 2


ALTER TABLE zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2
ADD INDEX `idx` (doc_nbr_prime ASC, trnsc_date ASC, fc_cpn_nbr ASC, `spec_fare_id` ASC);

update zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 H, zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 L
set H.min_seq_ind = 'N'
where H.doc_nbr_prime = L.doc_nbr_prime
and H.trnsc_date = L.trnsc_date
and H.fc_cpn_nbr = L.fc_cpn_nbr
and H.spec_fare_id = L.spec_fare_id
and H.r1_rule_id = L.r1_rule_id
and H.r2_cat_nbr = L.r2_cat_nbr
and H.r2_seq_nbr > L.r2_seq_nbr;     -- Later sequence not applicable

# ------------------------------------------------------------------------------------------------
# update back to fare matching, to eliminate the ones with incorrect tourcode
select * from zz_ws_law.temp_tbl_fc_fare_map where fare_match_ind='N';

update zz_ws_law.temp_tbl_fc_fare_map
set
tourcd_exist_in_fare = 'N',
tourcd_match_to_fare = 'N',
fare_match_ind = 'Y';

-- because there are possibilities multiple record 1s and record 2s are mapped to the fare (due to rule changes and we give +- 1 day)
-- give the priority to the one that matches perfectly

-- check cat 35
update zz_ws_law.temp_tbl_fc_fare_map mp
join zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 r2_mp on (mp.doc_nbr_prime = r2_mp.doc_nbr_prime and mp.trnsc_date = r2_mp.trnsc_date and mp.fc_cpn_nbr = r2_mp.fc_cpn_nbr and mp.spec_fare_id = r2_mp.spec_fare_id)
join ws_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join ws_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 35)
join ws_fare.atpco_cat35 r3 on (r2s.tbl_nbr = r3.cat_id)
join ws_fare.atpco_cat35_sup r3s on (r3.cat_id = r3s.cat_id)
set mp.cat35_r2_id = r2.rule_id,
mp.tourcd_exist_in_fare = 'Y',
mp.tourcd_match_to_fare = 'Y'
where mp.tkt_tour_cd <> ''
and r3s.tour_box = mp.tkt_tour_cd
and mp.map_type='S';

-- check cat 27
update zz_ws_law.temp_tbl_fc_fare_map mp
join zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 r2_mp on (mp.doc_nbr_prime = r2_mp.doc_nbr_prime and mp.trnsc_date = r2_mp.trnsc_date and mp.fc_cpn_nbr = r2_mp.fc_cpn_nbr and mp.spec_fare_id = r2_mp.spec_fare_id)
join ws_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join ws_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 27)
join ws_fare.atpco_cat27 r3 on (r2s.tbl_nbr = r3.cat_id)
set mp.cat27_r2_id = r2.rule_id,
mp.tourcd_exist_in_fare = 'Y',
mp.tourcd_match_to_fare = 'Y'
where mp.tkt_tour_cd <> ''
and r3.tour_nbr = mp.tkt_tour_cd
and mp.map_type='S';

-- for the rest, assign the tour code matching status

-- check cat 35
update zz_ws_law.temp_tbl_fc_fare_map mp
join zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 r2_mp on (mp.doc_nbr_prime = r2_mp.doc_nbr_prime and mp.trnsc_date = r2_mp.trnsc_date and mp.fc_cpn_nbr = r2_mp.fc_cpn_nbr and mp.spec_fare_id = r2_mp.spec_fare_id)
join ws_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join ws_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 35)
join ws_fare.atpco_cat35 r3 on (r2s.tbl_nbr = r3.cat_id)
join ws_fare.atpco_cat35_sup r3s on (r3.cat_id = r3s.cat_id)
set mp.cat35_r2_id = r2.rule_id,
mp.tourcd_exist_in_fare = if(r3s.tour_box = '', 'N', 'Y'),
mp.tourcd_match_to_fare = if(r3s.tour_box = mp.tkt_tour_cd, 'Y', 'N')		-- cannot be 'Y', otherwise it would have been set to true during the earlier step
where mp.tkt_tour_cd <> ''
and cat35_r2_id is null
and mp.map_type='S';


-- check cat 27
update zz_ws_law.temp_tbl_fc_fare_map mp
join zz_ws_law.temp_tbl_fc_fare_map_c27c35_r1_r2 r2_mp on (mp.doc_nbr_prime = r2_mp.doc_nbr_prime and mp.trnsc_date = r2_mp.trnsc_date and mp.fc_cpn_nbr = r2_mp.fc_cpn_nbr and mp.spec_fare_id = r2_mp.spec_fare_id)
join ws_fare.atpco_r2_cat_ctrl r2 on (r2_mp.r2_rule_id = r2.rule_id)
join ws_fare.atpco_r2_cat_ctrl_sup r2s on (r2.rule_id = r2s.rule_id and r2s.cat_nbr = 27)
join ws_fare.atpco_cat27 r3 on (r2s.tbl_nbr = r3.cat_id)
set mp.cat27_r2_id = r2.rule_id,
mp.tourcd_exist_in_fare = if(r3.tour_nbr = '', 'N', 'Y'),
mp.tourcd_match_to_fare = if(r3.tour_nbr = mp.tkt_tour_cd, 'Y', 'N')		-- cannot be 'Y', otherwise it would have been set to true during the earlier step
where mp.tkt_tour_cd <> ''
and cat27_r2_id is null
and mp.map_type='S';


-- eliminate cases where both tkt and fare have tour codes but don't match
update zz_ws_law.temp_tbl_fc_fare_map 
set fare_match_ind = 'N'
where tkt_tour_cd <> ''
and tourcd_exist_in_fare = 'Y'
and tourcd_match_to_fare = 'N'
and map_type='S';

-- eliminate cases where where ticket doesn't have tour code and fare requires a tour code
update zz_ws_law.temp_tbl_fc_fare_map
set fare_match_ind = 'N'
where tkt_tour_cd = ''
and tourcd_exist_in_fare = 'Y'
and map_type='S';

-- eliminate cases where where ticket has tour code and fare doesn't have a tour code
update zz_ws_law.temp_tbl_fc_fare_map
set fare_match_ind = 'N'
where tkt_tour_cd <> ''
and tourcd_exist_in_fare = 'N'
and map_type='S';

# =============================================================================================================================================================================================================================

 
-- ALTER TABLE zz_ws_law.temp_tbl_fc_fare_map 
-- ADD INDEX idx (doc_nbr_prime ASC);


# =============================================================================================================================================================================================================================
/*         temporarily comment it out as ws does not have addon-fare
# constructed fare matching
select * from zz_ws_law.temp_tbl_fc_fare_map;
select * from zz_ws_law.temp_fcm_c1_10_13 t1;
select * from zz_ws_law.temp_tbl_fc_all;

insert ignore into zz_ws_law.temp_tbl_fc_fare_map 
(doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
oadd_fare_id, dadd_fare_id,
map_amt_pct)
select fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, tkt_tour_cd,
fc.map_di_ind, 'C' as map_type, map_di_ind, fc_disc_pct, t1.f_fare_id, t1.f_ftnt,
t1.ado1_fare_id, t1.ado2_fare_id,
t1.map_amt_pct
from zz_ws_law.temp_tbl_fc_all fc
join zz_ws_law.temp_fcm_c1_10_13 t1
on fc.doc_nbr_prime=t1.doc_nbr_prime and fc.fc_cpn_nbr=t1.fc_cpn_nbr and fc.fc_carr_cd=t1.fc_carr_cd and fc.fc_orig=t1.fc_orig_city and fc.fc_dest=t1.fc_dest_city and fc.fc_disc_pct=t1.disc_pct;

insert ignore into zz_ws_law.temp_tbl_fc_fare_map 
(doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
oadd_fare_id, dadd_fare_id,
map_amt_pct)
select fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, tkt_tour_cd,
fc.map_di_ind, 'C' as map_type, map_di_ind, fc_disc_pct, t1.f_fare_id, t1.f_ftnt,
t1.ado1_fare_id, t1.ado2_fare_id,
t1.map_amt_pct
from zz_ws_law.temp_tbl_fc_all fc
join zz_ws_law.temp_fcm_c1_m_10_13 t1
on fc.doc_nbr_prime=t1.doc_nbr_prime and fc.fc_cpn_nbr=t1.fc_cpn_nbr and fc.fc_carr_cd=t1.fc_carr_cd and fc.fc_orig=t1.fc_orig_city and fc.fc_dest=t1.fc_dest_city and fc.fc_disc_pct=t1.disc_pct;

# match the remaining with fc.fare_match_ind = 'N'
*/
# =============================================================================================================================================================================================================================
# FBR fare matching
/*
select * from zz_ws_law.temp_tbl_fc_all fc;
select * from zz_ws_law.tmp_r2 t1;

insert ignore into zz_ws_law.temp_tbl_fc_fare_map 
(doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, fcs, fcs_std, fc_orig, fc_orig_cntry, fc_dest, fc_dest_cntry, fc_carr_cd, fc_fbc, fc_mile_plus, fc_tkt_dsg, fc_pax_type, fc_curr_cd, fc_amt, fc_roe, fc_nuc_amt, jrny_dep_date, tkt_tour_cd,
map_di_ind, map_type, map_code, map_disc_pct, spec_fare_id, spec_fare_ftnt, 
oadd_fare_id, dadd_fare_id,
map_amt_pct)
select fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, fc.fcs, fc.fcs_std, fc.fc_orig, fc.fc_orig_cntry, fc.fc_dest, fc.fc_dest_cntry, fc.fc_carr_cd, fc.fc_fbc, fc.fc_mile_plus, fc.fc_tkt_dsg, fc.fc_pax_type, fc.fc_curr_cd, fc.fc_amt, fc.fc_roe, fc.fc_nuc_amt, fc.jrny_dep_date, tkt_tour_cd,
fc.map_di_ind, 'R' as map_type, map_di_ind, fc_disc_pct, t1.f_fare_id, t1.f_ftnt,
t1.ado1_fare_id, t1.ado2_fare_id,
t1.map_amt_pct
from zz_ws_law.temp_tbl_fc_all fc
join zz_ws_law.tmp_r2 t1
on fc.doc_nbr_prime=t1.doc_nbr_prime and fc.fc_cpn_nbr=t1.fc_cpn_nbr and fc.fc_carr_cd=t1.fc_carr_cd and fc.fc_orig=t1.fc_orig_city and fc.fc_dest=t1.fc_dest_city and fc.fc_disc_pct=t1.disc_pct;
*/
# =============================================================================================================================================================================================================================
/*
# temporarily set for Cyrus' checking
update ws_dw.sales_tkt_fc fc
set fare_match_ind = 'N';

update ws_dw.sales_tkt_fc fc
inner join zz_ws_law.temp_tbl_fc_fare_map mp
	on (fc.doc_nbr_prime = mp.doc_nbr_prime and fc.fc_carr_cd = mp.doc_carr_nbr and fc.trnsc_date = mp.trnsc_date and fc.fc_cpn_nbr = mp.fc_cpn_nbr)
set fc.fare_match_ind = 'Y';


update zz_ws_law.temp_tbl_fc_all fc
inner join zz_ws_law.temp_tbl_fc_fare_map mp
	on (fc.doc_nbr_prime = mp.doc_nbr_prime and fc.doc_carr_nbr = mp.doc_carr_nbr and fc.trnsc_date = mp.trnsc_date and fc.fc_cpn_nbr = mp.fc_cpn_nbr)
set fc.fare_match_ind = 'Y';

*/
##################################### ftnt processing
# =============================================================================================================================================================================================================================
# CAT 14 and 15 filter


# ------------------------------------------------------------------------------------------------

# Check if cats are passed, mainly on dates only, the rest is left to final audit
# each rule can have multiple segments, they are the OR relationships

# CAT 14


# ------------------------------------------------------------------------------------------------

# aggregate result at per sub-ftnt level (just incase if there are multiple instances of the same sequence - due to update



##################################### matching back
# =============================================================================================================================================================================================================================
# Transfer result to final mapping

# create table ws_dw.map_tkt_fare_170915 engine = MyISAM
# SELECT * FROM ws_dw.map_tkt_fare;


##################################### build checking table
# =============================================================================================================================================================================================================================
# ------------------------------------------------------------------------------
	#step3
select * from ws_fare.atpco_fare ;
select * from zz_ws_law.temp_tbl_fc_fare_map;
select * from zz_ws_law.tmp_r2 fc;

delete from zz_ws_law.map_tkt_fare where map_type='S';
insert into zz_ws_law.map_tkt_fare
(doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, map_type, map_code, map_disc_pct, map_di_ind, map_amt_pct, cat14_pass_ind, cat15_pass_ind)
select 
doc_nbr_prime, doc_carr_nbr, trnsc_date, fc_cpn_nbr, f.orig_city, f.dest_city, f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq, map_type, map_code, map_disc_pct, map_di_ind, m.map_amt_pct, cat14_ok_ind, cat15_ok_ind
from zz_ws_law.temp_tbl_fc_fare_map m
join ws_fare.atpco_fare f on m.spec_fare_id = f.fare_id and m.map_type='S'
where (m.map_amt_pct between 0.986 and 1.014) or m.fc_amt=0 ; #or m.map_amt_pct is null;
optimize table zz_ws_law.map_tkt_fare;

select count(distinct doc_nbr_prime, fc_cpn_nbr) from zz_ws_law.map_tkt_fare where map_type='S';
select * from zz_ws_law.tmp_r2 where doc_nbr_prime=5702415861;
select * from zz_ws_law.map_tkt_fare where doc_nbr_prime=5702415861;

delete from zz_ws_law.map_tkt_fare where map_type='R';

  insert into zz_ws_law.map_tkt_fare
(doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, 
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, 
map_type, map_code, map_disc_pct, map_di_ind, map_amt_pct, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id, 
neg_r2_tar_nbr, neg_r2_carr_cd, neg_r2_rule_nbr, neg_r2_cat_nbr, neg_r2_seq_nbr, neg_r2_eff_date, neg_r2_mcn_nbr, neg_r2_bat_nbr)
SELECT 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
fc.orig_city, f.dest_city, f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq,
'R', 'F', fc.c25_fcalc_percent, map_di_ind, map_amt_pct,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, '25', r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, fc.cat_id,
r2_35.tar_nbr, r2_35.carr_cd, r2_35.rule_nbr, r2_35.cat_nbr, r2_35.seq_nbr, r2_35.eff_date, r2_35.mcn, r2_35.bat_nbr
 FROM zz_ws_law.tmp_r2 fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
 straight_join ws_fare.atpco_r2_cat_ctrl r2_35 on r2_35.rule_id=fc.r35_rule_id
where (fc.map_amt_pct between 0.986 and 1.014) or fc.fc_amt=0 ; #or fc.map_amt_pct is null;

 /*
  insert into zz_ws_law.map_tkt_fare
(
doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, 
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, 
map_type, map_code, map_disc_pct, map_di_ind, map_amt_pct, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id, 
neg_r2_tar_nbr, neg_r2_carr_cd, neg_r2_rule_nbr, neg_r2_cat_nbr, neg_r2_seq_nbr, neg_r2_eff_date, neg_r2_mcn_nbr, neg_r2_bat_nbr
)
SELECT 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
fc.orig_city, f.dest_city, f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq,
'R', 'T', fc.c25_fcalc_percent, map_di_ind, map_amt_pct,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, '25', r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, fc.cat_id,
r2_35.tar_nbr, r2_35.carr_cd, r2_35.rule_nbr, r2_35.cat_nbr, r2_35.seq_nbr, r2_35.eff_date, r2_35.mcn, r2_35.bat_nbr
 FROM zz_ws_law.tmp_r2_m fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
 straight_join ws_fare.atpco_r2_cat_ctrl r2_35 on r2_35.rule_id=fc.r35_rule_id
where (fc.map_amt_pct between 0.986 and 1.014) or fc.fc_amt=0 ; #or fc.map_amt_pct is null;

 
   insert into zz_ws_law.map_tkt_fare
(
doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, 
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, 
map_type, map_code, map_disc_pct, map_di_ind, map_amt_pct, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id, 
neg_r2_tar_nbr, neg_r2_carr_cd, neg_r2_rule_nbr, neg_r2_cat_nbr, neg_r2_seq_nbr, neg_r2_eff_date, neg_r2_mcn_nbr, neg_r2_bat_nbr
)
SELECT 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
f.orig_city, f.dest_city, f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq,
'R', 'T', fc.c25_fcalc_percent, map_di_ind, map_amt_pct,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, '25', r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, fc.cat_id,
r2_35.tar_nbr, r2_35.carr_cd, r2_35.rule_nbr, r2_35.cat_nbr, r2_35.seq_nbr, r2_35.eff_date, r2_35.mcn, r2_35.bat_nbr
 FROM zz_ws_law.tmp_r2_m2 fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
 straight_join ws_fare.atpco_r2_cat_ctrl r2_35 on r2_35.rule_id=fc.r35_rule_id
where (fc.map_amt_pct between 0.986 and 1.014) or fc.fc_amt=0 ; #or fc.map_amt_pct is null;
*/
   insert into zz_ws_law.map_tkt_fare
(
doc_nbr_prime, carr_cd, trnsc_date, fc_cpn_nbr, 
fare_orig_city, fare_dest_city, fare_carr_cd, fare_cls, fare_tar_nbr, fare_link_nbr, fare_link_seq, 
map_type, map_code, map_disc_pct, map_di_ind, map_amt_pct, 
fbr_r2_tar_nbr, fbr_r2_carr_cd, fbr_r2_rule_nbr, fbr_r2_cat_nbr, fbr_r2_seq_nbr, fbr_r2_eff_date, fbr_r2_mcn_nbr, fbr_r2_bat_nbr, c25_r3_cat_id
)
SELECT 
fc.doc_nbr_prime, fc.doc_carr_nbr, fc.trnsc_date, fc.fc_cpn_nbr, 
f.orig_city, f.dest_city, f.carr_cd, f.fare_cls, f.tar_nbr, f.link_nbr, f.link_seq,
'R', 'F', fc.c25_fcalc_percent, map_di_ind, map_amt_pct,
r2.tar_nbr, r2.carr_cd, r2.rule_nbr, '25', r2.seq_nbr, r2.eff_date, r2.mcn, r2.bat_nbr, fc.cat_id
 FROM zz_ws_law.tmp_r2_dsgn_candelete fc
 join ws_fare.atpco_fare f on fc.fare_id=f.fare_id
 straight_join ws_fare.atpco_r2_cat25_ctrl r2 on fc.r2_rule_id=r2.rule_id
where (fc.map_amt_pct between 0.986 and 1.014) or fc.fc_amt=0 ; #or fc.map_amt_pct is null;

select * from zz_ws_law.tmp_r2_dsgn_candelete;

select * from genie.ref_pax_disc;
optimize table zz_ws_law.map_tkt_fare;

##################################### build checking table
# =============================================================================================================================================================================================================================
# ------------------------------------------------------------------------------
 select * from ws_dw.sales_tkt_fc;
 
 update ws_dw.sales_tkt_fc a
 set a.fare_match_ind='N';
 
select count(*) from zz_ws_law.map_tkt_fare;
select count(*) from ws_dw.sales_tkt_fc where fare_match_ind='N';

select * from zz_ws_law.temp_tbl_fc_fare_map where fare_match_ind ='N';
select * from zz_ws_law.map_tkt_fare where doc_nbr_prime=9568663090;
select * from zz_ws_law.temp_fc_check where doc_nbr_prime=9568663090;

 update ws_dw.sales_tkt_fc a
 join zz_ws_law.temp_tbl_fc_fare_map b on a.doc_nbr_prime=b.doc_nbr_prime and a.fc_cpn_nbr = b.fc_cpn_nbr and b.fare_match_ind='Y' and ( (b.map_amt_pct between 0.986 and 1.014) or b.fc_amt=0)# or b.map_amt_pct is null)
 set a.fare_match_ind='Y';
 
 drop table if exists zz_ws_law.temp_fc_check;

create table if not exists zz_ws_law.temp_fc_check like ws_dw.sales_tkt_fc;

ALTER TABLE zz_ws_law.temp_fc_check 
ADD COLUMN fc_orig_cntry CHAR(3) NULL,
ADD COLUMN fc_dest_cntry CHAR(3) NULL,
ADD COLUMN cat27_35_err CHAR(3) NULL,
ADD COLUMN roe_err CHAR(1) NULL,
ADD COLUMN fc_inf0 CHAR(1) NULL,
ADD COLUMN fc_amt0 CHAR(1) NULL,
ADD COLUMN fc_err CHAR(1) NULL
;

insert ignore into zz_ws_law.temp_fc_check
select distinct fc.*, c.fc_orig_cntry, c.fc_dest_cntry, 'N' as cat27_35_err,'N' as roe_err, if(fc.tkt_pax_type like '%in%' and fc.fc_amt=0, 'Y', 'N' ), if(fc.fc_amt=0, 'Y', 'N'),'N' as fc_err  from ws_dw.sales_tkt_fc fc
  join zz_ws_law.temp_tbl_fc_all c on fc.doc_nbr_prime=c.doc_nbr_prime and fc.fc_cpn_nbr = c.fc_cpn_nbr
where 
fc.fare_match_ind='N'
and fc.trnsc_date between '2017-10-02' and '2017-10-31'
;

update  zz_ws_law.temp_fc_check fc join ws_dw.sales_tkt_fc_err er
on fc.doc_nbr_prime = er.doc_nbr_prime
set fc.fc_err='Y';

update  zz_ws_law.temp_fc_check fc join zz_ws_law.temp_tbl_fc_fare_map er
on fc.doc_nbr_prime = er.doc_nbr_prime and fc.fc_cpn_nbr = er.fc_cpn_nbr and er.map_amt_pct is null
set fc.roe_err='Y';


select * from zz_ws_law.temp_fc_check;

################################################################### build check indicators

select count(*) from zz_ws_law.temp_fc_check;
select * from zz_ws_law.temp_fc_check;

ALTER TABLE zz_ws_law.temp_fc_check 
ADD COLUMN fare_f_found CHAR(1) NULL AFTER fc_dest_cntry,
ADD COLUMN fare_f_mask_found CHAR(1) NULL AFTER fare_f_found,
ADD COLUMN fare_c_found CHAR(1) NULL AFTER fare_f_mask_found,
ADD COLUMN fare_r_found CHAR(1) NULL AFTER fare_c_found,
ADD COLUMN fare_c_mask_found CHAR(1) NULL AFTER fare_r_found,
ADD COLUMN fare_r_mask_found CHAR(1) NULL AFTER fare_c_mask_found,
ADD COLUMN fare_r8_found CHAR(1) NULL AFTER fare_r_mask_found,
ADD COLUMN fare_r8_mask_found CHAR(1) NULL AFTER fare_r8_found,
ADD COLUMN fare_r2_c_found CHAR(1) NULL AFTER fare_r8_mask_found,
ADD COLUMN price_ind CHAR(1) NULL DEFAULT '' AFTER fare_r2_c_found
;

ALTER TABLE zz_ws_law.temp_fc_check 
CHANGE COLUMN fare_f_found fare_f_found CHAR(1) NULL DEFAULT NULL COMMENT 'matched as a fare but not matched the fare amount' ,
CHANGE COLUMN fare_f_mask_found fare_f_mask_found CHAR(1) NULL DEFAULT NULL COMMENT 'matched as a fare with tkt code but not matched the fare amount' ,
CHANGE COLUMN fare_c_found fare_c_found CHAR(1) NULL DEFAULT NULL COMMENT 'matched as a constructed fare but not matched the fare amount' ,
CHANGE COLUMN fare_r_found fare_r_found CHAR(1) NULL DEFAULT NULL COMMENT 'matched as a fbr fare but not matched the fare amount' ,
CHANGE COLUMN fare_c_mask_found fare_c_mask_found CHAR(1) NULL DEFAULT NULL COMMENT 'matched as a construction fare with tkt coding masking but not matched the fare amount' ,
CHANGE COLUMN fare_r_mask_found fare_r_mask_found CHAR(1) NULL DEFAULT NULL COMMENT 'matched as a fbrfare with tkt coding masking but not matched the fare amount' ,
CHANGE COLUMN fare_r8_found fare_r8_found CHAR(1) NULL DEFAULT NULL COMMENT 'pass a possible matched in record 8 and cat35' ,
CHANGE COLUMN fare_r8_mask_found fare_r8_mask_found CHAR(1) NULL DEFAULT NULL COMMENT 'pass a possible matched in record 8 and cat35 and fare class masked' ,
CHANGE COLUMN fare_r2_c_found fare_r2_c_found CHAR(1) NULL DEFAULT NULL COMMENT 'can be constructed but not really find the combination' ,
CHANGE COLUMN price_ind price_ind CHAR(1) NULL DEFAULT NULL COMMENT 'auto-priced indicator, a means it is auto-priced' ;

update zz_ws_law.temp_fc_check a
join zz_ws_law.temp_tbl_fc_fare_map b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr and b.map_code='F'
set fare_f_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.temp_tbl_fc_fare_map b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr and b.map_code='T'
set fare_f_mask_found='f';

update zz_ws_law.temp_fc_check fc
set price_ind='';

#auto_price indicator
update zz_ws_law.temp_fc_check fc
join ws_dw.sales_trnsc t on t.trnsc_nbr=fc.doc_nbr_prime and fc.trnsc_date=t.trnsc_date and (t.fcmi = '0' or t.fcpi='0') and fc.carr_cd=t.carr_cd 
set price_ind='a';

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r2 b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r2_m b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r_mask_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r2_m2 b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r_mask_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r8 b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r8_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r8_m b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r8_mask_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r8_m2 b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r8_mask_found='f';

/*
ALTER ignore TABLE zz_ws_law.temp_fcm_c1_10_13 
ADD INDEX idx_doc (doc_nbr_prime ASC, fc_cpn_nbr ASC);

ALTER ignore TABLE zz_ws_law.temp_fcm_c1_m_10_13 
ADD INDEX idx_doc (doc_nbr_prime ASC, fc_cpn_nbr ASC);

ALTER ignore TABLE zz_ws_law.tmp_r2_c 
ADD INDEX idx_doc (doc_nbr_prime ASC, fc_cpn_nbr ASC);

update zz_ws_law.temp_fc_check a
join zz_ws_law.tmp_r2_c b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_r2_c_found='f';


update zz_ws_law.temp_fc_check a
join zz_ws_law.temp_fcm_c1_10_13 b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_c_found='f';

update zz_ws_law.temp_fc_check a
join zz_ws_law.temp_fcm_c1_m_10_13 b
on a.doc_nbr_prime=b.doc_nbr_prime
and a.fc_cpn_nbr=b.fc_cpn_nbr
set fare_c_mask_found='f';

*/


############check program for ws_trial

select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.temp_fc_check where doc_nbr_prime in (8695859874, 9568662820, 9568344170, 8676490421); #should not be found
select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.map_tkt_fare where doc_nbr_prime in (8695859874, 9568662820, 9568344170, 8676490421); #should be found

select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.temp_fc_check) as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.map_tkt_fare) as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.temp_tbl_fc_fare_map) as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from  ws_dw.sales_tkt_fc) as a;

select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from ws_dw.sales_tkt_fc) as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.temp_tbl_fc_fare_map where fare_match_ind ='Y') as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.temp_tbl_fc_fare_map where fare_match_ind ='Y' and map_type='S') as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.temp_tbl_fc_fare_map where fare_match_ind ='Y' and map_type='R') as a;
select count(distinct doc_nbr_prime, fc_cpn_nbr) from zz_ws_law.temp_tbl_fc_fare_map_c27c35 ;

select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.map_tkt_fare  ) as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.map_tkt_fare where  map_type='S') as a;
select count(*) from (select distinct doc_nbr_prime, fc_cpn_nbr from zz_ws_law.map_tkt_fare where  map_type='R') as a;

select * from zz_ws_law.temp_tbl_fc_fare_map_c27c35 ;


select 'fare_f_found', count(*) from zz_ws_law.temp_fc_check where fare_f_found='f' and price_ind ='a'
union all
select 'fare_f_mask_found', count(*) from zz_ws_law.temp_fc_check where fare_f_mask_found='f' and price_ind ='a'
union all
select 'fare_c_found', count(*) from zz_ws_law.temp_fc_check where fare_c_found='f' and price_ind ='a'
union all
select 'fare_r_found', count(*) from zz_ws_law.temp_fc_check where fare_r_found='f' and price_ind ='a'
union all
select 'fare_c_mask_found', count(*) from zz_ws_law.temp_fc_check where fare_c_mask_found='f' and price_ind ='a'
union all
select 'fare_r_mask_found', count(*) from zz_ws_law.temp_fc_check where fare_r_mask_found='f' and price_ind ='a'
union all
select 'fare_r8_found', count(*) from zz_ws_law.temp_fc_check where fare_r8_found='f' and price_ind ='a'
union all
select 'fare_r8_mask_found', count(*) from zz_ws_law.temp_fc_check where fare_r8_mask_found='f' and price_ind ='a'
union all
select 'fare_r2_c_found', count(*) from zz_ws_law.temp_fc_check where fare_r2_c_found='f' and price_ind ='a'
union all
select 'total', count(*) from zz_ws_law.temp_fc_check where price_ind ='a';
