USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_confirmation_score_aggr_card_bdm]    Script Date: 2/28/2023 10:03:44 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_insert_confirmation_score_aggr_card_bdm]
	@eod_date varchar(10)
	--@closing_bal_date varchar(10)
	--set arithabort off
	--set ansi_nulls off
	--set ansi_warnings off
	 
			as
declare @closing_bal_date varchar(10)
--set @eod_date ='20220831'
set @closing_bal_date = '20211031'	

set arithabort off
set ansi_nulls off
set ansi_warnings off
insert into confirmation_score_card_aggr(
	[staff_id], 
	[staff_name], 
	[score_card_id] ,
	[score_card_type],
	[incre_casa],
	[casa_deposit],
	[tenured_deposit],
	[loan],
	[domicilliary],
	[fees_income],
	[total_acct],
	[PBT],
	[structure_date])


select staff_id,  staff_name, score_card_id, score_card_type,

incr_casa,
casa, 
[TERM DEPOSIT],
isnull(case when loans > actual_loan then loans else actual_loan end,0) as loans, 
--loans, actual_loan,
[DOMICILIARY BALANCE],
fees, 
account_open,
PBT,
structure_date as eod_date
from(
select  staff_id,  staff_name, score_card_id,
score_card_type, sum(CASA) as casa, 
sum(incr_casa) as incr_casa,
sum([TERM DEPOSIT]) as 'TERM DEPOSIT',
sum(loans) as loans,
sum([DOMICILIARY BALANCE]) as 'DOMICILIARY BALANCE',
sum( actual_loan) as actual_loan,
sum(PBT) AS PBT,
sum(fees) as fees,
sum(account_open) as account_open,
structure_date
from 
(select a.branch_code, a.staff_name, a.staff_id, b.score_card_type, 
b.score_card_id, a.structure_date  -- score card type
from account_officers a
inner join score_card_types b
on a. sbu_id = b.score_card_id
--where a.structure_date = '20220831'
where month(a.structure_date) = month(@eod_date)
and year(a.structure_date) = year(@eod_date)
and b.score_card_id  in ( 'S003')
and a.staff_id in ('S09297','S09409','S09282','S09323')) staff
left join(

select kpi.branch_code, CASA, [TERM DEPOSIT],
LOANS, actual_loan, [DOMICILIARY BALANCE], FEES, 
account_open,PBT,incr_casa, kpi.eod_date
from
(select branch_code, 
isnull([CASA],0) as CASA,
isnull([TERM DEPOSIT],0) as [TERM DEPOSIT],
isnull([LOANS]*-1,0) as LOANS,
isnull([DOMICILIARY BALANCE],0) as [DOMICILIARY BALANCE],
isnull([FEES],0)as FEES, 
isnull([account_open],0) as account_open ,
isnull([PBT],0) as PBT,
isnull([incr_casa],0) as incr_casa,
eod_date
from (select x.branch_code, mp.score_card_class ,sum(x.avg_vol) as total_amount, x.eod_date
from mpr_balance_sheet_base x
Inner join (select distinct name, position,class,score_card_class from mpr_map) mp
 on x.position = mp.position
where x.eod_date = @eod_date
and mp.score_card_class in ('CASA','TERM DEPOSIT','DOMICILIARY BALANCE','LOANS')
group by x.eod_date, x.branch_code, mp.score_card_class 


union ALL 		
(select branch_code, 'FEES'as score_card_class,  total_income as fee_income, 
eod_date from comm_fees_aggr )

union all
(select branch_code,'PBT'as score_card_class, sum(int_inc_expense) as int_inc_expense,
eod_date  from  mpr_inc_stmt_aggr  where name in ('PROFIT BEFORE TAX') 
and eod_date = @eod_date group by branch_code, eod_date)

union all
(select branch_code,'account_reactivation'as score_card_class, 
total_accounts as account_reactivation,
eod_date from accounts_reactivated_monthly_aggr )

union all
/*incremental casa section----------*/
(select a.branch_code,'incr_casa'as score_card_class, 
avg_amt_actual- avg_amt_closing as incr_casa_avg, 
a.eod_date from
(select x.branch_code, mp.score_card_class ,
sum(x.avg_vol) as avg_amt_actual, x.eod_date
from mpr_balance_sheet_base x
Inner join (select distinct name, position,class,score_card_class from mpr_map) mp
 on x.position = mp.position
where x.eod_date = @eod_date  --
and mp.score_card_class in ('CASA')
group by x.eod_date, x.branch_code, mp.score_card_class )a				/* this section is the actual for incr casa*/
left join
(select x.branch_code, mp.score_card_class ,sum(x.avg_vol) as avg_amt_closing, x.eod_date
from mpr_balance_sheet_base x
Inner join (select distinct name, position,class,score_card_class from mpr_map) mp
 on x.position = mp.position
where x.eod_date = @closing_bal_date									/*This section is base/closing balance*/
and mp.score_card_class in ('CASA')
group by x.eod_date, x.branch_code, mp.score_card_class )b
on a.branch_code = b.branch_code)


union all
(select branch_code,'account_open'as score_card_class,  total_accounts as account_open, 
eod_date from accounts_open_monthly_aggr)
)as sourcetable
     pivot (
sum(total_amount) for score_card_class  in ([CASA],[TERM DEPOSIT],[LOANS],[DOMICILIARY BALANCE],
  [FEES],[account_open],[PBT],[incr_casa])
 ) as pivotable )kpi
 
 left join

 (select x.branch_code, mp.score_card_class ,
 sum(x.naira_value)*-1 as actual_loan, x.eod_date
from mpr_balance_sheet_base x
Inner join (select distinct name, position,class,score_card_class from mpr_map) mp
 on x.position = mp.position
where x.eod_date = @eod_date
and mp.score_card_class in ('LOANS')
group by x.eod_date, x.branch_code, mp.score_card_class) m
on kpi.branch_code = m.branch_code)  card
on staff.branch_code = card.branch_code
group by structure_date,  staff_id, staff_name, 
score_card_id, score_card_type) scd

