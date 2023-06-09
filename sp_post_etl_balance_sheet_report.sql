USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_balance_sheet_report]    Script Date: 2/28/2023 9:12:24 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_post_etl_balance_sheet_report]
@v_date date

as
 
 
 declare  @pMonth nvarchar(50)
 declare @pYear nvarchar(50)
declare @eod_date nvarchar(50)

set @pMonth = month(@v_date)
set @pYear = year(@v_date)
set @eod_date = @v_date


SET NOCOUNT ON;  
SET ARITHABORT OFF 
SET ANSI_WARNINGS OFF
 
 
delete from mpr_bal_sheet_report where month(eod_date) = @pMonth and YEAR(eod_date) = @pYear
 
insert into mpr_bal_sheet_report 
  
select	a.branch_code,a.branch_name,
		a.zone_code,a.zone_name,a.region_code,a.region_name,a.directorate_code,a.directorate_name,
		UPPER(a.name) as CAPTION, -sum(isnull(c.avg_vol,0))/1000 as month_1_avg,
		-sum(isnull(b.act_vol,0))/1000 as  month_2_act,
		-sum(isnull(b.avg_vol,0))/1000 as month_2_avg, 
		-(sum(isnull(b.avg_vol,0))-(sum(isnull(c.avg_vol,0))))/1000 MOM_variance, 
		sum(isnull(bg.month_budget,0)) as month_2_budget,
		(((sum(isnull(b.avg_vol/1000,0)))+sum(isnull(bg.month_budget,0)))) budget_variance,
		isnull(((100*sum(isnull(b.interest_income,0)))/-(sum(isnull(b.avg_vol,0))*(day(EOMONTH (@eod_date))))),0)/1000 yield_cof,
		17 pool_rate, 
		isnull(((100*sum(isnull(b.interest_income,0)))/-((sum(isnull(b.avg_vol,0)))*(day(EOMONTH (@eod_date)))) - (cast(17 as float)/cast(100 as float))),0)/1000 spread,
		sum(isnull(b.interest_income,0))/1000 interest_inc_exp,isnull(b.currency,c.currency) currency,'',@eod_date eod_date,a.position
		from 
		(
			select  v.branch_code, v.branch_name,v.directorate_code,v.directorate_name,v.region_code,v.region_name,
			v.zone_code,v.zone_name,m.name ,v.structure_date,m.position
			from vw_base_structure v
			--inner join account_officers a
			--on v.branch_code = a.branch_code
			--and v.structure_date = a.structure_date
			inner join (select distinct name,position,class from mpr_map) m
			on 1=1
			where v.structure_date between eomonth(DATEADD(month,-1,DATEFROMPARTS(@pYear, @pMonth, 1))) and  eomonth(DATEFROMPARTS(@pYear, @pMonth, 1))
			--and year(v.structure_date) = '''+@vMaxStructureYear+'''
			--and month(t.structure_date) = '''+@vMaxStructureMonth+'''
			--and year(t.structure_date) = '''+@vMaxStructureYear+'''
		) a		
		left join
		(
			select x.name,x.branch_code, sum(x.avg_vol) avg_vol, sum(x.naira_value) act_vol,
			sum(interest_inc_exp) interest_income,x.eod_date,x.currency,x.position
			from mpr_balance_sheet_aggr x
			where eomonth(x.eod_date) = eomonth(DATEFROMPARTS(@pYear, @pMonth, 1))
			and x.position between 101 and 200
			and x.name is not null
			group by x.name,x.branch_code,x.eod_date,x.position,x.currency
		) b
		on a.branch_code = b.branch_code and a.name = b.name and EOMONTH(a.structure_date) =EOMONTH(b.eod_date) 	
		left join
		(
			select x.name,x.branch_code, sum(x.avg_vol) avg_vol, sum(x.naira_value) act_vol,
			sum(interest_inc_exp) interest_income,x.eod_date,x.position,x.currency
			from mpr_balance_sheet_aggr x
			where eomonth(x.eod_date) = eomonth(DATEADD(month,-1,DATEFROMPARTS(@pYear, @pMonth, 1)))
			and x.position between 101 and 200
			and x.name is not null
			group by x.name,x.branch_code,x.eod_date,x.position,x.currency
		) c
		on  a.branch_code = c.branch_code and a.name = c.name and a.structure_date =EOMONTH(c.eod_date) and a.position = c.position --and b.currency = c.currency
		left join
		(select caption,month_budget as month_budget,branch_code,position,currency,structure_date from mpr_balance_sheet_budget where position between 101 and 200 and structure_date = EOMONTH(@eod_date)) bg
		on b.branch_code = bg.branch_code and EOMONTH(b.eod_date) = bg.structure_date and b.name = bg.caption and b.position = bg.position and b.currency = bg.currency --and c.currency = bg.currency
		
		where a.name is not null
		--and bg.position between 100 and 200
		group by a.branch_code,a.branch_name,a.zone_code,a.zone_name,a.region_code,a.region_name,a.directorate_code,
		a.directorate_name,a.name,b.currency,a.position,c.currency
		
		UNION
 
 select	a.branch_code,a.branch_name,
		a.zone_code,a.zone_name,a.region_code,a.region_name,a.directorate_code,a.directorate_name,
		UPPER(a.name) as CAPTION, 
		sum(isnull(c.avg_vol,0))/1000 as month_1_avg,
		sum(isnull(b.act_vol,0))/1000 as  month_2_act,
		sum(isnull(b.avg_vol,0))/1000 as month_2_avg, 
		sum(isnull(b.avg_vol,0))/1000-abs(sum(isnull(c.avg_vol,0)))/1000 MOM_variance, 
		sum(isnull(bg.month_budget,0)) as month_2_budget,
		(sum(isnull(b.avg_vol/1000,0))+sum(isnull(bg.month_budget,0))) budget_variance,
		isnull(((100*sum(isnull(b.interest_income,0)))/(abs(sum(isnull(b.avg_vol,0)))*(day(EOMONTH (@eod_date))))),0) yield_cof,
		17 pool_rate, 
		isnull(((100*sum(isnull(b.interest_income,0)))/(abs(sum(isnull(b.avg_vol,0)))*(day(EOMONTH (@eod_date)))) - (cast(17 as float)/cast(100 as float))),0) spread,
		sum(isnull(b.interest_income,0)) interest_inc_exp,isnull(b.currency,c.currency) currency,'',@eod_date eod_date,a.position
		from 
		(
			select  v.branch_code, v.branch_name,v.directorate_code,v.directorate_name,v.region_code,v.region_name,
			v.zone_code,v.zone_name,m.name ,v.structure_date,m.position
			from vw_base_structure v
			--inner join account_officers a
			--on v.branch_code = a.branch_code
			--and v.structure_date = a.structure_date
			inner join (select distinct name,position,class from mpr_map) m
			on 1=1
			where v.structure_date between eomonth(DATEADD(month,-1,DATEFROMPARTS(@pYear, @pMonth, 1))) and  eomonth(DATEFROMPARTS(@pYear, @pMonth, 1))
		) a
		
		left join
		(
			select x.name,x.branch_code, sum(x.avg_vol) avg_vol, sum(x.naira_value) act_vol,
			sum(interest_inc_exp) interest_income,x.eod_date,x.currency,x.position
			from mpr_balance_sheet_aggr x
			where eomonth(x.eod_date) = eomonth(DATEFROMPARTS(@pYear, @pMonth, 1))
			and x.position between 201 and 300
			and x.name is not null
			group by x.name,x.branch_code,x.eod_date,x.position,x.currency
		) b
		on  a.branch_code = b.branch_code and a.name = b.name and EOMONTH(a.structure_date) =EOMONTH(b.eod_date) 
		left join
		(
			select x.name,x.branch_code, sum(x.avg_vol) avg_vol, sum(x.naira_value) act_vol,
			sum(interest_inc_exp) interest_income,x.eod_date,x.position,x.currency
			from mpr_balance_sheet_aggr x
			where eomonth(x.eod_date) = eomonth(DATEADD(month,-1,DATEFROMPARTS(@pYear, @pMonth, 1)))
			and x.position between 201 and 300
			and x.name is not null
			group by x.name,x.branch_code,x.eod_date,x.position,x.currency
		) c
		on  a.branch_code = c.branch_code and a.name = c.name  and a.position = c.position and b.currency = c.currency 
		--and a.structure_date =EOMONTH(c.eod_date)
		left join
		(select caption,month_budget as month_budget,branch_code,position,currency,structure_date from mpr_balance_sheet_budget where position between 201 and 300 and structure_date = EOMONTH(@eod_date)) bg
		on b.branch_code = bg.branch_code and EOMONTH(b.eod_date) = bg.structure_date and b.name = bg.caption and b.position = bg.position and b.currency = bg.currency --and c.currency = bg.currency
		where a.name is not null
		--and a.position = 299
		group by a.branch_code,a.branch_name,a.zone_code,a.zone_name,a.region_code,a.region_name,a.directorate_code,
		a.directorate_name,a.name,b.currency,a.position,b.currency,c.currency

		order by a.branch_code,a.position;
	
		

		
--		update mpr_bal_sheet_report set month_1_avg =month_1_avg/1000,
--month_2_act =month_2_act
--month_2_avg