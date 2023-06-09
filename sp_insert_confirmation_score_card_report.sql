USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_confirmation_score_card_report]    Script Date: 2/28/2023 10:04:20 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_insert_confirmation_score_card_report]
 @eod_date varchar(10)
 as
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF


--create proc insert_confirmation_score_card_report
 --as
--declare @eod_date varchar(10)
--set @eod_date = '20220831'

--begin tran
insert into confirmation_score_card_report
(staff_id, score_card_id, incre_casa,
incre_casa_target,incre_casa_wgt,casa_deposit, casa_target, casa_wgt,
tenured_deposit,tenured_target, tenured_wgt,
domicilliary,	dorm_target, dorm_wgt,
loan, loan_target,	loan_wgt,	
fees_income, fees_income_target,	fees_income_wgt,
bg, bg_target,	bg_wgt,
lc,	lc_target,	lc_wgt,	alat,	alat_target, alat_wgt,	
credit_visa, credit_visa_target,credit_visa_wgt,
debit_visa,	debit_visa_target,	debit_Visa_wgt,
total_acct,	total_acct_target,	Total_acct_wgt,	
agent_onboarding,	agent_onboarding_target, agent_onboarding_wgt,
total_deposit,total_deposit_target, total_deposit_wgt, -- total deposit will be computed
account_reactivation,account_reactivation_target,account_reactivation_wgt,
PBT, PBT_target, PBT_wgt,
contribution, contribution_target, contribution_wgt,
eod_date)

 select scd.staff_id, scw.score_card_id, 
 scd.incre_casa, incre_casa_target,incre_casa_wgt, 
 scd.casa_deposit, scd.casa_target, scw.casa_wgt,
 scd.tenured_deposit, scd.tenured_target, scw.tenured_wgt, 
 scd.domicilliary, scd.dorm_target,  isnull(scw.dorm_wgt, 0) as dorm_wgt,
 scd.loan, scd.loan_target,  scw.loan_wgt, 
 scd.fees_income, scd.fees_income_target, scw.fees_income_wgt, 
 scd.bg, scd.bg_target, scw.bg_wgt,  
 scd.lc, scd.lc_target, scw.lc_wgt,
 scd.alat, scd.alat_target, scw.alat_wgt,  
 scd.credit_visa, scd.credit_visa_target, scw.credit_visa_wgt, 
 scd.debit_visa, scd.debit_visa_target, scw.debit_Visa_wgt, 
 scd.total_acct, scd.total_acct_target, scw.Total_acct_wgt,
 scd.agent_onboarding, scd.agent_onboarding_target, scw.agent_onboarding_wgt,
 scd.total_deposit,
 scd.total_deposit_target,scw.total_deposit_wgt,
 scd.account_reactivation,  scd.acct_reactivation_target, scw.acct_reactivation_wgt,
 scd.PBT, scd.PBT_target, scw.PBT_wgt,
 scd.contribution, scd.contribution_target, scw.contribution_wgt,
 scd.structure_date
 from(
select ca.staff_id, ca.score_card_id, ca.score_card_type,
ca.incre_casa,ca.casa_deposit, incre_casa_target, ct.casa_target, 
ca.tenured_deposit, ct.tenured_target,
ca.domicilliary, ct.dorm_target,ca.loan, ct.loan_target, 
ca.fees_income, ct.fees_income_target, ca.bg, ct.bg_target,
ca.lc, ct.lc_target, ca.Alat, ct.alat_target, ca.credit_visa, 
ct.credit_visa_target, ca.debit_visa, ct.debit_visa_target,
ca.total_acct, ct.total_acct_target, ca.agent_onboarding, 
ct.agent_onboarding_target,
ca.total_deposit,
ct.total_deposit_target,   ca.PBT, ct.PBT_target, 
ca.account_reactivation, ct.acct_reactivation_target,
ca.contribution, ct.contribution_target,
ca.structure_date from confirmation_score_card_target ct
left join  confirmation_score_card_aggr ca
on ca.staff_id = ct.staff_id
and ca.score_card_id = ct.score_card_id
where ct.staff_id is not null
and month(ct.structure_date)= month(ca.structure_date)
and year(ct.structure_date) = year(ca.structure_date)
and ct.structure_date = @eod_date) as scd

left join(
select  cw.staff_id,sc.score_card_type, sc.score_card_id,  isnull(cw.casa_wgt, 0) as casa_wgt, 
isnull(incre_casa_wgt,0) as incre_casa_wgt,
isnull(cw.tenured_wgt, 0) as tenured_wgt,isnull(cw.dorm_wgt,0) as dorm_wgt, 
isnull(cw.loan_wgt,0) as loan_wgt, isnull(cw.fees_income_wgt, 0) as fees_income_wgt,
isnull(cw.bg_wgt,0) as bg_wgt, isnull(cw.Total_acct_wgt,0) as total_acct_wgt,
isnull(cw.lc_wgt,0) as lc_wgt,  isnull(cw.alat_wgt,0)  as alat_wgt, 
isnull(cw.agent_onboarding_wgt,0) as agent_onboarding_wgt ,
isnull(cw.acct_reactivation_wgt,0)	as acct_reactivation_wgt,
isnull(cw.debit_Visa_wgt,0) as debit_Visa_wgt,
isnull(cw.credit_visa_wgt,0) as credit_visa_wgt, PBT_wgt,
isnull(cw.total_deposit_wgt,0) as total_deposit_wgt,
isnull(cw.contribution_wgt,0) as contribution_wgt
from confirmation_score_card_type_weight  cw 
left join score_card_types sc
on cw.score_card_Id = sc.score_card_id ) as scw
on scw.score_card_Id = scd.score_card_id
and scw.staff_id = scd.staff_id
where scd.score_card_id in ('S001','S002','S004','S008','S003') --bdm section is not included
--and scd.staff_id in  ('09495','09702','09588', '09697','09704','09529','09669')
--and scw.staff_id = scd.staff_id
--go



