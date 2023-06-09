USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_loans_retail]    Script Date: 2/28/2023 8:51:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_loans_retail]
    @pDirectorateCode nvarchar(50),   
    @pRegionCode nvarchar(50),
	@pClusterCode nvarchar(50),
	@pBranchCode nvarchar(50),
	@pSBU nvarchar(50),
	@pAccountOfficer nvarchar(50),
	@pStaffID nvarchar(50),
	@pRunDate nvarchar(50)
AS   

SET NOCOUNT ON;  
if @pDirectorateCode = 'ALL'
	BEGIN
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'TOTAL_BANK', NULL, GETDATE());

		select a.directorate_code, a.directorate_name as 'Directorate',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
		sum(isnull(a.loan_budget, 0)) as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.cluster_code, v.directorate_name, v.directorate_code, t.loan_budget
			from vw_base_structure_retail v
			left join cluster_branch_targets_retail t
			on v.branch_code = t.branch_code
			where month(v.structure_date) = month(@pRunDate)
			and year(v.structure_date) = year(@pRunDate)
			and month(t.structure_date) = month(@pRunDate)
			and year(t.structure_date) = year(@pRunDate)
		) a
		left join
		(
			select x.branch_code, sum(x.actual_balance) actual_balance, 
			sum(x.average_balance) average_balance, sum(x.int_income) int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by directorate_code, directorate_name
		order by directorate_name;
	END
else if @pRegionCode ='ALL' 
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'DIRECTORATE', @pDirectorateCode, GETDATE());

		select a.region_code, a.region_name as 'Region',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
		sum(isnull(a.loan_budget, 0)) as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.cluster_code, v.region_name, v.region_code, t.loan_budget
			from vw_base_structure_retail v
			left join cluster_branch_targets_retail t
			on v.branch_code = t.branch_code
			where directorate_code = @pDirectorateCode
			and month(v.structure_date) = month(@pRunDate)
			and year(v.structure_date) = year(@pRunDate)
			and month(t.structure_date) = month(@pRunDate)
			and year(t.structure_date) = year(@pRunDate)
		) a
		left join
		(
			select x.branch_code, sum(x.actual_balance) actual_balance, 
			sum(x.average_balance) average_balance, sum(x.int_income) int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by a.region_code, region_name
		order by region_name;
	END
else if @pClusterCode='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'REGION', @pRegionCode, GETDATE());

		select a.cluster_code, a.cluster_name as 'Cluster',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
		sum(isnull(a.loan_budget, 0)) as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.cluster_name, v.cluster_code, t.loan_budget
			from vw_base_structure_retail v
			left join cluster_branch_targets_retail t
			on v.branch_code = t.branch_code
			where region_code = @pRegionCode
			and month(v.structure_date) = month(@pRunDate)
			and year(v.structure_date) = year(@pRunDate)
			and month(t.structure_date) = month(@pRunDate)
			and year(t.structure_date) = year(@pRunDate)
		) a
		left join
		(
			select x.branch_code, sum(x.actual_balance) actual_balance, 
			sum(x.average_balance) average_balance, sum(x.int_income) int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by a.cluster_code, cluster_name
		order by cluster_name;
	END
else if @pBranchCode='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'CLUSTER', @pClusterCode, GETDATE());

		select a.branch_code, a.branch_name as 'Branch',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
		--sum(isnull(a.loan_target, 0))/1000 
		0 as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.branch_name,  t.loan_target
			from vw_base_structure_retail v
			left join branch_targets t
			on v.branch_code=t.branch_code
			where cluster_code = @pClusterCode
			and month(v.structure_date) = month(@pRunDate)
			and year(v.structure_date) = year(@pRunDate)
			and month(t.structure_date) = month(@pRunDate)
			and year(t.structure_date) = year(@pRunDate)
		) a
		left join
		(
			select x.branch_code, sum(x.actual_balance) actual_balance, 
			sum(x.average_balance) average_balance, sum(x.int_income) int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by a.branch_code, branch_name
		order by branch_name;
	END
else if @pSBU='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'BRANCH', @pBranchCode, GETDATE());

		select a.sbu_id, a.sbu_desc as 'SBU',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
	    --(case when a.sbu_desc = 'BDM' then dbo.fn_get_branch_loan_target(@pBranchCode, @pRunDate) else 0 end)/1000 
		0 as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select a.staff_id, s.sbu_desc, s.sbu_id, 0 as loan_target
			from  account_officers a
			inner join sbu s
			on a.sbu_id = s.sbu_id
			where a.branch_code = @pBranchCode
			and month(a.structure_date) = month(@pRunDate)
			and year(a.structure_date) = year(@pRunDate)
		) a
		left join
		(
			select x.staff_id, x.actual_balance, x.average_balance, x.int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
		) b
		on a.staff_id = b.staff_id
		group by sbu_id, sbu_desc
		order by sbu_desc;
	END
else if @pAccountOfficer='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'SBU', @pSBU, GETDATE());

		select a.staff_id, a.staff_name as 'Account Officer',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
		--sum(isnull(a.loan_target, 0))/1000 
		0 as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select a.staff_id, a.staff_name, isnull(b.loan_target, 0) loan_target
			from  account_officers a
			left join account_officer_targets b
			on a.staff_id = b.staff_id
			where branch_code = @pBranchCode
			and sbu_id = @pSBU
			and month(a.structure_date) = month(@pRunDate)
			and year(a.structure_date) = year(@pRunDate)
			and month(isnull(b.structure_date, a.structure_date)) = month(@pRunDate)
			and year(isnull(b.structure_date, a.structure_date)) = year(@pRunDate)
		) a
		left join
		(
			select x.staff_id, x.actual_balance, x.average_balance, x.int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
		) b
		on a.staff_id = b.staff_id
		group by a.staff_id, staff_name
		order by a.staff_name;
	END
else
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOANS_BY_CLUSTER', 'ACCOUNT_OFFICER', @pAccountOfficer, GETDATE());

		select a.staff_id, a.staff_name as 'Account Officer',
		sum(isnull(abs(b.actual_balance), 0))/1000 as 'Actual (N ''000)',
		sum(isnull(abs(b.average_balance), 0))/1000 as 'Average (N ''000)', 
		--sum(isnull(a.loan_target, 0))/1000 
		0 as 'Target (N ''000)',
		sum(isnull(abs(b.int_income), 0))/1000 as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select a.staff_id, a.staff_name, isnull(b.loan_target, 0) loan_target
			from  account_officers a
			left join account_officer_targets b
			on a.staff_id = b.staff_id
			where a.staff_id = @pAccountOfficer
			and month(a.structure_date) = month(@pRunDate)
			and year(a.structure_date) = year(@pRunDate)
			and month(isnull(b.structure_date, a.structure_date)) = month(@pRunDate)
			and year(isnull(b.structure_date, a.structure_date)) = year(@pRunDate)
		) a
		left join
		(
			select x.staff_id, x.actual_balance, x.average_balance, x.int_income
			from loans_aggr_retail x
			where x.eod_date = @pRunDate
		) b
		on a.staff_id = b.staff_id
		group by a.staff_id, staff_name
		order by a.staff_name;
	END
