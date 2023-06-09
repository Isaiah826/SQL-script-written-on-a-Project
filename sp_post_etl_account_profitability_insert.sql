USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_account_profitability_insert]    Script Date: 2/28/2023 9:12:39 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_post_etl_account_profitability_insert]
@v_date date

as

declare @pool_rate float
declare @ndic float
declare @cash_reserve float
declare @liquid_assets float
declare @regulatory_inc float
declare @pool_borrowing float
declare @pool_contribution float
declare @year varchar(10)
declare @days_year float


set @year = year(@v_date)
 

-----determine MPR Variables (pool, regulatory etc)------------------
select @ndic = ndic from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

select @cash_reserve = cash_reserve from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

select @pool_rate = pool_rate from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

select @liquid_assets = liquid_assets from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

select @regulatory_inc = regulatory_inc from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

select @pool_borrowing = pool_borrowing from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

select @pool_contribution = pool_contribution from wa_mpr_variables where effective_date in (select max(effective_date) from wa_mpr_variables )

SELECT @days_year = DATEDIFF(DAY,DATEADD(YEAR,@year-1900,0),DATEADD(YEAR,@year-1900+1,0)) -----number of days in a year



 delete from account_profitability_base where eod_date = @v_date


insert into account_profitability_base

select  dep.foracid, dep.acct_name, dep.rate,dep.rate_dr,dep.acct_mgr_user_id 'account_officer',ao.branch_code, isnull(liab.name,'')  'product_liab_class',isnull(ass.name,'') 'product_asset_class',ProductName product_name,dep.naira_value,dep.average_deposit,
isnull(dep.average_deposit_dr,0) average_deposit_dr, isnull(dep.average_deposit,0) * @cash_reserve 'cash_reserve',
isnull(dep.average_deposit,0) * @liquid_assets 'liquid_assets',
isnull(dep.average_deposit,0) + isnull(dep.average_deposit_dr,0) - (dep.average_deposit * @cash_reserve)-(dep.average_deposit * @liquid_assets) gross_pool, -dep.int_income,dep.int_expense,
isnull(dep.average_deposit,0) * @pool_contribution * (cast(day(eomonth(@v_date)) as float)/cast(dbo.fn(@year) as float)) pool_income,--((day(eomonth(@v_date)))/@days_year)  
0 pool_expense,--isnull(-1*dep.average_deposit_dr,0) * 0.12 * (cast(day(eomonth(@v_date)) as float)/cast(dbo.fn(2021) as float)) 
((@ndic)*isnull(dep.average_deposit,0)/@days_year*day(eomonth(@v_date))) 'NDIC',
@regulatory_inc*(isnull(dep.average_deposit,0) * @liquid_assets)*(day(@v_date)/@days_year) regulatory_income,
isnull(-1*dep.int_income,0) - isnull(dep.int_expense,0) + 
(isnull(dep.average_deposit_dr,0) * @pool_borrowing * (cast(day(eomonth(@v_date)) as float)/cast(dbo.fn(@year) as float)))
-(isnull(dep.average_deposit,0) * @pool_contribution * (cast(day(eomonth(@v_date)) as float)/cast(dbo.fn(@year) as float)))-
((@ndic)*isnull(dep.average_deposit,0)/@days_year*day(eomonth(@v_date)))+(@regulatory_inc*(isnull(dep.average_deposit,0) * @liquid_assets)*(day(@v_date)/@days_year))'NRFF',
isnull(other_expense,0) other_expense, isnull(loan_loss_exp,0) 'Provisions',isnull(recovery,0) 'Recovery',isnull(fees.[ACCOUNT MAINTENANCE],0) 'account_maintenance' , isnull(fees.[FACILITY RELATED FEES],0) 'facility_related_fees',
isnull(fees.[FX INCOME],0) 'fx_income',isnull(fees.[OFF BALANCE SHEET FEES],0) 'off_balance_sheet_fees',isnull(fees.[E-BUSINESS INCOME],0) 'e_business_income',
isnull(fees.[OTHER COMMISSION],0) 'other_commission', 
isnull(fees.[OTHER INCOME],0) 'other_income', cast( isnull(-1*dep.int_income,0) - isnull(dep.int_expense,0) + 
(isnull(-1*dep.average_deposit_dr,0) * @pool_borrowing * (cast(day(@v_date) as float)/cast(dbo.fn(2021) as float)))
-(isnull(dep.average_deposit,0) * @pool_contribution * ((day(@v_date))/@days_year))-
((@ndic)*isnull(dep.average_deposit,0)/@days_year*day(@v_date))+(@regulatory_inc*(isnull(dep.average_deposit,0)
-
((@ndic)*isnull(dep.average_deposit,0.00)/@days_year*day(@v_date)) + (@regulatory_inc*(isnull(dep.average_deposit,0.00) * @liquid_assets)*(day(@v_date)/@days_year))) - 
isnull([other_expense],0.00)
-isnull(loan_loss_exp,0.00) + isnull([recovery],0.00) + isnull(fees.[ACCOUNT MAINTENANCE],0.00) + isnull(fees.[FACILITY RELATED FEES],0.00) + isnull(fees.[FX INCOME],0.00) + isnull(fees.[OFF BALANCE SHEET FEES],0.00) + isnull(fees.[OTHER COMMISSION],0.00) + 
isnull(fees.[OTHER INCOME],0.00)) as float) 'total_income',@v_date eod_date

from 
--------deposit datasets------------------------------------
(select foracid,acct_name,acct_mgr_user_id,product_code,gl_sub_head_code, rate,rate_dr, naira_value,average_deposit,average_deposit_dr,int_expense,int_income,eod_date from deposits_base where eod_date = @v_date
and naira_value >0 and average_deposit > 0) dep  
left join 
-----comm&fees for deposits---------------------------------
(
select foracid,
		isnull([ACCOUNT MAINTENANCE FEE],0) as 'ACCOUNT MAINTENANCE',isnull([FACILITY RELATED FEES],0) as 'FACILITY RELATED FEES',
		isnull([FX INCOME],0) 'FX INCOME',isnull([E-BUSINESS INCOME],0) 'E-BUSINESS INCOME',
		isnull([OFF BALANCE SHEET FEES],0) 'OFF BALANCE SHEET FEES',isnull([OTHER COMMISSION],0) 'OTHER COMMISSION',
		isnull([OTHER INCOME],0) 'OTHER INCOME',eod_date
		from (
select  foracid,acct_name,sum(charge_amount) charge_amount,mpr_caption,eod_date from comm_fees_base comm
left join 
------------captions--------------------------
			(select cs.name as mpr_caption,  g.sh
			from captions_main cm
			inner join captions_sub cs on cm.id = cs.main_id
			left join gl_map g on cs.id = g.SubCaption
			where cm.refnote ='INCOME' and main_id = 11) cap
----------------------------------------------
on comm.gl_sub_head_code=cap.SH
where comm.eod_date = @v_date
and month(comm.chrg_tran_date)=month(@v_date)
and year(comm.chrg_tran_date)=year(@v_date)
group by foracid,acct_name,mpr_caption,eod_date )
AS SourceTable PIVOT(sum(charge_amount) FOR [mpr_caption] in ([ACCOUNT MAINTENANCE FEE],[FACILITY RELATED FEES],[FX INCOME],[E-BUSINESS INCOME],
		[OFF BALANCE SHEET FEES],[OTHER COMMISSION],[OTHER INCOME]))  AS PivotTable) fees
		on dep.foracid = fees.foracid
		and dep.eod_date = fees.eod_date
left join 
------other expenses---------------
		(select foracid,sum(exp_amt) other_expense,eod_date from apr_other_expense group by foracid,eod_date) oex
		on dep.foracid=oex.foracid
		and dep.eod_date = oex.eod_date
		--and dep.eod_date = @v_date
----loan loss----------------------
left join (select foracid, sum(provision) loan_loss_exp,eod_date from loan_loss_base group by foracid, eod_date) prov
		on dep.foracid = prov.foracid
		and dep.eod_date = prov.eod_date
		--and dep.eod_date = @v_date
-----------recoveries-----------------
left join (select foracid, sum(recovery) 'recovery', eod_date from recoveries_base group by foracid, eod_date) rec
		on dep.foracid = rec.foracid
		and dep.eod_date = rec.eod_date
		--and dep.eod_date = @v_date
inner join products prod on dep.product_code=prod.ProductCode ------scheme types
left join
--------liability ledgers----------------------
(select cm.id,cs.id csid,g.SubCaption,g.MainCaption,g.RefNote,cm.refnote cmref,g.SH,cs.name
			from captions_main cm
			inner join captions_sub cs on cm.id = cs.main_id
			left join gl_map g on cs.id = g.SubCaption
			and g.MainCaption = 9 and g.RefNote = 'LIABILITY'
			where cm.refnote ='LIABILITY' and cs.main_id = 9) liab
			on dep.gl_sub_head_code = liab.SH
left join

---------asset ledgers------------------------
(select cm.id,cs.id csid,g.SubCaption,g.MainCaption,g.RefNote,cm.refnote cmref,g.SH,cs.name
			from captions_main cm
			inner join captions_sub cs on cm.id = cs.main_id
			left join gl_map g on cs.id = g.SubCaption
			and g.MainCaption = 14 and g.RefNote = 'ASSET'
			where cm.refnote ='ASSET' and cs.main_id = 14) ass
			on dep.gl_sub_head_code = ass.SH
left join 
-----valid account officers----------
account_officers ao on dep.acct_mgr_user_id=ao.staff_id
and month(dep.eod_date) = month(ao.structure_date)
and year(dep.eod_date) = year(ao.structure_date)


UNION

select  loan.foracid, loan.acct_name, loan.rate,loan.rate_dr,loan.acct_mgr_user_id 'Account Officer',ao.branch_code, '' 'product_liab_class','' 'product_asset_class',ProductName product_name,loan.naira_value,isnull(loan.average_deposit,0) average_deposit,loan.average_deposit_dr,
0 'cash_reserve',--- isnull(-1*loan.average_deposit,0) * @cash_reserve
0 'liquid_assets',---isnull(loan.average_deposit,0) * @liquid_assets
isnull(loan.average_deposit,0) - isnull(-1*loan.average_deposit_dr,0) - (isnull(loan.average_deposit,0) * @cash_reserve)-(isnull(loan.average_deposit,0) * @liquid_assets) gross_pool, -1*loan.int_income int_income,isnull(loan.int_expense,0) int_expense,
0 pool_income,--loan.average_deposit_dr*@pool_borrowing*(day(@v_date)/@days_year)
(-1*loan.average_deposit_dr) *@pool_borrowing*(cast(day(@v_date) as float)/cast(dbo.fn(2021) as float))  pool_expense, 
((@ndic)*isnull(loan.average_deposit,0)/@days_year*day(@v_date)) 'NDIC',
@regulatory_inc*(isnull(loan.average_deposit,0) * @liquid_assets)*(day(@v_date)/@days_year) regulatory_income,
isnull(-1*loan.int_income,0) - isnull(loan.int_expense,0) + 
(isnull(-1*loan.average_deposit_dr,0) * @pool_borrowing * (cast(day(@v_date) as float)/cast(dbo.fn(2021) as float)))
-(isnull(loan.average_deposit,0) * @pool_contribution * ((day(@v_date))/@days_year))-
((@ndic)*isnull(loan.average_deposit,0)/@days_year*day(@v_date))+(@regulatory_inc*(isnull(loan.average_deposit,0) * @liquid_assets)*(day(@v_date)/@days_year))'NRFF',
isnull(other_expense,0) other_expense, isnull(loan_loss_exp,0.00) 'Provisions',isnull(recovery,0) 'Recovery',isnull(fees.[ACCOUNT MAINTENANCE],0) 'ACCOUNT MAINTENANCE' , isnull(fees.[FACILITY RELATED FEES],0) 'FACILITY RELATED FEES',
isnull(fees.[FX INCOME],0) 'FX INCOME',isnull(fees.[OFF BALANCE SHEET FEES],0) 'OFF BALANCE SHEET FEES',isnull(fees.[E-BUSINESS INCOME],0) 'e_business_income',
isnull(fees.[OTHER COMMISSION],0) 'OTHER COMMISSION', 
isnull(fees.[OTHER INCOME],0) 'OTHER INCOME', cast( isnull(loan.int_income,0) - isnull(loan.int_expense,0) + 
(isnull(-1*loan.average_deposit_dr,0) * @pool_borrowing * (cast(day(@v_date) as float)/cast(dbo.fn(2021) as float)))
-(isnull(loan.average_deposit,0) * @pool_contribution * ((day(@v_date))/@days_year))-
((@ndic)*isnull(loan.average_deposit,0)/@days_year*day(@v_date))+(@regulatory_inc*(isnull(loan.average_deposit,0) * @liquid_assets)*(day(@v_date)/@days_year))
-
((@ndic)*isnull(loan.average_deposit,0.00)/@days_year*day(@v_date)) + (@regulatory_inc*(isnull(loan.average_deposit,0.00) * @liquid_assets)*(day(@v_date)/@days_year)) - 
isnull([other_expense],0.00)
-isnull(loan_loss_exp,0.00) + isnull([recovery],0.00) + isnull(fees.[ACCOUNT MAINTENANCE],0.00) + isnull(fees.[FACILITY RELATED FEES],0.00) + isnull(fees.[FX INCOME],0.00) + isnull(fees.[OFF BALANCE SHEET FEES],0.00) + isnull(fees.[OTHER COMMISSION],0.00) + 
isnull(fees.[OTHER INCOME],0.00) as float) 'TOTAL INCOME', @v_date eod_date
 
 from 
 --------loans datasets------------------------------------

 (select foracid,acct_name,acct_mgr_user_id,product_code,gl_sub_head_code, rate,rate_dr, naira_value,average_deposit,average_deposit_dr,int_expense,int_income,eod_date from loans_base where eod_date = @v_date) loan  
left join
-----comm&fees for loans---------------------------------
(
select foracid,
		isnull([ACCOUNT MAINTENANCE FEE],0) as 'ACCOUNT MAINTENANCE',isnull([FACILITY RELATED FEES],0) as 'FACILITY RELATED FEES',
		isnull([FX INCOME],0) 'FX INCOME',isnull([E-BUSINESS INCOME],0) 'E-BUSINESS INCOME',
		isnull([OFF BALANCE SHEET FEES],0) 'OFF BALANCE SHEET FEES',isnull([OTHER COMMISSION],0) 'OTHER COMMISSION',
		isnull([OTHER INCOME],0) 'OTHER INCOME',eod_date
		from (
select  foracid,acct_name,sum(charge_amount) charge_amount,mpr_caption,eod_date from comm_fees_base comm
left join 
------------captions--------------------------
			(select cs.name as mpr_caption,  g.sh
			from captions_main cm
			inner join captions_sub cs on cm.id = cs.main_id
			left join gl_map g on cs.id = g.SubCaption
			where cm.refnote ='INCOME' and main_id = 11) cap
on comm.gl_sub_head_code=cap.SH
where comm.eod_date = @v_date
and month(comm.chrg_tran_date)=month(@v_date)
and year(comm.chrg_tran_date)=year(@v_date)
group by foracid,acct_name,mpr_caption,eod_date )
AS SourceTable PIVOT(sum(charge_amount) FOR [mpr_caption] in ([ACCOUNT MAINTENANCE FEE],[FACILITY RELATED FEES],[FX INCOME],[E-BUSINESS INCOME],
		[OFF BALANCE SHEET FEES],[OTHER COMMISSION],[OTHER INCOME]))  AS PivotTable) fees
		on loan.foracid = fees.foracid
		and loan.eod_date = fees.eod_date
left join 
------other expenses loans---------------
		(select foracid,sum(exp_amt) other_expense,eod_date from apr_other_expense group by foracid,eod_date) oex
		on loan.foracid=oex.foracid
		and loan.eod_date = oex.eod_date
		and loan.eod_date = @v_date
-----loan loss loans ------
left join (select foracid, sum(provision) loan_loss_exp,eod_date from loan_loss_base group by foracid, eod_date) prov
		on loan.foracid = prov.foracid
		and loan.eod_date = prov.eod_date
		and loan.eod_date = @v_date
-----recoveries loans ------
left join (select foracid, sum(recovery) 'recovery', eod_date from recoveries_base group by foracid, eod_date) rec
		on loan.foracid = rec.foracid
		and loan.eod_date = rec.eod_date
		and loan.eod_date = @v_date
inner join products prod on loan.product_code=prod.ProductCode 

left join
---------liability ledgers------------------------
(select cm.id,cs.id csid,g.SubCaption,g.MainCaption,g.RefNote,cm.refnote cmref,g.SH,cs.name
			from captions_main cm
			inner join captions_sub cs on cm.id = cs.main_id
			left join gl_map g on cs.id = g.SubCaption
			and g.MainCaption = 9 and g.RefNote = 'LIABILITY'
			where cm.refnote ='LIABILITY' and cs.main_id = 9) liab
			on loan.gl_sub_head_code = liab.SH
left join
---------asset ledgers------------------------

(select cm.id,cs.id csid,g.SubCaption,g.MainCaption,g.RefNote,cm.refnote cmref,g.SH,cs.name
			from captions_main cm
			inner join captions_sub cs on cm.id = cs.main_id
			left join gl_map g on cs.id = g.SubCaption
			and g.MainCaption = 14 and g.RefNote = 'ASSET'
			where cm.refnote ='ASSET' and cs.main_id = 14) ass
			on loan.gl_sub_head_code = ass.SH		
left join 
-----valid account officers----------
account_officers ao on loan.acct_mgr_user_id=ao.staff_id
and month(loan.eod_date) = month(ao.structure_date)
and year(loan.eod_date) = year(ao.structure_date)


	

		--select * from loans_base_202204 d join products p on d.product_code=p.ProductCode
		--where p.ProductName product_name = 'EXPRESS CREDIT' and eod_date = '20211112'