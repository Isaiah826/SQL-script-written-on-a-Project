USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_confirmation_scorecard_target]    Script Date: 2/28/2023 9:15:32 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_post_etl_confirmation_scorecard_target]
@v_date date
as

declare @prev_structure date
select @prev_structure = max(structure_date) from confirmation_score_card_target

if (@v_date > @prev_structure) --and @v_date = EOMON
begin
delete from confirmation_score_card_target where structure_date > @prev_structure

insert into confirmation_score_card_target
select distinct 
staff_id,
staff_name,
score_card_id,
incre_casa_target,
casa_target,
tenured_target,
dorm_target,
loan_target,
fees_income_target,
total_acct_target,
lc_target,
bg_target,
alat_target,
agent_onboarding_target,
acct_reactivation_target,
debit_visa_target,
credit_visa_target,
PBT_target,
contribution_target,
total_deposit_target,
EOMONTH(@v_date),
month(@v_date)
from confirmation_score_card_target
end