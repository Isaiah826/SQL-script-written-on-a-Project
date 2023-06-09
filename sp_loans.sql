USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_loans]    Script Date: 2/28/2023 8:49:34 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_loans]
    @pDirectorateCode nvarchar(50),   
    @pRegionCode nvarchar(50),
	@pZoneCode nvarchar(50),
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
		values (@pStaffID, 'LOAN', 'TOTAL_BANK', NULL, GETDATE());

		select a.directorate_name as 'Region',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(a.loan_target, 0))/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.directorate_name, t.loan_target
			from vw_base_structure v
			left join branch_targets t
			on v.branch_code=t.branch_code
			and v.structure_date = t.structure_date
			where month(v.structure_date) = month(@pRunDate)
			and year(v.structure_date) = year(@pRunDate)

		) a
		left join
		(
			select x.branch_code, sum(x.actual_balance) actual_balance, 
			sum(x.average_balance) average_balance, sum(x.int_income) int_income
			from loans_aggr x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by directorate_name
		order by directorate_name;
	END
else if @pRegionCode ='ALL' 
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOAN', 'DIRECTORATE', @pDirectorateCode, GETDATE());

		select a.region_name as 'Region',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(a.loan_target, 0))/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.region_name, t.loan_target
			from vw_base_structure v
			left join branch_targets t
			on v.branch_code=t.branch_code
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
			from loans_aggr x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by region_name
		order by region_name;
	END
else if @pZoneCode='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOAN', 'REGION', @pRegionCode, GETDATE());

		select a.zone_name as 'Zone',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(a.loan_target, 0))/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.zone_name, t.loan_target
			from vw_base_structure v
			left join branch_targets t
			on v.branch_code=t.branch_code
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
			from loans_aggr x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by zone_name
		order by zone_name;
	END
else if @pBranchCode='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOAN', 'ZONE', @pZoneCode, GETDATE());

		select a.branch_name as 'Branch',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(a.loan_target, 0))/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select v.branch_code, v.branch_name, t.loan_target
			from vw_base_structure v
			left join branch_targets t
			on v.branch_code=t.branch_code
			where zone_code = @pZoneCode
			and month(v.structure_date) = month(@pRunDate)
			and year(v.structure_date) = year(@pRunDate)
			and month(t.structure_date) = month(@pRunDate)
			and year(t.structure_date) = year(@pRunDate)
		) a
		left join
		(
			select x.branch_code, sum(x.actual_balance) actual_balance, 
			sum(x.average_balance) average_balance, sum(x.int_income) int_income
			from loans_aggr x
			where x.eod_date = @pRunDate
			group by x.branch_code
		) b
		on a.branch_code = b.branch_code
		group by branch_name
		order by branch_name;
	END
else if @pSBU='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOAN', 'BRANCH', @pBranchCode, GETDATE());

		select a.sbu_desc as 'SBU',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, (case when a.sbu_desc = 'BDM' then dbo.fn_get_branch_loan_target(@pBranchCode, @pRunDate) else 0 end)/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select a.staff_id, s.sbu_desc, 0 as loan_target
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
			from loans_aggr x
			where x.eod_date = @pRunDate
		) b
		on a.staff_id = b.staff_id
		group by sbu_desc
		order by sbu_desc;
	END
else if @pAccountOfficer='ALL'
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOAN', 'SBU', @pSBU, GETDATE());

		select a.staff_name as 'Account Officer',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(a.loan_target, 0))/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select a.staff_id, a.staff_name, isnull(b.loan_target, 0) loan_target
			from  account_officers a
			left join account_officer_targets b
			on a.staff_id = b.staff_id
			and a.structure_date = b.structure_date
			where branch_code = @pBranchCode
			and sbu_id = @pSBU
			and a.structure_date = EOMONTH(@pRunDate)
			
		) a
		left join
		(
			select x.staff_id, x.actual_balance, x.average_balance, x.int_income
			from loans_aggr x
			where x.eod_date = @pRunDate
		) b
		on a.staff_id = b.staff_id
		group by staff_name
		order by a.staff_name;
	END
else
	BEGIN 
		/* INSERT A LOG */
		insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
		values (@pStaffID, 'LOAN', 'ACCOUNT_OFFICER', @pAccountOfficer, GETDATE());

		select a.staff_name as 'Account Officer',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.actual_balance), 0))/1000), 1) as 'Actual (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.average_balance), 0))/1000), 1) as 'Average (N ''000)', 
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(a.loan_target, 0))/1000), 1) as 'Target (N ''000)',
		CONVERT(VARCHAR, CONVERT(MONEY, sum(isnull(abs(b.int_income), 0))/1000), 1) as 'Int.Inc (N ''000)', 
		'0' as 'Yield (%)', '0' as ' Contribution','0' as '% Achieved' 
		from 
		(
			select a.staff_id, a.staff_name, isnull(b.loan_target, 0) loan_target
			from  account_officers a
			left join account_officer_targets b
			on a.staff_id = b.staff_id
			and a.structure_date = b.structure_date
			where a.staff_id = @pAccountOfficer
			and a.structure_date = EOMONTH(@pRunDate)
			
		) a
		left join
		(
			select x.staff_id, x.actual_balance, x.average_balance, x.int_income
			from loans_aggr x
			where x.eod_date = @pRunDate
		) b
		on a.staff_id = b.staff_id
		group by staff_name
		order by a.staff_name;
	END