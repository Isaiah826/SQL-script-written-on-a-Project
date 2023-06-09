USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_confirmation_score_aggr_card_rmo]    Script Date: 2/28/2023 10:03:56 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_insert_confirmation_score_aggr_card_rmo] 
		--@act_open_start_date varchar(10),
		--@disburse_loan_start_date varchar(10),
		@eod_date varchar(10)
			as
/*rmo script*/
declare @act_open_start_date varchar(10),
		@disburse_loan_start_date varchar(10)
--		@eod_date varchar(10)

--set @pdate = '20220831'
set @act_open_start_date = '20170101'
set @disburse_loan_start_date ='20170101'
--set @eod_date = '20220831'

insert into confirmation_score_card_aggr(
	[staff_id], 
	[staff_name], 
	[score_card_id] ,
	[score_card_type],
	[casa_deposit],
	[tenured_deposit],
	[loan],
	[domicilliary],
	[fees_income],
	[lc],
	[bg],
	[alat],
	[account_reactivation],
	[total_acct],
	[debit_visa],
	[credit_visa],
	[agent_onboarding],
	[contribution],
	[structure_date])
	


select
staff_id,
staff_name,
score_card_id,
score_card_type,
CASA+[DOMICILIARY BALANCE] AS CASA,	
[TERM DEPOSIT] as Tenured,
case when disbursed_loan > 0 then disbursed_loan
else  loans end as loan,
[DOMICILIARY BALANCE],
FEES,
lc,
bg,
alat,
account_reactivation,
isnull((total_acct_opening),0) as total_acct_opening,
debit_card,
credit_card,
agents_onboarding,
contribution,
structure_date
--[TERM DEPOSIT]+[DOMICILIARY BALANCE] as full_deposit 
--ac.eod_date,
--disbursed_loans.eod_date



from

(select sn.staff_id,sn.score_card_id, sn.staff_name,  sn.score_card_type,
 CASA,[TERM DEPOSIT], loans,[DOMICILIARY BALANCE],
FEES,alat,account_reactivation,account_open, lc, bg, debit_card,
credit_card, agents_onboarding,contribution, structure_date
from

(select x.staff_id, x.staff_name, y.score_card_id, 
y.score_card_type,x.structure_date
from (select substring (staff_id,2,5) as staff_id, 
staff_name, sbu_id, structure_date  
from account_officers 
where  substring (staff_id, 1,1) not in ('W','T')
--and structure_date = '20220831'
and eomonth(structure_date) =  eomonth(@eod_date)
and year(structure_date) = year(@eod_date)
union
(select staff_id, staff_name,
sbu_id, structure_date  
from account_officers 
where  substring (staff_id, 1,1) in ('W','T')
--and structure_date ='20220831'
and eomonth(structure_date) =  eomonth(@eod_date)
and year(structure_date) = year(@eod_date) )) x
join score_card_types y
on x. sbu_id = y.score_card_id
--where x.structure_date ='20220831'
where  eomonth(x.structure_date) =  eomonth(@eod_date)
and year(x.structure_date) = year(@eod_date)
and y.score_card_id in ('S001','S002', 'S004') )sn
--and x.staff_id in ('09495','09702','09515','09697','09704','09529','09669'))sn
--and x.staff_id in ('09515'))sn    

left join(
select staff_id,
isnull([CASA],0) as CASA,
isnull([TERM DEPOSIT],0) as 'TERM DEPOSIT',
isnull( [LOANS]*-1,0) as loans,
isnull([DOMICILIARY BALANCE],0) as 'DOMICILIARY BALANCE',
isnull([FEES],0) as FEES,
isnull([alat],0) as alat,
isnull([account_reactivation],0) as 'account_reactivation' ,
isnull([account_open],0) as 'account_open',
isnull([lc], 0) as lc ,
isnull([bg],0) as bg,
isnull([debit_visa],0) as debit_card,
isnull([credit_visa],0) as credit_card,
isnull([agents_onboarding],0) as agents_onboarding,
isnull([contribution],0) as contribution,
eod_date
from(


select staff_id, score_card_class, average_amt,structure_date as eod_date 
from																		/*modified+ account_officers*/
(select x.staff_id, x.staff_name, y.score_card_id, 
y.score_card_type,x.structure_date
from (select substring (staff_id,2,5) as staff_id, 
staff_name, sbu_id, structure_date  
from account_officers 
where  substring (staff_id, 1,1) not in ('W','T')
--and structure_date ='20220831'
and eomonth(structure_date) =  eomonth(@eod_date)
and year(structure_date) = year(@eod_date)
union
(select staff_id, staff_name,
sbu_id, structure_date  
from account_officers 
where  substring (staff_id, 1,1) in ('W','T')
--and structure_date ='20220831'
and eomonth(structure_date) =  eomonth(@eod_date)
and year(structure_date) = year(@eod_date)
)) x
join score_card_types y
on x. sbu_id = y.score_card_id
--where x.structure_date ='20220831'
where eomonth(structure_date) =  eomonth(@eod_date)
and year(structure_date) = year(@eod_date)
and y.score_card_id in ('S001','S002','S004')) staff
left join(

select free_code_4, score_card_class,foracid, average_amt, eod_date
from
(select bal.FREE_CODE_4, score_card_class, bal.foracid, average_amt, 
bal.eod_date
from
(select  c.FREE_CODE_4, a.score_card_class,
a.average_amt, a.total_amt, a.foracid,
a.eod_date 
from -- starting line
(select  x.foracid, mp.score_card_class,
sum(x.avg_vol) as average_amt, sum(naira_value) as total_amt, 
x.eod_date
from mpr_balance_sheet_base x --T2454 casa 373.54
left join 
(select distinct name, position,class,score_card_class from mpr_map) mp
on x.position = mp.position
where x.eod_date =@eod_date    
and mp.score_card_class in ('CASA','TERM DEPOSIT','DOMICILIARY BALANCE','LOANS')
group by  mp.score_card_class , x.eod_date, x.foracid) a
join 
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE =@eod_date 	)bal /* pls remove free_code4*/ --ending line -- and c.free_code_4 = '09669'

left join
(select distinct foracid, free_code_4 ,  /*modified date*/
acct_name, eod_date from account_modified_base) ac
on bal.foracid = ac.foracid
--and  bal.FREE_CODE_4 =ac.FREE_CODE_4
where ac.FORACID is null)md		)xyz
on staff.staff_id = xyz.FREE_CODE_4														/*modified+ account_officers*/


union all

/*commission and fees*/
(select  c.free_code_4, a.score_card_class,a.fee_income, a.eod_date  from
(select foracid, 'FEES'as score_card_class,  
sum(charge_amount) as fee_income, eod_date 
from comm_fees_base --comm_fees_base_202208
group by acct_mgr_user_id, foracid, eod_date) a
join 
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE =@eod_date) --@eod_date

union all
/*bonds and gurantee*/
(select free_code_4, 'bg'as score_card_class, 
sum(average_value) as bg_amt, eod_date from bg_base
group by free_code_4, foracid, eod_date)

union all
/*lc*/
(select free_code_4, 'lc'as score_card_class, 
sum(average_value) as lc_amt, eod_date from lc_base
group by free_code_4, foracid, eod_date)

union all
/*contribution*/
(select free_code_4, 'contribution'as score_card_class, 
sum(average_value) as continution_amt, eod_date from contribution_base
group by free_code_4, foracid, eod_date)


union all
/*credit visa*/
(select c.free_code_4, a.score_card_class, a.credit, a.eod_date from 
(select foracid,'credit_visa'as score_card_class, 
count(card_type) as credit, eod_date
from cards_base 
where card_type = 'CREDIT' --and eod_date ='20220831'
group by foracid, eod_date) a
join
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE = @eod_date) --@eod_date

union all
/*debit visa*/
(select c.free_code_4, a.score_card_class,a.debit, a.eod_date from 
(select foracid,'debit_visa'as score_card_class, 
count(card_type) as debit, eod_date
from cards_base 
where card_type = 'DEBIT' --and eod_date ='20220831'
group by foracid, eod_date) a
join
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE = @eod_date) -- no data 


union all
/*ntb_alat*/
(select c.free_code_4, a.score_card_class, a.alat, a.eod_date from 
(select  foracid, 'alat'as score_card_class,
 count(*) as alat, eod_date  from ntb_alat_base  ---ntb_alat, what are we counting
GROUP BY foracid, eod_date ) a
join 
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE =@eod_date)

union all

/*agent_onboarding*/
(select c.free_code_4, a.score_card_class,a.total_agent_onboarding, a.eod_date from 
(select  foracid, 'agent_onboarding'as score_card_class,
 count(*) as total_agent_onboarding, eod_date
 from agent_onboarding_base_202208  ---agent_onboarding, what are we counting
GROUP BY foracid,  eod_date) a
join 
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE =@eod_date) 


union all
/*accounts_reactivation*/ 
(select c.free_code_4, a.score_card_class, a.total_accounts_reactivation, a.eod_date from 
(select  foracid, 'accounts_reactivation'as score_card_class,
count(*) as total_accounts_reactivation, eod_date
from accounts_reactivated_monthly_base ---accounts_reactivation,, what are we counting- ACCT_OPN_DATE
GROUP BY foracid,  eod_date) a
join 
scrub.dbo.scrub_gam_raw b
on a.FORACID = b.FORACID
join 
scrub.dbo.scrub_gac_raw c
on b.ACID = c.ACID
where EOD_DATE =@eod_date)


)as sourcetable	
pivot
(sum(average_amt) for score_card_class  in ([CASA],[TERM DEPOSIT],
[LOANS],[DOMICILIARY BALANCE], [FEES],[alat], [account_reactivation],
[account_open],[lc], [bg],[debit_visa],[credit_visa], [agents_onboarding],
[contribution]
)
)as pivotable) kpi
on sn.staff_id = kpi.staff_id) card



left join
/* starting date will be a parameter for account opening i.e start_date_loans*/
/* this is the disbursed loan figure*/
(select free_code_4, disbursed_loan, 
eod_date from
(select free_code_4, isnull(sum(dis_amt),0) as disbursed_loan, eod_date 
from
(select free_code_4, foracid, dis_amt, 
DIS_SHDL_DATE,@eod_date as eod_date from loans_disbursed_base
where DIS_SHDL_DATE between @disburse_loan_start_date and @eod_date) term_loan
--where free_code_4 in ('09495','09702','09515', '09697','09704','09529','09669')
group by eod_date,free_code_4) k) disbursed_loans
on card.staff_id = disbursed_loans.free_code_4

left join
/*total numbers of account opened*/
/* starting date will be a parameter for account opening i.e start_date acct*/
(select free_code_4,sum(acct_open)as total_acct_opening, eod_date from
(select free_code_4, count(foracid) as acct_open, 
'account_opening' as score_card_class, @eod_date as eod_date 
from account_status_base
where acct_opn_date between @act_open_start_date and  @eod_date  ---free_code_4 = '09669'and
group by foracid, free_code_4) act_nos
group by eod_date, free_code_4) ac
on card.staff_id = ac.free_code_4


