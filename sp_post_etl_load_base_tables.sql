USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_load_base_tables]    Script Date: 2/28/2023 9:17:40 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[sp_post_etl_load_base_tables]
    @p_date date
AS   

SET NOCOUNT ON; 
DECLARE @v_last_day_of_month date = EOMONTH(@p_date);
DECLARE @v_last_wrk_day date = dbo.fn_get_last_wrk_day(@p_date);
DECLARE @v_delete_date date;

if @p_date = @v_last_wrk_day
	set @v_delete_date = @v_last_day_of_month;
else 
	set @v_delete_date = @p_date;


/*-------------------------------------------------------------------
	insert into balances_base table
*/-------------------------------------------------------------------
delete
from balances_base
where eod_date = @v_delete_date;

insert into balances_base (
	foracid, acct_name, acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, 
	free_code_4, product_code, gl_sub_head_code,
	acct_opn_date, sol_id, rate, rate_dr, sol_desc, acct_crncy_code, naira_value, 
	average_deposit, average_deposit_dr, int_expense, int_income, eod_date
)
select 
	foracid, acct_name, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, 
	free_code_4, product_code, gl_sub_head_code,
	acct_opn_date, sol_id, rate, rate_dr, sol_desc, acct_crncy_code, naira_value, 
	average_deposit, average_deposit_dr, int_expense, int_income, eod_date
from balances_base_raw
where eod_date = @p_date;


/*-------------------------------------------------------------------
	insert into account_status_base table
*/-------------------------------------------------------------------
truncate table account_status_base;

insert into account_status_base (
	foracid, acct_name, schm_code, schm_desc, schm_sub_type, gl_sub_head_code, acct_opn_date, free_code_4, sol_id,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, acct_status, closure_flag, acct_status_date, period, year, eod_date
)
select foracid, acct_name, schm_code, schm_desc, schm_sub_type, gl_sub_head_code, acct_opn_date, free_code_4, sol_id,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_status, closure_flag, acct_status_date, period, year, eod_date
from account_status_base_raw
where eod_date = @p_date;


/*-------------------------------------------------------------------
	insert into accounts_open_monthly_base table
*/-------------------------------------------------------------------
delete
from accounts_open_monthly_base
where eod_date = @v_delete_date;

insert into accounts_open_monthly_base (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_open_monthly_base_raw b

where eod_date = @p_date
and SCHM_DESC not in ('PRE-NEGOTIATION ODA','POST-NEGOTIATION ODA')
and ACCT_OPN_DATE between DATEADD(DAY,1,EOMONTH(@p_date,-1)) and @p_date
;


/*-------------------------------------------------------------------
	insert into accounts_open_monthly_base_retail table
*/-------------------------------------------------------------------
delete
from accounts_open_monthly_base_retail
where eod_date = @v_delete_date;

insert into accounts_open_monthly_base_retail (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select a.foracid, a.ACCT_NAME, a.SCHM_DESC, a.SCHM_SUB_TYPE, a.ACCT_OPN_DATE, a.FREE_CODE_4, a.SOL_ID,
	a.acct_mgr_user_id, a.acct_mgr_user_id, a.acct_mgr_user_id, a.acct_mgr_user_id, a.ACCT_STATUS, a.EOD_DATE
from accounts_open_monthly_base_raw a inner join scrub.dbo.scrub_gam_raw b on a.FORACID=b.FORACID
left join products c on b.SCHM_CODE=c.ProductCode
inner join (select distinct schm_code from acct_open_schm_codes) d on b.SCHM_CODE=d.schm_code
where eod_date = @p_date;


/*-------------------------------------------------------------------
	insert into accounts_closed_monthly_base table
*/-------------------------------------------------------------------
delete
from accounts_closed_monthly_base
where eod_date = @v_delete_date;

insert into accounts_closed_monthly_base (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_closed_monthly_base_raw
where eod_date = @p_date
and SCHM_DESC not in ('PRE-NEGOTIATION ODA','POST-NEGOTIATION ODA');


/*-------------------------------------------------------------------
	insert into accounts_dormant_monthly_base table
*/-------------------------------------------------------------------
delete
from accounts_dormant_monthly_base
where eod_date = @v_delete_date;

insert into accounts_dormant_monthly_base (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_dormant_monthly_base_raw
where eod_date = @p_date
and SCHM_DESC not in ('PRE-NEGOTIATION ODA','POST-NEGOTIATION ODA');


/*-------------------------------------------------------------------
	insert into accounts_reactivated_monthly_base table
*/-------------------------------------------------------------------
delete
from accounts_reactivated_monthly_base
where eod_date = @v_delete_date;

insert into accounts_reactivated_monthly_base (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_reactivated_monthly_base_raw
where eod_date = @p_date
and SCHM_DESC not in ('PRE-NEGOTIATION ODA','POST-NEGOTIATION ODA');





/*-------------------------------------------------------------------
	insert into account_maintenance_base table
*/-------------------------------------------------------------------
--delete
--from account_maintenance_base
--where eod_date = @v_delete_date;

--insert into account_maintenance_base (
--	acid, FORACID, ACCT_NAME, SCHM_CODE, SCHM_DESC, SOL_ID, 
--	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
--	COT_PRODUCT, COT_RATE, COT_CHARGE_AMOUNT, COT_TRAN_DATE, COT_APPLIED_FLG,
--	EOD_DATE
--)
--select acid, FORACID, ACCT_NAME, SCHM_CODE, SCHM_DESC, SOL_ID, 
--	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id,
--	COT_PRODUCT, COT_RATE, COT_CHARGE_AMOUNT, COT_TRAN_DATE, COT_APPLIED_FLG,
--	EOD_DATE
--from account_maintenance_base_raw
--where eod_date = @p_date;

/*-------------------------------------------------------------------
	insert into account_maintenance_base table
*/-------------------------------------------------------------------
delete
from account_maintenance_base
where eod_date = @v_delete_date;

if @p_date = EOMONTH(@p_date)
begin
 
insert into account_maintenance_base (
	acid, FORACID, ACCT_NAME, SCHM_CODE, SCHM_DESC, SOL_ID, 
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
	COT_PRODUCT, COT_RATE, COT_CHARGE_AMOUNT, COT_TRAN_DATE, COT_APPLIED_FLG,
	EOD_DATE
)
select ACID,FORACID,ACCT_NAME,SCHM_CODE,SCHM_DESC,SOL_ID,ACCT_MGR_USER_ID, 
ACCT_MGR_USER_ID,ACCT_MGR_USER_ID,ACCT_MGR_USER_ID,
COT_PRODUCT,COT_RATE,COT_CHARGE_AMOUNT,COT_TRAN_DATE,COT_APPLIED_FLG,EOD_DATE
from acct_maint_monthly_base_raw
where eod_date = @p_date;

END
ELSE
BEGIN

insert into account_maintenance_base (
	acid, FORACID, ACCT_NAME, SCHM_CODE, SCHM_DESC, SOL_ID, 
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
	COT_PRODUCT, COT_RATE, COT_CHARGE_AMOUNT, COT_TRAN_DATE, COT_APPLIED_FLG,
	EOD_DATE
)

select a.ACID,a.FORACID,a.ACCT_NAME,b.SCHM_CODE,b.SCHM_TYPE,a.SOL_ID,b.ACCT_MGR_USER_ID,
b.ACCT_MGR_USER_ID,b.ACCT_MGR_USER_ID,b.ACCT_MGR_USER_ID,a.COT_PRODUCT,a.COT_RATE,a.COT_CHARGE_AMOUNT,
a.COT_TRAN_DATE,a.COT_APPLIED_FLG,a.EOD_DATE
from acct_maint_daily_base_raw a
inner join scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
where a.eod_date = @p_date;

END



/*-------------------------------------------------------------------
	insert into pos_base table
*/-------------------------------------------------------------------
truncate table pos_base;

insert into pos_base (
	terminal_id, foracid, acct_name, schm_code,
	acct_opn_date, sol_id, mtd_txn_count, mtd_txn_amount,
	pos_status, 
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
	period, year,
	date_deployed, eod_date
)
select a.terminal_id, c.foracid, c.acct_name, c.schm_code,
c.acct_opn_date, c.sol_id, isnull(d.transaction_count, 0), 
isnull(d.transaction_amount, 0),
a.pos_status, 
c.acct_mgr_user_id, c.acct_mgr_user_id, c.acct_mgr_user_id, c.acct_mgr_user_id,
month(@p_date) period, 
year(@p_date) year,
a.date_deployed, 
cast(@p_date as date) as eod_date
from scrub.dbo.scrub_pos a
join scrub.dbo.scrub_pos_terminal_accounts b on (a.terminal_id = b.terminal_id and a.account_number = isnull(right('000' + b.foracid, 10), a.account_number))
join scrub.dbo.scrub_gam_raw c on isnull(b.foracid, a.account_number) = c.foracid
left join scrub.dbo.scrub_pos_transactions d on a.terminal_id = d.terminal_id;


/*-------------------------------------------------------------------
	insert into cards_base table
*/-------------------------------------------------------------------
truncate table cards_base

insert into cards_base (
	masked_pan, card_type, card_manufacturer, foracid, acct_name, schm_code,
	schm_desc, acct_opn_date, sol_id, issue_date, expiry_date, activated_date,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
	period, year, eod_date
)
select z.MaskedPan masked_pan, z.card_type, z.card_maker card_manufacturer,
	b.foracid, b.acct_name,	b.schm_code, c.SCHM_DESC, cast(b.acct_opn_date as date) acct_opn_date,
	b.SOL_ID, z.CreationDate issue_date, z.ExpiryDate expiry_date,z.activated_date,
	b.acct_mgr_user_id, b.acct_mgr_user_id, b.acct_mgr_user_id, b.acct_mgr_user_id,
	z.period, z.year, z.eod_date
--into cards_base
from (
	select distinct
	a.MaskedPan, 
		a.AccountNo,
		case
			when upper(a.ProductName) like '%DEBIT%' then 'DEBIT'
			when upper(a.ProductName) like '%CREDIT%' then 'CREDIT'
			else 'DEBIT'
		end as card_type,
		case
			when upper(a.ProductName) like '%VISA%' then 'VISA'
			when upper(a.ProductName) like '%MASTERCARD%' then 'MASTERCARD'
			else 'VISA'
		end as card_maker,
		a.CreationDate,
		a.ExpiryDate,
		a.ActivationDate activated_date,
		a.period,
		a.year,
		a.eod_date
	from scrub.dbo.scrub_cards_ni a 
	where MaskedPan is not null
	and ActivationDate is not null
	and len(AccountNo) = 10
	and SequenceNo != (select MAX(SequenceNo) from scrub.dbo.scrub_cards_ni where AccountNo = scrub.dbo.scrub_cards_ni.AccountNo)
	union
	select distinct
		pan, account_id, card_type, card_manufacturer,
		cast(a.date_issued as date) issue,
		convert(date, '20' + a.expiry_date + '01', 112) expiry_date,
		convert(date,date_activated) activated_date,
		a.period,
		a.year,
		a.eod_date
	from scrub.dbo.scrub_cards_postcard a
	where len(account_id) = 10
	and expiry_date <> 'NIL'
) z
inner join scrub.dbo.scrub_gam_raw b on z.accountNo = b.foracid
inner join scrub.dbo.scrub_gsp_raw c on b.schm_code = c.schm_code


/*-------------------------------------------------------------------
	insert into new_loans_base_retail table
*/-------------------------------------------------------------------
delete
from new_loans_base_retail
--where eod_date = @v_delete_date;

insert into new_loans_base_retail (
	foracid,acct_name,schm_code,schm_desc,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
	acct_opn_date,acct_cls_date,
	dis_amt,sol_desc,sol_id,eod_date
)
select foracid,acct_name,schm_code,schm_desc,
acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id,
acct_opn_date,acct_cls_date,
dis_amt,sol_desc,sol_id,eod_date
from new_loans_raw
where eod_date = @p_date;




/*-------------------------------------------------------------------
	insert into ntb_alat_base table
*/-------------------------------------------------------------------
truncate table ntb_alat_base

insert into ntb_alat_base (
	foracid,acct_name,schm_code,sol_id,
	acct_opn_date,acct_mgr_user_id,acct_mgr_user_id_2,
	acct_mgr_user_id_3,acct_mgr_user_id_4,eod_date,
	spool_date
)
select acct_number,acct_name,schm_code,sol_id,acct_opn_date,acct_mgr_user_id,acct_mgr_user_id_2,acct_mgr_user_id_3,
acct_mgr_user_id_4,eod_date,CURRENT_TIMESTAMP
from ntb_alat_base_raw
where eod_date = @p_date;




---------------------------------
/*old job from ALA 4.0 db*/
---------------------------------
/*
truncate table ntb_alat_base

insert into ntb_alat_base (
	foracid,acct_name,schm_code,sol_id,
	acct_opn_date,acct_mgr_user_id,acct_mgr_user_id_2,
	acct_mgr_user_id_3,acct_mgr_user_id_4,eod_date,
	spool_date
)
select distinct b.foracid,AccountName,SchemeCode,BranchCode,
	convert(date,date_registered,110) acct_opn_date,convert(varchar,StaffId),convert(varchar,StaffId),
	convert(varchar,StaffId),convert(varchar,StaffId),@p_date 'eod_date',
getdate() spool_date from scrub.dbo.accounts_alat b
inner join scrub.dbo.scrub_gam_raw c
on b.foracid= c.foracid
where month(b.date_registered) = month(@p_date)
and year(b.date_registered) = year(@p_date)
--and c.ACCT_CLS_FLG = 'Y'
and (c.ACCT_CLS_DATE> @p_date
or c.ACCT_CLS_DATE is null)
--and SchemeCode in ('30005','60010','60012','60013','64002')
;
*/

/*
insert into ntb_alat_base (
	foracid,acct_name,cif_id,emp_id,schm_code,schm_desc,sol_id,sol_desc,channel,
	acct_opn_date,clr_bal_amt,acct_crncy_code,acct_mgr_user_id,acct_mgr_user_id_2,
	acct_mgr_user_id_3,acct_mgr_user_id_4,introducer_id,cust_sex,PhoneNo,Email,eod_date,
	spool_date
)
select acct_number,acct_name,cif_id,emp_id,schm_code,schm_desc,sol_id,sol_desc,channel,
acct_opn_date,clr_bal_amt,acct_crncy_code,acct_mgr_user_id,acct_mgr_user_id_2,
acct_mgr_user_id_3,acct_mgr_user_id_4,introducer_id,cust_sex,PhoneNo,Email,eod_date,
getdate() spool_date from ntb_alat_base_raw
where eod_date = @p_date;
*/

/*
insert into ntb_alat_base (
	foracid,acct_name,emp_id,schm_desc,sol_id,
	acct_opn_date,acct_mgr_user_id,acct_mgr_user_id_2,
	acct_mgr_user_id_3,acct_mgr_user_id_4,eod_date,
	spool_date
)
select a.foracid,a.acct_name,'' emp_id,schm_desc,sol_id,
	convert(date,date_registered,110) acct_opn_date,acct_mgr_user_id,acct_mgr_user_id_2,
	acct_mgr_user_id_3,acct_mgr_user_id_4,eod_date,
getdate() spool_date from account_status_base a inner join scrub.dbo.accounts_alat b
on a.foracid=b.foracid
where a.eod_date = @p_date
and month(b.date_registered) = month(@p_date)
and year(b.date_registered) = year(@p_date)
and a.schm_code in ('30005','60010','60012','60013','64002')
and a.closure_flag = 'closed'
;
*/
/*-------------------------------------------------------------------
	insert into agent_onboarding_base table
*/-------------------------------------------------------------------
truncate table agent_onboarding_base;

set ansi_warnings off
insert into agent_onboarding_base (
	agent_id, other_names, last_name, gender,
	date_of_birth, onboarding_date, foracid, sol_id, 
	phone_number, email, contact_address,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4,
	period, year, eod_date
)
select a.id, a.othernames, a.lastname, a.gender,
	a.dateofbirth, a.dateonboarded, b.foracid, b.sol_id, 
	a.phonenumber, a.emailaddress, a.contactaddress,
	b.acct_mgr_user_id, b.acct_mgr_user_id, b.acct_mgr_user_id, b.acct_mgr_user_id,
	period, year, eod_date
from scrub.dbo.scrub_agency_banking a
left join scrub.dbo.scrub_gam_raw b on a.AccountNumber = b.foracid
where b.foracid is not null
union
select a.id, a.othernames, a.lastname, a.gender,
	a.dateofbirth, a.dateonboarded, a.AccountNumber foracid, isnull(b.sol_id,'999') sol_id, 
	a.phonenumber, a.emailaddress, a.contactaddress,
	isnull(b.acct_mgr_user_id,'') acct_mgr_user_id, isnull(b.acct_mgr_user_id,'') acct_mgr_user_id,
	cast(isnull(a.StaffId,'U00048') as varchar(20)) acct_mgr_user_id,isnull(b.acct_mgr_user_id,'') acct_mgr_user_id, 
	period, year, eod_date
from scrub.dbo.scrub_agency_banking a
left join scrub.dbo.scrub_gam_raw b on a.AccountNumber = b.foracid
where b.foracid is null


-------------------------------------------------------------------
/*merge all account activity to one table*/
/*

delete
from accounts_ytd_base_retail
where eod_date = @v_delete_date;

insert into accounts_ytd_base_retail (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_closed_ytd_base_raw
where eod_date = @p_date

union


select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_closed_ytd_base_raw
where eod_date = @p_date

union

select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_dormant_ytd_base_raw
where eod_date = @p_date

union
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_reactivated_ytd_base_raw
where eod_date = @p_date;

*/

/*-------------------------------------------------------------------
	insert into head_office_expense_base table
*/-------------------------------------------------------------------
--delete
--from head_office_expense_base
--where eod_date <> eomonth(@v_delete_date);

--insert into head_office_expense_base  (
--	foracid, tran_date, gl_sub_head_code, tran_amt, sol_id, tran_particular, part_tran_type, rpt_code, eod_date, process_flag, spool_date
--)
--select 
--	foracid, tran_date, gl_sub_head_code, case when part_tran_type = 'D' then tran_amt else tran_amt * -1 end as tran_amt,
--	sol_id, tran_particular, part_tran_type, rpt_code, eod_date, 0, CURRENT_TIMESTAMP 
--from head_office_expense_base_raw
--where eod_date = @p_date
--and tran_particular not like '%YEAR END CLOSURE%'
;
/*
/*-------------------------------------------------------------------
	insert into branch_expense_base table
*/-------------------------------------------------------------------


delete
from branch_expense_base
where eod_date <> eomonth(@v_delete_date);

insert into branch_expense_base  (
	foracid, tran_date, gl_sub_head_code, tran_amt, sol_id, tran_particular, part_tran_type, eod_date,process_flag,spool_date
)

select 
foracid, tran_date, case when substring(foracid,4,11) = 'NGN75470002' then '72100' else gl_sub_head_code end as gl_sub_head_code,
case when part_tran_type = 'D' then isnull(tran_amt * b.var_currency_units,tran_amt) else isnull(tran_amt * b.var_currency_units,tran_amt) * -1 end as tran_amt,
	sol_id, tran_particular, part_tran_type, x.eod_date,0,CURRENT_TIMESTAMP
from branch_expense_base_raw x
LEFT JOIN exchange_rate_base b
ON substring (x.foracid,4,3) = trim(b.fxd_currency_code) 
and x.eod_date = b.eod_date
where x.eod_date = @p_date

union all

select 
	foracid, tran_date, case when substring(foracid,4,11) = 'NGN75470002' then '72100' else gl_sub_head_code end as gl_sub_head_code,case when part_tran_type = 'D' then tran_amt else tran_amt * -1 end as tran_amt,
	case when rpt_code = '3376' then 'LPS' else rpt_code end as sol_id , tran_particular, part_tran_type, eod_date,0,CURRENT_TIMESTAMP
from head_office_expense_base_raw
where eod_date =@p_date and rpt_code = '3376'
--and tran_particular not like '%YEAR END CLOSURE%'
;
*/

/*-------------------------------------------------------------------
	insert into exchange_rate_base table
*/-------------------------------------------------------------------
delete
from exchange_rate_base
where eod_date = @v_delete_date;

insert into exchange_rate_base (
	fxd_currency_code, var_currency_code, fxd_currency_units, var_currency_units, eod_date
)
select 
	FXD_CRNCY_CODE, VAR_CRNCY_CODE, FXD_CRNCY_UNITS, VAR_CRNCY_UNITS, EOD_DATE
from exchange_rate_raw
where EOD_DATE = @p_date;

/*-------------------------------------------------------------------
	insert into commission & fees table
*/-------------------------------------------------------------------
--delete
--from comm_fees_base
--where eod_date = @v_delete_date;


--if @p_date = EOMONTH(@p_date)
--begin
 

--insert into comm_fees_base(
--	foracid, acct_name, acct_opn_date, fee_charge_id, income_acct, gl_sub_head_code, 
--	sol_id, event_id, chrg_tran_date, tran_particular, charge_amount,part_tran_type, 
--	acct_mgr_user_id, eod_date,spool_date
--)
--select 
--	foracid, acct_name, acct_opn_date, fee_charge_id, income_acct,  gl_sub_head_code, 
--	sol_id, event_id, chrg_tran_date, tran_particular, 
--	isnull(charge_amount * b.var_currency_units,charge_amount) as charge_amount,part_tran_type, 
--	acct_mgr_user_id, a.eod_date,
--	current_timestamp spool_date
--from comm_fees_base_raw a
--LEFT JOIN exchange_rate_base b
--ON substring (a.income_acct,4,3) = trim(b.fxd_currency_code) 
----and a.chrg_tran_date = b.eod_date
--and a.eod_date = b.eod_date
--where a.eod_date = @p_date
--and a.gl_sub_head_code not in ('55100','54210')
--and a.tran_particular not like '%YEAR END%'

--UNION ALL

--select a.FORACID,a.ACCT_NAME,b.ACCT_OPN_DATE,'XXX','XXX','55100',a.SOL_ID,'XXX',a.COT_TRAN_DATE,'ACCOUNT MAINTENANCE CHARGE',
--COT_CHARGE_AMOUNT,'C',a.ACCT_MGR_USER_ID,EOD_DATE,CURRENT_TIMESTAMP
--from acct_maint_monthly_base_raw a 
--left join scrub.dbo.scrub_gam_raw b
--on a.FORACID = b.FORACID
--where eod_date = @p_date;
--END

--ELSE

--BEGIN

--insert into comm_fees_base(
--	foracid, acct_name, acct_opn_date, fee_charge_id, income_acct, gl_sub_head_code, 
--	sol_id, event_id, chrg_tran_date, tran_particular, charge_amount,part_tran_type, 
--	acct_mgr_user_id, eod_date,spool_date
--)
--select 
--	foracid, acct_name, acct_opn_date, fee_charge_id, income_acct,  gl_sub_head_code, 
--	sol_id, event_id, chrg_tran_date, tran_particular, 
--	isnull(charge_amount * b.var_currency_units,charge_amount) as charge_amount,part_tran_type, 
--	acct_mgr_user_id, a.eod_date,
--	current_timestamp spool_date
--from comm_fees_base_raw a
--LEFT JOIN exchange_rate_base b
--ON substring (a.income_acct,4,3) = trim(b.fxd_currency_code) 
----and a.chrg_tran_date = b.eod_date
--and a.eod_date = b.eod_date
--where a.eod_date = @p_date
--and a.gl_sub_head_code not in ('55100','54210')
--and a.tran_particular not like '%YEAR END%'

--UNION ALL

--select a.FORACID,a.ACCT_NAME,b.ACCT_OPN_DATE,'XXX','XXX','55100',a.SOL_ID,'XXX',a.COT_TRAN_DATE,
--'ACCOUNT MAINTENANCE CHARGE',a.COT_CHARGE_AMOUNT,'C',b.ACCT_MGR_USER_ID,a.EOD_DATE, CURRENT_TIMESTAMP
--from acct_maint_daily_base_raw a
--left join scrub.dbo.scrub_gam_raw b
--on a.FORACID = b.FORACID
--where a.eod_date = @p_date;

--END;


/*
delete
from comm_fees_base
where eod_date = @v_delete_date;

insert into comm_fees_base(
	foracid, acct_name, acct_opn_date, fee_charge_id, income_acct, gl_sub_head_code, 
	sol_id, event_id, chrg_tran_date, tran_particular, charge_amount,part_tran_type, 
	acct_mgr_user_id, eod_date,spool_date
)
select 
	foracid, acct_name, acct_opn_date, fee_charge_id, income_acct,  gl_sub_head_code, 
	sol_id, event_id, chrg_tran_date, tran_particular, 
	isnull(charge_amount * b.var_currency_units,charge_amount) as charge_amount,part_tran_type, 
	acct_mgr_user_id, a.eod_date,
	current_timestamp spool_date
from comm_fees_base_raw a
LEFT JOIN exchange_rate_base b
ON substring (a.income_acct,4,3) = trim(b.fxd_currency_code) 
--and a.chrg_tran_date = b.eod_date
and a.eod_date = b.eod_date
where a.eod_date = @p_date;
*/




/*-------------------------------------------------------------------
	insert into accounts_open_ytd_base_retail table
*/-------------------------------------------------------------------
/*
delete
from accounts_open_ytd_base_retail
where eod_date = @v_delete_date;

insert into accounts_open_ytd_base_retail (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select a.foracid, a.ACCT_NAME, a.SCHM_DESC, a.SCHM_SUB_TYPE, a.ACCT_OPN_DATE, a.FREE_CODE_4, a.SOL_ID,
	a.acct_mgr_user_id, a.acct_mgr_user_id, a.acct_mgr_user_id, a.acct_mgr_user_id, a.ACCT_STATUS, a.EOD_DATE
from accounts_open_ytd_base_raw a inner join scrub.dbo.scrub_gam_raw b on a.FORACID=b.FORACID
inner join products c on b.SCHM_CODE=c.ProductCode
inner join acct_open_schm_codes d on b.SCHM_CODE=d.schm_code
where a.eod_date = @p_date;
*/

DELETE FROM accounts_open_ytd_base_retail where month(EOD_DATE)= month(@p_date) and year(eod_date) =year(@p_date) and EOD_DATE<> EOMONTH(@p_date)

INSERT INTO accounts_open_ytd_base_retail(foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,spool_date)

SELECT distinct foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,CURRENT_TIMESTAMP FROM accounts_open_monthly_base_retail WHERE EOMONTH(acct_opn_date) = EOMONTH(@p_date) and EOD_DATE = @p_date


/*-------------------------------------------------------------------
	insert into accounts_closed_ytd_base_retail table
*/-------------------------------------------------------------------
/*
delete
from accounts_closed_ytd_base_retail
where eod_date = @v_delete_date;

insert into accounts_closed_ytd_base_retail (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_closed_ytd_base_raw
where eod_date = @p_date;
*/
DELETE FROM accounts_closed_ytd_base_retail where month(EOD_DATE)= month(@p_date) and year(eod_date) =year(@p_date) and EOD_DATE<> EOMONTH(@p_date)

INSERT INTO accounts_closed_ytd_base_retail(foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,spool_date)

SELECT distinct foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,CURRENT_TIMESTAMP FROM accounts_closed_monthly_base WHERE  EOD_DATE = @p_date;

/*-------------------------------------------------------------------
	insert into accounts_dormant_ytd_base_retail table
*/-------------------------------------------------------------------
/*
delete
from accounts_dormant_ytd_base_retail
where eod_date = @v_delete_date;

insert into accounts_dormant_ytd_base_retail (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_dormant_ytd_base_raw
where eod_date = @p_date;
*/
DELETE FROM accounts_dormant_ytd_base_retail where month(EOD_DATE)= month(@p_date) and year(eod_date) =year(@p_date) and EOD_DATE<> EOMONTH(@p_date)

INSERT INTO accounts_dormant_ytd_base_retail(foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,spool_date)

SELECT distinct foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,CURRENT_TIMESTAMP FROM accounts_dormant_monthly_base WHERE  EOD_DATE = @p_date;


/*-------------------------------------------------------------------
	insert into accounts_reactivated_ytd_base_retail table
*/-------------------------------------------------------------------
/*
delete
from accounts_reactivated_ytd_base_retail
where eod_date = @v_delete_date;

insert into accounts_reactivated_ytd_base_retail (
	foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id_2, acct_mgr_user_id_3, acct_mgr_user_id_4, ACCT_STATUS, EOD_DATE
)
select foracid, ACCT_NAME, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE, FREE_CODE_4, SOL_ID,
	acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, acct_mgr_user_id, ACCT_STATUS, EOD_DATE
from accounts_reactivated_ytd_base_raw
where eod_date = @p_date;
*/
DELETE FROM accounts_reactivated_ytd_base_retail where month(EOD_DATE)= month(@p_date) and year(eod_date) =year(@p_date) and EOD_DATE<> EOMONTH(@p_date)

INSERT INTO accounts_reactivated_ytd_base_retail(foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,spool_date)

SELECT distinct foracid,ACCT_NAME,SCHM_DESC,SCHM_SUB_TYPE,ACCT_OPN_DATE,FREE_CODE_4,SOL_ID,ACCT_MGR_USER_ID,
ACCT_STATUS,ACCT_STATUS_DATE,EOD_DATE,CURRENT_TIMESTAMP FROM accounts_reactivated_monthly_base WHERE  EOD_DATE = @p_date;

----------------------------------------
