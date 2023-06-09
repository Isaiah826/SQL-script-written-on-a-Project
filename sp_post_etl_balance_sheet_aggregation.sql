USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_balance_sheet_aggregation]    Script Date: 2/28/2023 9:12:00 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_post_etl_balance_sheet_aggregation] 
@v_date date

as

declare @eod_date date
declare @ndic float
declare @cash_reserve float
declare @pool_rate float
declare @liquid_assets float
declare @regulatory_inc float

set @eod_date = @v_date

select @ndic = ndic from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )
select @cash_reserve = cash_reserve from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )
select @pool_rate = pool_rate from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )
select @liquid_assets = liquid_assets from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )
select @regulatory_inc = regulatory_inc from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )



set nocount on

 delete from mpr_balance_sheet_aggr where eod_date = @eod_date

------insert cash reserve & liquidity------------------------------
delete from mpr_balance_sheet_base where name in ('LIQUIDITY POSITION','CASH RESERVE REQUIREMENT') and eod_date= @eod_date

insert into mpr_balance_sheet_base
select name,position,'XXX',name,currency,'TEMP LIQUIDITY' product_code,0 rate,0 rate_dr,account_officer,gl_sub_head_code,
branch_code,'' product_liab_class,'' product_asset_class,'' product_name,sum(naira_value),sum(avg_vol),sum(gross_pool),
sum(interest_inc_exp) int_income,sum(interest_inc_exp) int_expense,sum(NRFF),'ASSET',eod_date
from (

select 'LIQUIDITY POSITION' name,foracid,acct_name,branch_code,account_officer,gl_sub_head_code,currency,-sum(avg_vol)*@liquid_assets avg_vol,-sum(naira_value)*@liquid_assets naira_value,sum(gross_pool)*@liquid_assets gross_pool,
(sum(avg_vol)*@liquid_assets)*@pool_rate*(cast(day(eod_date) as float)/cast(dbo.fn_days_in_a_year(year(@eod_date)) as float))  as interest_inc_exp ,sum(NRFF)*@liquid_assets NRFF,110 position,eod_date 
from mpr_balance_sheet_base where eod_date= @eod_date and position between 200  and 248 and position <>227
and currency = 'NGN'
group by account_officer,gl_sub_head_code,branch_code,currency,eod_date,foracid,acct_name

 union
 select 'CASH RESERVE REQUIREMENT' name,foracid,acct_name,branch_code,account_officer,gl_sub_head_code,currency,-sum(avg_vol)*@cash_reserve avg_vol,-sum(naira_value)*@cash_reserve naira_value,sum(gross_pool)*@cash_reserve gross_pool,
(sum(avg_vol)*@cash_reserve)*@pool_rate*(cast(day(eod_date) as float)/cast(dbo.fn_days_in_a_year(year(@eod_date)) as float))  as interest_inc_exp ,sum(NRFF*@cash_reserve) NRFF,107 position,eod_date 
from mpr_balance_sheet_base where eod_date= @eod_date and position between 200  and 248 and position <>227
and currency = 'NGN'
group by account_officer,gl_sub_head_code,branch_code,currency,eod_date,foracid,acct_name) crrliq

group by name,position,currency,account_officer,gl_sub_head_code,
branch_code,eod_date

-----------------------


EXEC p_table_pool_aggr_sum_detail @eod_date = @eod_date
--,@debug = 3
 
insert into mpr_balance_sheet_aggr

select name,branch_code,account_officer,gl_sub_head_code,currency,sum(avg_vol) avg_vol,sum(naira_value) naira_value,case when sum(int_expense) = 0 then sum(int_income) else sum(int_expense) end as interest_inc_exp ,position,eod_date 
from mpr_balance_sheet_base where eod_date= @eod_date
group by name,account_officer,gl_sub_head_code,branch_code,currency,position,eod_date


union


select name,branch_code,account_officer,gl_sub_head_code,currency
,sum(avg_vol) avg_vol,sum(naira_value) naira_value,sum(interest_inc_exp)
,position,eod_date
from ##table_pool_aggr_sum_detail --where branch_code = 'ALL'
group by name,branch_code, account_officer,gl_sub_head_code,currency
,position,eod_date



--order by position

 
--SELECT *
--FROM ##table_pool_aggr_sum_detail 

/*
select name,branch_code,account_officer,gl_sub_head_code,currency,sum(avg_vol) avg_vol,sum(naira_value) naira_value,sum(interest_inc_exp) ,position,eod_date 
from fn_table_pool_aggr_sum_detail (@eod_date)--- where branch_code = '001'
group by name,account_officer,gl_sub_head_code,branch_code,currency,position,eod_date
*/



--order by 2,8

IF OBJECT_ID('tempdb..##table_pool_aggr_sum_detail') IS NOT NULL
BEGIN
	DROP TABLE ##table_pool_aggr_sum_detail
END;



/*
select name,branch_code--,account_officer,gl_sub_head_code,currency
,sum(avg_vol) avg_vol,sum(naira_value) naira_value,sum(interest_inc_exp)
,position,eod_date, branch_all
from ##table_pool_aggr_sum_detail where branch_code = 'ALL'
group by name,branch_code--, account_officer,gl_sub_head_code,currency
,position,eod_date, branch_all
order by position

select name,branch_code--,account_officer,gl_sub_head_code,currency
,sum(avg_vol) avg_vol,sum(naira_value) naira_value,sum(interest_inc_exp)
,position,eod_date
from ##table_pool_aggr_sum_detail where branch_code = '001'
group by name,branch_code--, account_officer,gl_sub_head_code,currency
,position,eod_date
order by position

select name,branch_code--,account_officer,gl_sub_head_code,currency
,sum(avg_vol) avg_vol,sum(naira_value) naira_value,sum(interest_inc_exp)
,position,eod_date
from ##table_pool_aggr_sum_detail where branch_code = '092'
group by name,branch_code--, account_officer,gl_sub_head_code,currency
,position,eod_date
order by position
*/

--select * from mpr_balance_sheet_aggr
--where branch_code = 'ALL'

