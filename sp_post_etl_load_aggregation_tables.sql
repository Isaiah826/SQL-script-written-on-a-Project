USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_load_aggregation_tables]    Script Date: 2/28/2023 9:17:28 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[sp_post_etl_load_aggregation_tables]
    @v_date date
AS   

SET NOCOUNT ON;  

delete
from deposits_aggr
where eod_date = @v_date;

INSERT into deposits_aggr (
	staff_id, staff_name, branch_code,
	actual_balance, average_balance, int_expense, eod_date
)
SELECT a.staff_id, a.staff_name, a.branch_code, 
sum(a.naira_value) actual_balance, 
sum(a.average_deposit) average_balance,
sum(a.int_expense) as int_expense,
a.eod_date 
from 
(
	select y.staff_id, y.staff_name, y.branch_code,
	naira_value, average_deposit, x.int_expense, x.eod_date--, v.structure_date
	FROM deposits_base x 
	inner join account_officers y 
	on x.acct_mgr_user_id = y.staff_id
	where month(x.eod_date) = month(y.structure_date) 
	and year(x.eod_date) = year(y.structure_date)
	and x.eod_date = @v_date
) a
group by a.staff_id, a.staff_name, a.branch_code, a.eod_date 
order by a.branch_code, a.staff_name;

-- insert into deposits_aggr_retail

delete
from deposits_aggr_retail
where eod_date = @v_date;

INSERT into deposits_aggr_retail (
	staff_id, staff_name, branch_code,
	actual_balance, average_balance, int_expense, eod_date
)
SELECT a.staff_id, a.staff_name, a.branch_code, 
sum(a.naira_value) actual_balance, 
sum(a.average_deposit) average_balance,
sum(a.int_expense) as int_expense,
a.eod_date 
from 
(
	select y.staff_id,y.staff_name,
	--case when y.sbu_code = 'S002' then [dbo].[fn_get_unmapped_officer_by_branch_code](y.branch_code,@v_date)
	--else y.staff_id end as staff_id,
	--case when y.sbu_code = 'S002' then 'UNMAPPED' else y.staff_name end as staff_name,
	y.branch_code,
	naira_value, average_deposit, x.int_expense, x.eod_date--, v.structure_date
	FROM deposits_base_retail x 
	inner join account_officers y 
	on x.acct_mgr_user_id = y.staff_id
	inner join retail_gl_sub_heads_deposits z
	on x.gl_sub_head_code=z.gl_sub_head
	left join accounts_exempted_retail_deposits_by_cluster a
	on x.foracid = a.account_number
	left join retail_deposits_backout f
	on x.foracid=f.foracid
	where month(x.eod_date) = month(y.structure_date)
	and a.account_number is null
	and f.foracid is null
	and year(x.eod_date) = year(y.structure_date)
	and x.eod_date = @v_date
) a
group by a.staff_id, a.staff_name, a.branch_code, a.eod_date 
order by a.branch_code, a.staff_name;

-----------------------------------------------------
delete
from loans_aggr
where eod_date = @v_date;


-- insert into loans_aggr
INSERT into loans_aggr (
	staff_id, staff_name, branch_code,
	actual_balance, average_balance, int_income, eod_date
)
SELECT a.staff_id, a.staff_name, a.branch_code, 
sum(a.naira_value) actual_balance, 
sum(a.average_deposit_dr) average_balance,
sum(a.int_income) as int_income,
a.eod_date 
from 
(
	select y.staff_id, y.staff_name, y.branch_code,
	x.product_code, x.gl_sub_head_code,
	naira_value, average_deposit_dr, x.int_income, x.eod_date--, v.structure_date
	FROM loans_base x 
	inner join account_officers y 
	on x.acct_mgr_user_id = y.staff_id
	where month(x.eod_date) = month(y.structure_date) 
	and year(x.eod_date) = year(y.structure_date)
	and x.eod_date = @v_date
) a
group by a.staff_id, a.staff_name, a.branch_code, a.eod_date 
order by a.branch_code, a.staff_name;


-------Retail Loans Aggregation
delete
from loans_aggr_retail
where eod_date = @v_date;


-- insert into loans_aggr_retail
INSERT into loans_aggr_retail(
	staff_id, staff_name, branch_code,
	actual_balance, average_balance, int_income, eod_date
)
SELECT a.staff_id, a.staff_name, a.branch_code, 
sum(a.naira_value) actual_balance, 
sum(a.average_deposit_dr) average_balance,
sum(a.int_income) as int_income,
a.eod_date 
from 
(
	select y.staff_id, y.staff_name, y.branch_code,
	x.product_code, x.gl_sub_head_code,
	naira_value, average_deposit_dr, x.int_income, x.eod_date--, v.structure_date
	FROM loans_base_retail x 
	inner join account_officers y 
	on x.acct_mgr_user_id = y.staff_id
    inner join retail_gl_sub_heads_loans z
	on x.gl_sub_head_code=z.gl_sub_head
	left join retail_loans_backout f
	on x.foracid=f.foracid
	where month(x.eod_date) = month(y.structure_date) 
	and year(x.eod_date) = year(y.structure_date)
	and f.foracid is null
	and x.eod_date = @v_date
) a
group by a.staff_id, a.staff_name, a.branch_code, a.eod_date 
order by a.branch_code, a.staff_name;



-- account status
truncate table account_status_aggregation

insert into account_status_aggregation (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

-------top cards accounts aggregation---------



insert into top_cards_accounts_aggregation (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable
---------------------------------------------------------------------------------
-- account status retail
truncate table account_status_aggregation_retail

insert into account_status_aggregation_retail (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_3 = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	--inner join retail_gl_sub_heads_deposits z
	--on x.gl_sub_head_code=z.gl_sub_head
	--left join retail_deposits_backout f
	--on x.foracid=f.foracid
	--where f.foracid is null
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable
-------------------------------------------------------------------
/*
truncate table account_status_aggregation_non_alat_for_business_products

insert into account_status_aggregation_non_alat_for_business_products (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.schm_code not in (select schm_code from products_alat_for_business)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable
*/

truncate table account_status_aggregation_alat_products

insert into account_status_aggregation_alat_products (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.schm_code in (select schm_code from products_alat)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

truncate table account_status_aggregation_alat_for_business_products

insert into account_status_aggregation_alat_for_business_products (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.schm_code in (select schm_code from products_alat_for_business)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

truncate table account_status_aggregation_ussd_products

insert into account_status_aggregation_ussd_products (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.schm_code in (select schm_code from products_ussd)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

truncate table account_status_aggregation_digital_alat

insert into account_status_aggregation_digital_alat (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	where month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and schm_code in (select schm_code from products_alat)
	and x.foracid in (select foracid from scrub.dbo.accounts_alat)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

truncate table account_status_aggregation_digital_alat_for_business

insert into account_status_aggregation_digital_alat_for_business (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	where month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.schm_code in (select schm_code from products_alat_for_business)
	and x.foracid in (select foracid from scrub.dbo.accounts_alat_for_business)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

truncate table account_status_aggregation_digital_ussd

insert into account_status_aggregation_digital_ussd (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	where month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.schm_code in (select schm_code from products_ussd)
	and x.foracid in (select foracid from scrub.dbo.accounts_ussd)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

truncate table account_status_aggregation_digital_total

insert into account_status_aggregation_digital_total (
	staff_id, branch_code, active, inactive, dormant, closed, 
	total_open, period, year, eod_date
)
select 
	staff_id, branch_code, isnull(Active, 0) as Active, isnull(Inactive, 0) as Inactive, 
	isnull(Dormant, 0) as Dormant, isnull(Closed, 0) as Closed, 
	(isnull(Active, 0) + isnull(Inactive, 0) + isnull(Dormant, 0)) as total_open, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_status account_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from account_status_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	where month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.foracid in (
		select foracid from scrub.dbo.accounts_alat
		union
		select foracid from scrub.dbo.accounts_alat_for_business
		union
		select foracid from scrub.dbo.accounts_ussd
	)
	group by a.staff_id, a.branch_code, x.acct_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [account_status] IN ([Active],
                                                         [Inactive],
                                                         [Dormant],
                                                         [Closed])) AS PivotTable

delete
from accounts_open_monthly_aggr
where eod_date = @v_date;

-- insert into accounts_open_monthly_aggr
insert into accounts_open_monthly_aggr (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_open_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id = a.staff_id
where eod_date = @v_date
and ACCT_OPN_DATE between DATEADD(DAY,1,EOMONTH(@v_date,-1)) and @v_date
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

delete
from accounts_closed_monthly_aggr
where eod_date = @v_date;

-- insert into accounts_closed_monthly_aggr
insert into accounts_closed_monthly_aggr (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_closed_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id = a.staff_id
where eod_date = @v_date
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

delete
from accounts_dormant_monthly_aggr
where eod_date = @v_date;

-- insert into accounts_dormant_monthly_aggr
insert into accounts_dormant_monthly_aggr (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_dormant_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id = a.staff_id
where eod_date = @v_date
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

delete
from accounts_reactivated_monthly_aggr
where eod_date = @v_date;

-- insert into accounts_reactivated_monthly_aggr
insert into accounts_reactivated_monthly_aggr (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_reactivated_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id = a.staff_id
where eod_date = @v_date
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

truncate table mtd_account_activity_aggregation

insert into mtd_account_activity_aggregation (
	staff_id, branch_code, opened, closed, dormant, reactivated, 
	period, year, eod_date
)
select 
	staff_id, branch_code, isnull(OPENED, 0) as OPENED, isnull(CLOSED, 0) as CLOSED, 
	isnull(DORMANT, 0) as DORMANT, isnull(REACTIVATED, 0) as REACTIVATED, 
	period, year, eod_date
from (
	select a.staff_id, a.branch_code, x.acct_activity_status, 
		count(*) total_accounts, x.period, x.year, x.eod_date
	from (
		select foracid, acct_name, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE,
		FREE_CODE_4, SOL_ID, ACCT_MGR_USER_ID, ACCT_STATUS, 'OPENED' as acct_activity_status,
		ACCT_STATUS_DATE, period, year, eod_date, spool_date, acct_mgr_user_id_2,
		acct_mgr_user_id_3, acct_mgr_user_id_4
		from accounts_open_monthly_base

		union

		select foracid, acct_name, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE,
		FREE_CODE_4, SOL_ID, ACCT_MGR_USER_ID, ACCT_STATUS, 'CLOSED' as acct_activity_status,
		ACCT_STATUS_DATE, period, year, eod_date, spool_date, acct_mgr_user_id_2,
		acct_mgr_user_id_3, acct_mgr_user_id_4
		from accounts_closed_monthly_base

		union

		select foracid, acct_name, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE,
		FREE_CODE_4, SOL_ID, ACCT_MGR_USER_ID, ACCT_STATUS, 'DORMANT' as acct_activity_status,
		ACCT_STATUS_DATE, period, year, eod_date, spool_date, acct_mgr_user_id_2,
		acct_mgr_user_id_3, acct_mgr_user_id_4
		from accounts_dormant_monthly_base

		union

		select foracid, acct_name, SCHM_DESC, SCHM_SUB_TYPE, ACCT_OPN_DATE,
		FREE_CODE_4, SOL_ID, ACCT_MGR_USER_ID, ACCT_STATUS, 'REACTIVATED' as acct_activity_status,
		ACCT_STATUS_DATE, period, year, eod_date, spool_date, acct_mgr_user_id_2,
		acct_mgr_user_id_3, acct_mgr_user_id_4
		from accounts_reactivated_monthly_base
	) x
	inner join account_officers a
	on x.acct_mgr_user_id = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.eod_date = @v_date
	group by a.staff_id, a.branch_code, x.acct_activity_status, 
		x.period, x.year, x.eod_date
) AS SourceTable PIVOT(sum(total_accounts) FOR [acct_activity_status] IN([OPENED],
                                                         [CLOSED],
                                                         [DORMANT],
                                                         [REACTIVATED])) AS PivotTable

--------------------------------------------------------------------------

/*month-to-date retail*/

delete
from accounts_open_monthly_aggr_retail
--where eod_date = @v_date;

-- insert into accounts_open_monthly_aggr
insert into accounts_open_monthly_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_open_monthly_base_retail x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
left join retail_deposits_backout f
on x.foracid=f.foracid
where eod_date = @v_date
and f.foracid is null
and month(x.ACCT_OPN_DATE) = month(a.structure_date) 
and year(x.ACCT_OPN_DATE) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

delete
from accounts_closed_monthly_aggr_retail
--where eod_date = @v_date;

-- insert into accounts_closed_monthly_aggr_retail
insert into accounts_closed_monthly_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_closed_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
left join retail_deposits_backout f
on x.foracid=f.foracid
where eod_date = @v_date
and f.foracid is null
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

delete
from accounts_dormant_monthly_aggr_retail
--where eod_date = @v_date;

-- insert into accounts_dormant_monthly_aggr
insert into accounts_dormant_monthly_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_dormant_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
left join retail_deposits_backout f
on x.foracid=f.foracid
where eod_date = @v_date
and f.foracid is null
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

delete
from accounts_reactivated_monthly_aggr_retail
--where eod_date = @v_date;

-- insert into accounts_reactivated_monthly_aggr_retail
insert into accounts_reactivated_monthly_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from accounts_reactivated_monthly_base x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
left join retail_deposits_backout f
on x.foracid=f.foracid
where eod_date = @v_date
and f.foracid is null

group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

--------------------------------------------------------------------------
delete
from accounts_open_ytd_aggr_retail
where eod_date <> EOMONTH(@v_date);

-- insert into accounts_open_ytd_aggr_retail
insert into accounts_open_ytd_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*),@v_date	--x.eod_date
from accounts_open_ytd_base_retail x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
left join retail_deposits_backout f
on x.foracid=f.foracid
where YEAR(x.eod_date) = YEAR(@v_date)
and f.foracid is null

group by a.staff_id, a.branch_code
order by branch_code;

delete
from accounts_closed_ytd_aggr_retail
where eod_date <> EOMONTH(@v_date);

-- insert into accounts_closed_ytd_aggr_retail
insert into accounts_closed_ytd_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), @v_date
from accounts_closed_ytd_base_retail x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
left join retail_deposits_backout f
on x.foracid=f.foracid
where YEAR(x.eod_date) = YEAR(@v_date)
and f.foracid is null
group by a.staff_id, a.branch_code
order by branch_code;

delete
from accounts_dormant_ytd_aggr_retail
where eod_date <> EOMONTH(@v_date);
-- insert into accounts_dormant_ytd_aggr_retail
insert into accounts_dormant_ytd_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), @v_date
from accounts_dormant_ytd_base_retail x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
left join retail_deposits_backout f
on x.foracid=f.foracid
where YEAR(x.eod_date) = YEAR(@v_date)
and f.foracid is null
group by a.staff_id, a.branch_code
order by branch_code;

delete
from accounts_reactivated_ytd_aggr_retail
where eod_date <> EOMONTH(@v_date);
-- insert into accounts_reactivated_ytd_aggr_retail
insert into accounts_reactivated_ytd_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), @v_date
from accounts_reactivated_ytd_base_retail x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
left join retail_deposits_backout f
on x.foracid=f.foracid
where YEAR(x.eod_date) = YEAR(@v_date)
and f.foracid is null
group by a.staff_id, a.branch_code
order by branch_code;

delete
from account_maintenance_aggregation
where eod_date = @v_date;
/*
-- insert into account_maintenance_aggregation
if EOMONTH(@v_date) = @v_date -- if it is the last day of the month, pick cot that has been paid
	insert into account_maintenance_aggregation (
		staff_id, branch_code, turnover, cot_amount, eod_date
	)
	select a.staff_id, a.branch_code, sum(cot_product), sum(COT_CHARGE_AMOUNT), x.eod_date
	from account_maintenance_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	where eod_date = @v_date
	and cot_applied_flg in ('Y')
	and cot_charge_amount > 0
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, x.EOD_DATE
	order by branch_code;
else
*/	
	insert into account_maintenance_aggregation (
		staff_id, branch_code, turnover, cot_amount, eod_date
	)
	select a.staff_id, a.branch_code, sum(cot_product), sum(COT_CHARGE_AMOUNT), x.eod_date
	from account_maintenance_base x
	inner join account_officers a
	on x.acct_mgr_user_id_2 = a.staff_id
	where eod_date = @v_date
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, x.EOD_DATE
	order by branch_code;

delete
from alco_deposit_aggregation
where eod_date = @v_date;

-- insert into alco_deposit_aggr
insert into alco_deposit_aggregation (staff_id, branch_code, DEMAND, DOMICILLIARY, SAVINGS, TENURED, total_deposit, eod_date)
select staff_id, branch_code, isnull(DEMAND, 0) as DEMAND, isnull(DOMICILLIARY, 0) as DOMICILLIARY, 
isnull(SAVINGS, 0) as SAVINGS, isnull(TENURED, 0) as TENURED, 
(isnull(DEMAND, 0) + isnull(DOMICILLIARY, 0) + isnull(SAVINGS, 0) + isnull(TENURED, 0)) as total_deposit, eod_date
from (
	select a.staff_id, a.branch_code, g.alco, sum(naira_value) total_balance, x.eod_date
	from deposits_base x
	inner join account_officers a on x.acct_mgr_user_id = a.staff_id
	inner join gl_map g on x.gl_sub_head_code = g.sh
	where x.eod_date = @v_date
	and g.MainCaption = '9'
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, g.alco, x.eod_date
	-- order by a.staff_id, a.branch_code, g.alco
) AS SourceTable PIVOT(sum(total_balance) FOR [alco] IN([DEMAND],
                                                         [DOMICILLIARY],
                                                         [SAVINGS],
                                                         [TENURED])) AS PivotTable
order by branch_code, staff_id;

-- insert into alco_deposit_aggregation_retail

delete
from alco_deposit_aggregation_retail
where eod_date = @v_date;

insert into alco_deposit_aggregation_retail (
	staff_id, branch_code, DEMAND, DOMICILLIARY, SAVINGS, TENURED, total_deposit, eod_date
)
select staff_id, branch_code, isnull(DEMAND, 0) as DEMAND, isnull(DOMICILLIARY, 0) as DOMICILLIARY, 
isnull(SAVINGS, 0) as SAVINGS, isnull(TENURED, 0) as TENURED, 
(isnull(DEMAND, 0) + isnull(DOMICILLIARY, 0) + isnull(SAVINGS, 0) + isnull(TENURED, 0)) as total_deposit, eod_date
from (
	select a.staff_id, a.branch_code, g.alco, sum(naira_value) total_balance, x.eod_date
	from deposits_base_retail x
	inner join account_officers a on x.acct_mgr_user_id = a.staff_id
	inner join gl_map g on x.gl_sub_head_code = g.sh
	inner join retail_gl_sub_heads_deposits z
	on x.gl_sub_head_code=z.gl_sub_head
	left join retail_deposits_backout f
	on x.foracid=f.foracid
	where x.eod_date = @v_date
	and g.MainCaption = '9'
	and f.foracid is null
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, g.alco, x.eod_date
	-- order by a.staff_id, a.branch_code, g.alco
) AS SourceTable PIVOT(sum(total_balance) FOR [alco] IN([DEMAND],
                                                         [DOMICILLIARY],
                                                         [SAVINGS],
                                                         [TENURED])) AS PivotTable
order by branch_code, staff_id;





-- load balance sheet movement data

delete
from balancesheet_aggregation
where eod_date = @v_date;


exec sp_load_balancesheet_movement @v_date;
-----------------------------------------------------

delete
from alco_loan_aggregation
where eod_date = @v_date;

-- insert into alco_loan_aggr
insert into alco_loan_aggregation (staff_id, branch_code, OVERDRAFT, TERM_LOAN, CBN_BOI, OTHER_LOANS, total_loan, eod_date)
select staff_id, branch_code, isnull(OVERDRAFT, 0) as OVERDRAFT, isnull(TERM_LOAN, 0) as TERM_LOAN, 
isnull(CBN_BOI, 0) as CBN_BOI, isnull(OTHER_LOANS, 0) as OTHER_LOANS, 
(isnull(OVERDRAFT, 0) + isnull(TERM_LOAN, 0) + isnull(CBN_BOI, 0) + isnull(OTHER_LOANS, 0)) as total_deposit, eod_date
from (
	select a.staff_id, a.branch_code, g.alco, sum(naira_value) total_balance, x.eod_date
	from loans_base x
	inner join account_officers a on x.acct_mgr_user_id = a.staff_id
	inner join gl_map g on x.gl_sub_head_code = g.sh
	where x.eod_date = @v_date
	and g.MainCaption = '14'
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code, g.alco, x.eod_date
	-- order by a.staff_id, a.branch_code, g.alco
) AS SourceTable PIVOT(sum(total_balance) FOR [alco] IN([OVERDRAFT],
                                                         [TERM_LOAN],
                                                         [CBN_BOI],
                                                         [OTHER_LOANS])) AS PivotTable
order by branch_code, staff_id;



--------------------------------------------------------------------

delete
from alco_loan_aggregation_retail
where eod_date = @v_date;

-- insert into alco_loan_aggr_retail
insert into alco_loan_aggregation_retail (staff_id, branch_code, OVERDRAFT, TERM_LOAN, CBN_BOI, OTHER_LOANS, total_loan, eod_date)
select staff_id, branch_code, isnull(OVERDRAFT, 0) as OVERDRAFT, isnull(TERM_LOAN, 0) as TERM_LOAN, 
isnull(CBN_BOI, 0) as CBN_BOI, isnull(OTHER_LOANS, 0) as OTHER_LOANS, 
(isnull(OVERDRAFT, 0) + isnull(TERM_LOAN, 0) + isnull(CBN_BOI, 0) + isnull(OTHER_LOANS, 0)) as total_deposit, eod_date
from (
	select a.staff_id, a.branch_code, g.alco, sum(naira_value) total_balance, x.eod_date
	from loans_base_retail x
	inner join account_officers a on x.acct_mgr_user_id = a.staff_id
	inner join gl_map g on x.gl_sub_head_code = g.sh
    inner join retail_gl_sub_heads_loans z
	on x.gl_sub_head_code=z.gl_sub_head
	left join retail_loans_backout f
	on x.foracid=f.foracid
	where x.eod_date = @v_date
	and g.MainCaption = '14'
	and f.foracid is null
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and x.foracid not in ('0302498778','0302501580')----exception list
	group by a.staff_id, a.branch_code, g.alco, x.eod_date
	-- order by a.staff_id, a.branch_code, g.alco
) AS SourceTable PIVOT(sum(total_balance) FOR [alco] IN([OVERDRAFT],
                                                         [TERM_LOAN],
                                                         [CBN_BOI],
                                                         [OTHER_LOANS])) AS PivotTable
order by branch_code, staff_id;



---------------------------------------------------


-- load pos aggregation figures
truncate table pos_aggregation

insert into pos_aggregation (
	staff_id, branch_code, total_pos, active_pos, inactive_pos, txn_count, txn_amount, 
	mtd_count_deployed, period, year, eod_date
)
select 
	a.staff_id, a.branch_code, a.total_pos, a.active_pos, 
	a.inactive_pos, b.mtd_txn_count, b.mtd_txn_amount, 
	isnull(c.mtd_deployed, 0) mtd_deployed,
	a.period, a.year, a.eod_date
from 
(
	select 
		staff_id, branch_code, 
		(isnull(Active, 0) + isnull(Inactive, 0)) as total_pos,
		isnull(Active, 0) as active_pos, 
		isnull(Inactive, 0) as inactive_pos, 
		period, year, eod_date
	from (
		select a.staff_id, a.branch_code, x.pos_status pos_status, 
			count(*) total_pos,
			x.period, x.year, x.eod_date
		from pos_base x
		inner join account_officers a
		on x.acct_mgr_user_id = a.staff_id
		and month(x.eod_date) = month(a.structure_date) 
		and year(x.eod_date) = year(a.structure_date)
		group by a.staff_id, a.branch_code, x.pos_status, 
			x.period, x.year, x.eod_date
	) AS SourceTable PIVOT(sum(total_pos) FOR pos_status IN([ACTIVE],
																[INACTIVE])) AS PivotTable
) a
join (
	select a.staff_id, a.branch_code, 
		sum(mtd_txn_count) mtd_txn_count, 
		sum(mtd_txn_amount) mtd_txn_amount,
		x.period, x.year, x.eod_date
	from pos_base x
	inner join account_officers a
	on x.acct_mgr_user_id = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	group by a.staff_id, a.branch_code,
		x.period, x.year, x.eod_date
) b
on a.staff_id = b.staff_id
left join (
	select a.staff_id, count(*) mtd_deployed
	from pos_base x
	inner join account_officers a
	on x.acct_mgr_user_id = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	where month(x.date_deployed) = month(x.eod_date)
	and year(x.date_deployed) = year(x.eod_date)
	group by a.staff_id
) c
on a.staff_id = c.staff_id

/* load cards aggregation data */
truncate table cards_aggregation

insert into cards_aggregation (
	staff_id, branch_code, 
	debit_mc, debit_visa, debit_verve,
	credit_mc, credit_visa, credit_verve,
	prepaid_mc, prepaid_visa, prepaid_verve,
	total_mc, total_visa, total_verve,
	period, year, eod_date
)
select 
	staff_id, branch_code,
	ISNULL(DEBIT_MASTERCARD, 0) debit_mc,
	ISNULL(DEBIT_VISA, 0) debit_visa,
	ISNULL(DEBIT_VERVE, 0) debit_verve,
	ISNULL(CREDIT_MASTERCARD, 0) credit_mc,
	ISNULL(CREDIT_VISA, 0) credit_visa,
	ISNULL(CREDIT_VERVE, 0) credit_verve,
	ISNULL(PREPAID_MASTERCARD, 0) prepaid_mc,
	ISNULL(PREPAID_VISA, 0) prepaid_visa,
	ISNULL(PREPAID_VERVE, 0) prepaid_verve,
	ISNULL(DEBIT_MASTERCARD, 0) + ISNULL(CREDIT_MASTERCARD, 0) + ISNULL(PREPAID_MASTERCARD, 0) total_mc,
	ISNULL(DEBIT_VISA, 0) + ISNULL(CREDIT_VISA, 0) + ISNULL(PREPAID_VISA, 0) total_visa,
	ISNULL(DEBIT_VERVE, 0) + ISNULL(CREDIT_VERVE, 0) + ISNULL(PREPAID_VERVE, 0) total_verve,
	period, year, eod_date
from 
(
	select a.staff_id, a.branch_code, x.card_type + '_' + x.card_manufacturer as card_category,
		count(*) total_cards,
		x.period, x.year, x.eod_date
	from cards_base x
	inner join account_officers a
	on x.acct_mgr_user_id = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and month(x.activated_date) = month(x.eod_date) and year(x.activated_date) = year(x.eod_date)

	group by a.staff_id, a.branch_code, x.card_type + '_' + card_manufacturer,
		x.period, x.year, x.eod_date
)  AS SourceTable 
PIVOT(sum(total_cards) FOR card_category IN (
											[DEBIT_MASTERCARD], 
											[DEBIT_VISA], 
											[DEBIT_VERVE], 
											[CREDIT_MASTERCARD], 
											[CREDIT_VISA], 
											[CREDIT_VERVE],
											[PREPAID_MASTERCARD], 
											[PREPAID_VISA], 
											[PREPAID_VERVE])
) AS PivotTable

-------------------------------------------------------------------------
/* load top cards cards aggregation data */


insert into top_cards_cards_aggregation (
	staff_id, branch_code, 
	debit_mc, debit_visa, debit_verve,
	credit_mc, credit_visa, credit_verve,
	prepaid_mc, prepaid_visa, prepaid_verve,
	total_mc, total_visa, total_verve,
	period, year, eod_date
)
select 
	staff_id, branch_code,
	ISNULL(DEBIT_MASTERCARD, 0) debit_mc,
	ISNULL(DEBIT_VISA, 0) debit_visa,
	ISNULL(DEBIT_VERVE, 0) debit_verve,
	ISNULL(CREDIT_MASTERCARD, 0) credit_mc,
	ISNULL(CREDIT_VISA, 0) credit_visa,
	ISNULL(CREDIT_VERVE, 0) credit_verve,
	ISNULL(PREPAID_MASTERCARD, 0) prepaid_mc,
	ISNULL(PREPAID_VISA, 0) prepaid_visa,
	ISNULL(PREPAID_VERVE, 0) prepaid_verve,
	ISNULL(DEBIT_MASTERCARD, 0) + ISNULL(CREDIT_MASTERCARD, 0) + ISNULL(PREPAID_MASTERCARD, 0) total_mc,
	ISNULL(DEBIT_VISA, 0) + ISNULL(CREDIT_VISA, 0) + ISNULL(PREPAID_VISA, 0) total_visa,
	ISNULL(DEBIT_VERVE, 0) + ISNULL(CREDIT_VERVE, 0) + ISNULL(PREPAID_VERVE, 0) total_verve,
	period, year, eod_date
from 
(
	select a.staff_id, a.branch_code, x.card_type + '_' + x.card_manufacturer as card_category,
		count(*) total_cards,
		x.period, x.year, x.eod_date
	from cards_base x
	inner join account_officers a
	on x.acct_mgr_user_id = a.staff_id
	and month(x.eod_date) = month(a.structure_date) 
	and year(x.eod_date) = year(a.structure_date)
	and month(x.activated_date) = month(x.eod_date) and year(x.activated_date) = year(x.eod_date)

	group by a.staff_id, a.branch_code, x.card_type + '_' + card_manufacturer,
		x.period, x.year, x.eod_date
)  AS SourceTable 
PIVOT(sum(total_cards) FOR card_category IN (
											[DEBIT_MASTERCARD], 
											[DEBIT_VISA], 
											[DEBIT_VERVE], 
											[CREDIT_MASTERCARD], 
											[CREDIT_VISA], 
											[CREDIT_VERVE],
											[PREPAID_MASTERCARD], 
											[PREPAID_VISA], 
											[PREPAID_VERVE])
) AS PivotTable

-------------------------------------------------------------------------

/*Cards Issuance Retail Aggregation*/

truncate table card_issuance_monthly_aggr_retail

insert into card_issuance_monthly_aggr_retail (
	staff_id, branch_code, total_cards, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from cards_base x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
where month(x.eod_date) = month(a.structure_date) and year(x.eod_date) = year(a.structure_date)
and month(x.activated_date) = month(x.eod_date) and year(x.activated_date) = year(x.eod_date)
and x.eod_date=@v_date
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

--------------------------------------------------------------------------
-- insert into new_loans_aggr_retail
delete from new_loans_aggr_retail
where eod_date<> EOMONTH(eod_date)

INSERT into new_loans_aggr_retail (
	staff_id,staff_name,branch_code,product_code,dis_amt,eod_date)
SELECT a.staff_id, a.staff_name, a.branch_code,a.product_code, 
sum(a.dis_amt) disbursed_amt, 
a.eod_date 
from 
(
	select y.staff_id, y.staff_name, y.branch_code,
	x.schm_code product_code,x.dis_amt,x.eod_date--, v.structure_date
	FROM new_loans_base_retail x 
	inner join account_officers y 
	on x.acct_mgr_user_id_3 = y.staff_id
	and month(x.eod_date) = month(y.structure_date) 
	and year(x.eod_date) = year(y.structure_date)
	and month(x.acct_opn_date) = month(@v_date)
	and year(x.acct_opn_date) = year(@v_date)
	where x.acct_cls_date>@v_date
	or  x.acct_cls_date is null
	and x.eod_date = @v_date
) a
group by a.staff_id, a.staff_name, a.branch_code, a.product_code,a.eod_date 
order by a.branch_code, a.staff_name;
---------------------------------------------------------------------------

/*NTB ALAT Retail Aggregation*/
delete from ntb_alat_aggr_retail
where eod_date <> eomonth(eod_date)

insert into ntb_alat_aggr_retail (
	staff_id, branch_code, total_accounts, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from ntb_alat_base x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
--inner join retail_gl_sub_heads_deposits z
--on x.gl_sub_head_code=z.gl_sub_head
where eod_date = @v_date
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
and x.acct_opn_date between DATEADD(M,DATEDIFF(M, 0,x.eod_date), 0)
and x.eod_date
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;


/*Agent Onboarding Retail Aggregation*/
truncate table agent_onboarding_aggr_retail
insert into agent_onboarding_aggr_retail (
	staff_id, branch_code, total_agents, eod_date
)
select a.staff_id, a.branch_code, count(*), x.eod_date
from agent_onboarding_base x
inner join account_officers a
on x.acct_mgr_user_id_3 = a.staff_id
--inner join retail_gl_sub_heads_deposits z
--on x.gl_sub_head_code=z.gl_sub_head
where eod_date = @v_date
and month(x.eod_date) = month(a.structure_date) 
and year(x.eod_date) = year(a.structure_date)
and x.onboarding_date between DATEADD(M,DATEDIFF(M, 0,x.eod_date), 0)
and x.eod_date
group by a.staff_id, a.branch_code, x.eod_date
order by branch_code;

/*Head Office Expense Aggregation*/

--delete
--from head_office_expense_aggr
--where eod_date <> eomonth(eod_date);

--INSERT into head_office_expense_aggr (
--	branch_code, rpt_code, gl_sub_head_code, total_exp,
--	 eod_date
--)
--SELECT a.sol_id, a.rpt_code, a.gl_sub_head_code,
--sum(a.tran_amt) total_expense,
--a.eod_date 
--from 
--(
--	select x.sol_id, x.rpt_code, x.gl_sub_head_code, x.tran_amt, x.eod_date, x.tran_date
--	FROM head_office_expense_base x
--	where month(x.eod_date) = month(x.tran_date) 
--	and year(x.eod_date) = year(x.tran_date) 
--	and x.eod_date =@v_date
--	and process_flag = 0
--) a
--group by a.sol_id, a.rpt_code, a.gl_sub_head_code, a.eod_date 
--order by a.sol_id
--update head_office_expense_base set process_flag = 1;


/*Branch Expense Aggregation*/

--delete
--from branch_expense_aggr
--where eod_date <> eomonth(eod_date);

--INSERT into branch_expense_aggr (
--	branch_code, gl_sub_head_code, total_exp,
--	 eod_date
--)
--SELECT a.sol_id, a.gl_sub_head_code,
--sum(a.tran_amt) total_expense,
--a.eod_date 
--from 
--(
--	select x.sol_id, x.gl_sub_head_code, x.tran_amt, x.eod_date, x.tran_date
--	FROM branch_expense_base x
--	where month(x.eod_date) = month(x.tran_date) 
--	and year(x.eod_date) = year(x.tran_date) 
--	and x.eod_date =@v_date
--	and process_flag = 0
--) a
--group by a.sol_id, a.gl_sub_head_code, a.eod_date 
--order by a.sol_id
--update branch_expense_base set process_flag = 1;

/*
-------------------------------------------------------
/* commission & fees aggregates */
---------------------------------------------------------
delete
from comm_fees_aggr
where eod_date <> eomonth(eod_date);

INSERT into comm_fees_aggr (
	staff_id,staff_name,branch_code, gl_sub_head_code, total_income,
	 eod_date
)
SELECT a.staff_id,a.staff_name, a.branch_code, a.gl_sub_head_code,
sum(a.charge_amount) total_comm_fees,
a.eod_date 
from 
(
	select y.staff_id,y.staff_name,y.branch_code, gl_sub_head_code, x.income_acct, x.eod_date, x.charge_amount
	FROM comm_fees_base x
	inner join account_officers y 
	on x.acct_mgr_user_id = y.staff_id
	and month(x.eod_date)=month(y.structure_date)
	and year(x.eod_date)=year(y.structure_date)
	where x.chrg_tran_date between DATEADD(DAY,1,EOMONTH(@v_date,-1)) and @v_date
	and x.eod_date =@v_date
) a
group by  a.staff_id,a.staff_name,a.branch_code, a.gl_sub_head_code, a.eod_date 
order by a.branch_code

-------------------------------------------------------
/* commission & fees branch aggregates */
---------------------------------------------------------
delete
from comm_fees_branch_aggr
where eod_date <> eomonth(eod_date);

INSERT into comm_fees_branch_aggr (
	branch_code, gl_sub_head_code, total_income,
	 eod_date
)
SELECT  a.sol_id, a.gl_sub_head_code,
sum(a.charge_amount) total_comm_fees,
a.eod_date 
from 
(
	select x.sol_id,  gl_sub_head_code, x.income_acct, x.eod_date, x.charge_amount
	FROM comm_fees_branch_base x
	--inner join account_officers y 
	--on x.acct_mgr_user_id = y.staff_id
	--and month(x.eod_date)=month(y.structure_date)
	--and year(x.eod_date)=year(y.structure_date)
	where x.chrg_tran_date between DATEADD(DAY,1,EOMONTH(@v_date,-1)) and @v_date
	and x.eod_date = @v_date
) a
group by  a.sol_id, a.gl_sub_head_code, a.eod_date 
order by a.sol_id

*/
