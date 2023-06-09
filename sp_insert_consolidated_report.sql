USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_consolidated_report]    Script Date: 2/28/2023 10:07:02 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER     PROCEDURE [dbo].[sp_insert_consolidated_report]
		@pYear NVARCHAR(10),
		@pBranchCode VARCHAR(10)
AS

DECLARE @factor FLOAT,
		--@pBranchCode VARCHAR(10),
		@pDate DATE,
		@pNyear FLOAT
		

SET @factor = 8.333333333
--SET @pBranchCode = '001'
SELECT @pDate = CONVERT(DATE,config_value) from wa_budget_config WHERE config_id = 1
--SET @pYear = '2022'
SET @pNyear = DATEPART(dy, @pYear +'1231')



IF @pBranchCode = 'ALL'

BEGIN

DELETE FROM wa_budget_consolidated_report WHERE budget_year = @pYear 


INSERT INTO wa_budget_consolidated_report 


SELECT Report, report_group, caption, position, A.branch_code, 
		JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, YE_TOTAL, @pYear AS budget_year

FROM

(SELECT DISTINCT branch_code from vw_base_structure WHERE YEAR(structure_date) = @pYear) A

LEFT JOIN

(
/** BALANCE SHEET **/

SELECT DISTINCT 'BALANCE SHEET' AS Report,
				CASE WHEN map.position IN (116, 125, 128, 119, 122, 131, 134, 137) THEN 'ASSET' 
					WHEN map.position IN (206, 224, 236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251, 254) THEN 'LIABILITIES'
					END AS report_group,
				UPPER(map.name) as caption, 
				--map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				--isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				--isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position AS position,
				bs.branch_code,
				bs.month_2_avg + ((@factor*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((@factor*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((@factor*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((@factor*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((@factor*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((@factor*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((@factor*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((@factor*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((@factor*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((@factor*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((@factor*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as YE_TOTAL
--				dapp.budget_--year AS budget_year
				
	FROM mpr_map map
	JOIN (select branch_code, caption, sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date

	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate 
	AND map.position IN (116, 125, 128, 119, 122, 131, 134, 137, 206, 224, 236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251, 254)
	AND YEAR(dapp.budget_year) = @pYear
	--AND bs.branch_code = @pBranchCode 
	--ORDER BY branch_code,map.position,map.class)

	) B

               ON A.branch_code = B.branch_code
               --WHERE A.branch_code = @pBranchCode

UNION

-------SUBTOTALS--------------------------------------

SELECT * FROM [dbo].[fn_table_wa_budget_pool_aggregate] (@pYear,@pBranchCode)


UNION

/** INCOME STATEMENT **/

/** INTEREST INCOME & EXPENSE **/
SELECT 'INCOME STATEMENT' AS Report,
		CASE WHEN A.position IN (116, 125, 128, 119, 122, 131, 134, 137) THEN 'INTEREST INCOME' 
				WHEN A.position IN (236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251) THEN 'INTEREST EXPENSE'
				END AS report_group,
		A.caption,
		A.position,
		branch_code,
		SUM(A.JAN * (31/@pNyear) * B.[JAN ]) AS JAN,
		CASE WHEN @pNyear = 365 THEN SUM(A.FEB * (28/@pNyear) * B.FEB) WHEN @pNyear = 366 THEN SUM(A.FEB * (29/@pNyear) * B.FEB) END AS FEB,
		SUM(A.MAR * (31/@pNyear) * B.MAR) AS MAR,
		SUM(A.APR * (30/@pNyear) * B.APR) AS APR,
		SUM(A.MAY * (31/@pNyear) * B.MAY) AS MAY,
		SUM(A.JUN * (30/@pNyear) * B.JUN) AS JUN,
		SUM(A.JUL * (31/@pNyear) * B.JUL) AS JUL,
		SUM(A.AUG * (31/@pNyear) * B.AUG) AS AUG,
		SUM(A.SEP * (30/@pNyear) * B.SEPT) AS SEP,
		SUM(A.OCT * (31/@pNyear) * B.OCT) AS OCT,
		SUM(A.NOV * (30/@pNyear) * B.NOV) AS NOV,
		SUM(A.DEC * (31/@pNyear) * B.DEC) AS DEC,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) + 
				(A.MAY  * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL  * (31/@pNyear) * B.JUL) + (A.AUG * (31/@pNyear) * B.AUG) + 
				(A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT  * (31/@pNyear) * B.OCT) + (A.NOV * (30/@pNyear) * B.NOV) + (A.DEC * (31/@pNyear) * B.DEC)) AS YE_TOTAL,
		@pYear as budget_year


FROM

	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((@factor*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((@factor*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((@factor*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((@factor*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((@factor*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((@factor*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((@factor*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((@factor*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((@factor*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((@factor*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((@factor*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC,
				dapp.budget_year
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
	AND YEAR(dapp.budget_year) = @pYear

	--AND bs.branch_code = @pBranchCode
	--ORDER BY branch_code,map.position,map.class
	) A

JOIN wa_budget_rate_assumptions  B
	ON A.position = B.position

WHERE A.position IN (116, 125, 128, 119, 122, 131, 134, 137,236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251)
GROUP BY A.caption,	branch_code, A.position, A.budget_year 



UNION

/** FEE BASED INCOME **/


	SELECT distinct 'INCOME STATEMENT' AS Report,
		'FEE BASED INCOME' AS report_group,
		income_line AS caption,
		a.position,
		a.branch_code,
		monthly as JAN, monthly as FEB, monthly as MAR, monthly AS APR, monthly as MAY, monthly as JUN, monthly as JUL, monthly as AUG, 
		monthly as SEP, monthly as OCT, monthly as NOV, monthly as DEC, monthly * 12 as ye_total,
		YEAR(a.structure_date) AS budget_year
	FROM
	
	(SELECT DISTINCT branch_code, 'Off Balance Sheet Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			off_balancesheet_fees/12 AS monthly, 607 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'fx income' AS income_line, 'FEE BASED INCOME'  as report, 
			fx_Income/12 AS monthly, 609 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'E-Business income' AS income_line, 'FEE BASED INCOME'  as report, 
			ebusiness_income/12 AS monthly, 610 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Other income' AS income_line, 'FEE BASED INCOME'  as report, 
			other_income/12 AS monthly, 634 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Commisions on Collections' AS income_line, 'FEE BASED INCOME'  as report, 
			com_on_collections/12 AS monthly, 614 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Account Maintenance Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			account_maintenance_fees/12 AS monthly, 603 AS position, structure_date
	FROM wa_budget_commission ) a
	WHERE YEAR(structure_date) = @pYear --AND branch_code = @pBranchCode



	--left join
	--(select branch_code, caption, sum(month_2_avg)as month_2_avg , eod_date 
	--from mpr_bal_sheet_report 
	--where caption in('CBN/BOI LOAN','RETAIL PRODUCT LOAN', 
	--'BUSINESS LOAN','TERM LOANS','OVERDRAFTS','LEASES','WEMA ASSET ACQUISITION SCHEME') 
	--and eod_date = '20220831' 
	--group by branch_code, caption, position,eod_date) b
	--on a.branch_code = b.branch_code
	--where a.structure_date = b.eod_date

UNION



/** Facility Related Fees **/

	SELECT 'INCOME STATEMENT' AS Report,
		'FEE BASED INCOME' AS report_group, 'Facility Related Fees' as caption, 
		NULL AS position, fr.branch_code,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12)) as JAN,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)) as FEB,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12)) as MAR,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)) as APR,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12)) as MAY,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12)) as JUN,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12)) as JUL,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12)) as AUG,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12)) as SEP,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12)) as OCT,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12)) as NOV,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12)) as DEC,

	((sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12)))) AS ye_total,
	@pYear as budget_year

	from
	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((8.333*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((8.333*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((8.333*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((8.333*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((8.333*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((8.333*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((8.333*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((8.333*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((8.333*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((8.333*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((8.333*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((8.333*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position 

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
		--and bs.branch_code = @pBranchCode
		and  map.class = 'ASSET')fR
	join
	(select branch_code,  sum(month_2_avg)as total_start_bal  
	from mpr_bal_sheet_report 
	where caption in('CBN/BOI LOAN','RETAIL PRODUCT LOAN', 
	'BUSINESS LOAN','TERM LOANS','OVERDRAFTS','LEASES','WEMA ASSET ACQUISITION SCHEME') 
	and eod_date = @pDate --and branch_code = @pBranchCode
	group by branch_code)start_bal_total
	on fr.branch_code = start_bal_total.branch_code
	group by total_start_bal, fR.branch_code


UNION

/** OPEX **/


	/** Staff Cost **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'STAFF COST' AS caption,
		NULL AS position,
		b.branch_code, 
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JAN, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS FEB, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS MAR,
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS APR, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS MAY, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JUN,
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JUL, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS AUG, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS SEP,
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS OCT, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS NOV, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS DEC,
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 12), 0) AS YE_TOTAL,
		@pYear AS budget_year
	FROM wa_budget_comm_staff_cost a
	JOIN 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  b
	ON a.branch_code = b.branch_code AND a.year = YEAR(b.budget_date)
	WHERE a.year = @pYear --AND a.branch_code = @pBranchCode 
	GROUP BY b.branch_code, a.monthly

UNION

	/** Premises Maintenance Expense **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'PREMISES MAINTENANCE EXPENSE' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL,
		SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Premises Maintenance%'
	GROUP BY branch_code

	


UNION

	/** Depreciation **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'DEPRECIATION' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly) AS JAN, SUM(monthly) AS FEB, SUM(monthly) AS MAR, SUM(monthly) AS APR, SUM(monthly) AS MAY, SUM(monthly) AS JUN, 
		SUM(monthly) AS JUL, SUM(monthly) AS AUG, SUM(monthly) AS SEP, SUM(monthly) AS OCT, SUM(monthly) AS NOV, SUM(monthly) AS DEC, 
		SUM(ye_total) AS YE_TOTAL,@pYear as budget_year
		FROM
		wa_budget_depreciation
		WHERE year = @pYear
		GROUP BY branch_code

	--	SUM(monthly_depr) AS JAN, SUM(monthly_depr) AS FEB, SUM(monthly_depr) AS MAR, SUM(monthly_depr) AS APR, SUM(monthly_depr) AS MAY, SUM(monthly_depr) AS JUN, 
	--	SUM(monthly_depr) AS JUL, SUM(monthly_depr) AS AUG, SUM(monthly_depr) AS SEP, SUM(monthly_depr) AS OCT, SUM(monthly_depr) AS NOV, SUM(monthly_depr) AS DEC, 
	--	SUM(depr_amount) AS YE_TOTAL
	--	--year AS budget_year
	--FROM 
	--(SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_capex_depr
	--UNION
	--SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_HO_capex_depr) a
	--wa_budget_depreciation
	--GROUP BY branch_code

	
UNION

	/** Public Relations and Advert Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'PUBLIC RELATIONS AND ADVERT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year

	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Public Relations and Advert%'
	GROUP BY branch_code


UNION

	/** Communication Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'COMMUNICATION EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Communication%'
	GROUP BY branch_code



UNION

	/** Printing and Stationery Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'PRINTING AND STATIONERY EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly_amort) AS JAN, SUM(monthly_amort) AS FEB, SUM(monthly_amort) AS MAR, SUM(monthly_amort) AS APR, SUM(monthly_amort) AS MAY, SUM(monthly_amort) AS JUN, 
		SUM(monthly_amort) AS JUL, SUM(monthly_amort) AS AUG, SUM(monthly_amort) AS SEP, SUM(monthly_amort) AS OCT, SUM(monthly_amort) AS NOV, SUM(monthly_amort) AS DEC, 
		SUM(total_cost) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 	
	(SELECT branch_code, monthly_amort, total_cost FROM wa_budget_stationery
	UNION
	SELECT branch_code, monthly_amort, total_cost FROM wa_budget_HO_stationery) a
	--JOIN wa_budget_HO_stationery
	GROUP BY branch_code


UNION

	/** Other Business Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'OTHER BUSINESS EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Business%'
	GROUP BY branch_code


UNION

	/** Transport Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'TRANSPORT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Transport%'
	GROUP BY branch_code


UNION

	/** Other Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'OTHER EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Expense%'
	GROUP BY branch_code









UNION

/** INCOME STATEMENT YTD **/

/** INTEREST INCOME & EXPENSE YTD **/
SELECT 'INCOME STATEMENT YTD' AS Report,
		CASE WHEN A.position IN (116, 125, 128, 119, 122, 131, 134, 137) THEN 'INTEREST INCOME YTD' 
				WHEN A.position IN (236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251) THEN 'INTEREST EXPENSE YTD'
				END AS report_group,
		A.caption,
		A.position,
		branch_code,
		SUM(A.JAN * (31/@pNyear) * B.[JAN ]) AS JAN,
		CASE WHEN @pNyear = 365 THEN SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB)) 
					WHEN @pNyear = 366 THEN SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (29/@pNyear) * B.FEB)) END AS FEB,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR)) AS MAR,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR)) AS APR,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY)) AS MAY,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN)) AS JUN,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL)) AS JUL,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG)) AS AUG,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT)) AS SEP,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT * (31/@pNyear) * B.OCT)) AS OCT,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT * (31/@pNyear) * B.OCT) 
				+ (A.NOV * (30/@pNyear) * B.NOV)) AS NOV,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT * (31/@pNyear) * B.OCT) 
				+ (A.NOV * (30/@pNyear) * B.NOV) + (A.DEC * (31/@pNyear) * B.DEC)) AS DEC,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) + 
				(A.MAY  * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL  * (31/@pNyear) * B.JUL) + (A.AUG * (31/@pNyear) * B.AUG) + 
				(A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT  * (31/@pNyear) * B.OCT) + (A.NOV * (30/@pNyear) * B.NOV) + (A.DEC * (31/@pNyear) * B.DEC)) AS YE_TOTAL,
		@pYear as budget_year



FROM

	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((@factor*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((@factor*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((@factor*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((@factor*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((@factor*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((@factor*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((@factor*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((@factor*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((@factor*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((@factor*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((@factor*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC,
				dapp.budget_year
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
	--AND bs.branch_code = @pBranchCode
	--ORDER BY branch_code,map.position,map.class
	) A

JOIN wa_budget_rate_assumptions  B
	ON A.position = B.position

WHERE A.position IN (116, 125, 128, 119, 122, 131, 134, 137,	236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251)
GROUP BY A.caption,	branch_code, A.position, A.budget_year



UNION

/** FEE BASED INCOME YTD **/


	SELECT distinct 'INCOME STATEMENT YTD' AS Report,
		'FEE BASED INCOME YTD' AS report_group,
		income_line AS caption,
		a.position,
		a.branch_code,
		monthly as JAN, monthly * 2 as FEB, monthly * 3 as MAR, monthly * 4 AS APR, monthly * 5 as MAY, monthly * 6 as JUN, 
		monthly * 7 as JUL, monthly * 8 as AUG, monthly * 9 as SEP, monthly * 10 as OCT, monthly * 11 as NOV, monthly * 12 as DEC, 
		monthly * 12 as ye_total,
		YEAR(a.structure_date) AS budget_year
	FROM
	
	(SELECT DISTINCT branch_code, 'Off Balance Sheet Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			off_balancesheet_fees/12 AS monthly, 607 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'fx income' AS income_line, 'FEE BASED INCOME'  as report, 
			fx_Income/12 AS monthly, 609 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'E-Business income' AS income_line, 'FEE BASED INCOME'  as report, 
			ebusiness_income/12 AS monthly, 610 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Other income' AS income_line, 'FEE BASED INCOME'  as report, 
			other_income/12 AS monthly, 634 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Commisions on Collections' AS income_line, 'FEE BASED INCOME'  as report, 
			com_on_collections/12 AS monthly, 614 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Account Maintenance Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			account_maintenance_fees/12 AS monthly, 603 AS position, structure_date
	FROM wa_budget_commission ) a
	WHERE YEAR(structure_date) = @pYear




UNION


/** Facility Related Fees YTD **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'FEE BASED INCOME YTD' AS report_group, 'Facility Related Fees' as caption, 
		NULL AS position, fr.branch_code,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12)) as JAN,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12))) as FEB,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) as MAR,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12))) as APR,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) as MAY,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) as JUN,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) as JUL,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) as AUG,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) as SEP,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) as OCT,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) as NOV,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12))) as DEC,

	((sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12)))) AS ye_total,
	@pYear as budget_year

	from
	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((8.333*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((8.333*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((8.333*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((8.333*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((8.333*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((8.333*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((8.333*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((8.333*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((8.333*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((8.333*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((8.333*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((8.333*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position 

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
		--and bs.branch_code = @pBranchCode
		and  map.class = 'ASSET')fR
	join
	(select branch_code,  sum(month_2_avg)as total_start_bal  
	from mpr_bal_sheet_report 
	where caption in('CBN/BOI LOAN','RETAIL PRODUCT LOAN', 
	'BUSINESS LOAN','TERM LOANS','OVERDRAFTS','LEASES','WEMA ASSET ACQUISITION SCHEME') 
	and eod_date = @pDate --and branch_code = @pBranchCode
	group by branch_code)start_bal_total
	on fr.branch_code = start_bal_total.branch_code
	group by total_start_bal, fR.branch_code



UNION

/** OPEX **/


	/** Staff Cost **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'STAFF COST' AS caption,
		NULL AS position,
		b.branch_code, 
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JAN, ROUND(((a.monthly + (SUM(b.total_cost) / 12) * 2)), 0) AS FEB, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 3), 0) AS MAR, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 4), 0) AS APR, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 5), 0) AS MAY, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 6), 0) AS JUN,
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 7), 0) AS JUL, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 8), 0) AS AUG, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 9), 0) AS SEP, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 10), 0) AS OCT, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 11), 0) AS NOV, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 12), 0) AS DEC,
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 12), 0) AS YE_TOTAL,
		@pYear AS budget_year
	FROM wa_budget_comm_staff_cost a
	JOIN 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  b
	ON a.branch_code = b.branch_code AND a.year = YEAR(b.budget_date)
	--WHERE a.branch_code = @pBranchCode 
	GROUP BY b.branch_code, a.monthly

UNION

	/** Premises Maintenance Expense **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'PREMISES MAINTENANCE EXPENSE' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Premises Maintenance%'
	GROUP BY branch_code

	


UNION

	/** Depreciation **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'DEPRECIATION' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly) AS JAN, SUM(monthly)*2 AS FEB, SUM(monthly)*3 AS MAR, SUM(monthly)*4 AS APR, SUM(monthly)*5 AS MAY, SUM(monthly)*6 AS JUN, 
		SUM(monthly)*7 AS JUL, SUM(monthly)*8 AS AUG, SUM(monthly)*9 AS SEP, SUM(monthly)*10 AS OCT, SUM(monthly)*11 AS NOV, SUM(monthly)*12 AS DEC, 
		SUM(ye_total) AS YE_TOTAL, @pYear as budget_year
	FROM wa_budget_depreciation
	WHERE year = @pYear
	GROUP BY branch_code

	--	SUM(monthly_depr) AS JAN, SUM(monthly_depr) * 2 AS FEB, SUM(monthly_depr) * 3 AS MAR, SUM(monthly_depr) * 4 AS APR, SUM(monthly_depr) * 5 AS MAY, 
	--	SUM(monthly_depr) * 6 AS JUN, SUM(monthly_depr) * 7 AS JUL, SUM(monthly_depr) * 8 AS AUG, SUM(monthly_depr) * 9 AS SEP, SUM(monthly_depr) * 10 AS OCT, 
	--	SUM(monthly_depr) * 11 AS NOV, SUM(monthly_depr) * 12 AS DEC, SUM(depr_amount) * 12 AS YE_TOTAL
	--	--year AS budget_year
	--FROM 
	--(SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_capex_depr
	--UNION
	--SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_HO_capex_depr) a
	----wa_budget_depreciation
	--GROUP BY branch_code

	
UNION

	/** Public Relations and Advert Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'PUBLIC RELATIONS AND ADVERT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Public Relations and Advert%'
	GROUP BY branch_code


UNION

	/** Communication Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'COMMUNICATION EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 	
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Communication%'
	GROUP BY branch_code



UNION

	/** Printing and Stationery Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'PRINTING AND STATIONARY EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly_amort) AS JAN, SUM(monthly_amort) * 2 AS FEB, SUM(monthly_amort) * 3 AS MAR, SUM(monthly_amort) * 4 AS APR, SUM(monthly_amort) * 5 AS MAY, 
		SUM(monthly_amort) * 6 AS JUN, SUM(monthly_amort) * 7 AS JUL, SUM(monthly_amort) * 8 AS AUG, SUM(monthly_amort) * 9 AS SEP, SUM(monthly_amort) * 10 AS OCT, 
		SUM(monthly_amort) * 11 AS NOV, SUM(monthly_amort) * 12 AS DEC, SUM(monthly_amort) * 12 AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, monthly_amort, total_cost FROM wa_budget_stationery
	UNION
	SELECT branch_code, monthly_amort, total_cost FROM wa_budget_HO_stationery) a
	GROUP BY branch_code


UNION

	/** Other Business Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'OTHER BUSINESS EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Business%'
	GROUP BY branch_code


UNION

	/** Transport Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'TRANSPORT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Transport%'
	GROUP BY branch_code


UNION

	/** Other Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'OTHER EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Expense%'
	GROUP BY branch_code
--) B

--ON A.branch_code = B.branch_code AND 1=1

END







ELSE ---IF @pBranchCode IS NOT NULL

BEGIN

DELETE FROM wa_budget_consolidated_report WHERE budget_year = @pYear AND branch_code = @pBranchCode


INSERT INTO wa_budget_consolidated_report 


SELECT Report, report_group, caption, position, A.branch_code, 
		JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, YE_TOTAL, @pYear AS budget_year

FROM

(SELECT DISTINCT branch_code from vw_base_structure WHERE YEAR(structure_date) = @pYear) A

LEFT JOIN

(
/** BALANCE SHEET **/

SELECT DISTINCT 'BALANCE SHEET' AS Report,
				CASE WHEN map.position IN (116, 125, 128, 119, 122, 131, 134, 137) THEN 'ASSET' 
					WHEN map.position IN (206, 224, 236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251, 254) THEN 'LIABILITIES'
					END AS report_group,
				UPPER(map.name) as caption, 
				--map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				--isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				--isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position AS position,
				bs.branch_code,
				bs.month_2_avg + ((@factor*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((@factor*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((@factor*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((@factor*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((@factor*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((@factor*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((@factor*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((@factor*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((@factor*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((@factor*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((@factor*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as YE_TOTAL
--				dapp.budget_--year AS budget_year
				
	FROM mpr_map map
	JOIN (select branch_code, caption, sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate 
	AND map.position IN (116, 125, 128, 119, 122, 131, 134, 137, 206, 224, 236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251, 254)
	AND YEAR(dapp.budget_year) = @pYear
	--AND bs.branch_code = @pBranchCode 
	--ORDER BY branch_code,map.position,map.class)
	) B

               ON A.branch_code = B.branch_code
               WHERE A.branch_code = @pBranchCode

UNION

------------SUBTOTALS----------------------------------------------


SELECT * FROM [dbo].[fn_table_wa_budget_pool_aggregate] (@pYear,@pBranchCode)




UNION

/** INCOME STATEMENT **/

/** INTEREST INCOME & EXPENSE **/
SELECT 'INCOME STATEMENT' AS Report,
		CASE WHEN A.position IN (116, 125, 128, 119, 122, 131, 134, 137) THEN 'INTEREST INCOME' 
				WHEN A.position IN (236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251) THEN 'INTEREST EXPENSE'
				END AS report_group,
		A.caption,
		A.position,
		branch_code,
		SUM(A.JAN * (31/@pNyear) * B.[JAN ]) AS JAN,
		CASE WHEN @pNyear = 365 THEN SUM(A.FEB * (28/@pNyear) * B.FEB) WHEN @pNyear = 366 THEN SUM(A.FEB * (29/@pNyear) * B.FEB) END AS FEB,
		SUM(A.MAR * (31/@pNyear) * B.MAR) AS MAR,
		SUM(A.APR * (30/@pNyear) * B.APR) AS APR,
		SUM(A.MAY * (31/@pNyear) * B.MAY) AS MAY,
		SUM(A.JUN * (30/@pNyear) * B.JUN) AS JUN,
		SUM(A.JUL * (31/@pNyear) * B.JUL) AS JUL,
		SUM(A.AUG * (31/@pNyear) * B.AUG) AS AUG,
		SUM(A.SEP * (30/@pNyear) * B.SEPT) AS SEP,
		SUM(A.OCT * (31/@pNyear) * B.OCT) AS OCT,
		SUM(A.NOV * (30/@pNyear) * B.NOV) AS NOV,
		SUM(A.DEC * (31/@pNyear) * B.DEC) AS DEC,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) + 
				(A.MAY  * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL  * (31/@pNyear) * B.JUL) + (A.AUG * (31/@pNyear) * B.AUG) + 
				(A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT  * (31/@pNyear) * B.OCT) + (A.NOV * (30/@pNyear) * B.NOV) + (A.DEC * (31/@pNyear) * B.DEC)) AS YE_TOTAL,
		@pYear as budget_year


FROM

	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((@factor*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((@factor*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((@factor*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((@factor*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((@factor*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((@factor*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((@factor*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((@factor*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((@factor*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((@factor*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((@factor*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC,
				dapp.budget_year
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
	AND YEAR(dapp.budget_year) = @pYear

	--AND bs.branch_code = @pBranchCode
	--ORDER BY branch_code,map.position,map.class
	) A

JOIN wa_budget_rate_assumptions  B
	ON A.position = B.position

WHERE A.position IN (116, 125, 128, 119, 122, 131, 134, 137,	236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251)
GROUP BY A.caption,	branch_code, A.position, A.budget_year 



UNION

/** FEE BASED INCOME **/


	SELECT distinct 'INCOME STATEMENT' AS Report,
		'FEE BASED INCOME' AS report_group,
		income_line AS caption,
		a.position,
		a.branch_code,
		monthly as JAN, monthly as FEB, monthly as MAR, monthly AS APR, monthly as MAY, monthly as JUN, monthly as JUL, monthly as AUG, 
		monthly as SEP, monthly as OCT, monthly as NOV, monthly as DEC, monthly * 12 as ye_total,
		YEAR(a.structure_date) AS budget_year
	FROM
	
	(SELECT DISTINCT branch_code, 'Off Balance Sheet Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			off_balancesheet_fees/12 AS monthly, 607 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'fx income' AS income_line, 'FEE BASED INCOME'  as report, 
			fx_Income/12 AS monthly, 609 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'E-Business income' AS income_line, 'FEE BASED INCOME'  as report, 
			ebusiness_income/12 AS monthly, 610 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Other income' AS income_line, 'FEE BASED INCOME'  as report, 
			other_income/12 AS monthly, 634 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Commisions on Collections' AS income_line, 'FEE BASED INCOME'  as report, 
			com_on_collections/12 AS monthly, 614 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Account Maintenance Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			account_maintenance_fees/12 AS monthly, 603 AS position, structure_date
	FROM wa_budget_commission ) a
	WHERE YEAR(structure_date) = @pYear --AND branch_code = @pBranchCode



	--left join
	--(select branch_code, caption, sum(month_2_avg)as month_2_avg , eod_date 
	--from mpr_bal_sheet_report 
	--where caption in('CBN/BOI LOAN','RETAIL PRODUCT LOAN', 
	--'BUSINESS LOAN','TERM LOANS','OVERDRAFTS','LEASES','WEMA ASSET ACQUISITION SCHEME') 
	--and eod_date = '20220831' 
	--group by branch_code, caption, position,eod_date) b
	--on a.branch_code = b.branch_code
	--where a.structure_date = b.eod_date

UNION



/** Facility Related Fees **/

	SELECT 'INCOME STATEMENT' AS Report,
		'FEE BASED INCOME' AS report_group, 'Facility Related Fees' as caption, 
		NULL AS position, fr.branch_code,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12)) as JAN,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)) as FEB,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12)) as MAR,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)) as APR,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12)) as MAY,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12)) as JUN,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12)) as JUL,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12)) as AUG,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12)) as SEP,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12)) as OCT,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12)) as NOV,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12)) as DEC,

	((sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12)))) AS ye_total,
	@pYear as budget_year
	from
	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((8.333*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((8.333*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((8.333*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((8.333*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((8.333*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((8.333*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((8.333*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((8.333*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((8.333*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((8.333*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((8.333*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((8.333*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position 

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
		--and bs.branch_code = @pBranchCode
		and  map.class = 'ASSET')fR
	join
	(select branch_code,  sum(month_2_avg)as total_start_bal  
	from mpr_bal_sheet_report 
	where caption in('CBN/BOI LOAN','RETAIL PRODUCT LOAN', 
	'BUSINESS LOAN','TERM LOANS','OVERDRAFTS','LEASES','WEMA ASSET ACQUISITION SCHEME') 
	and eod_date = @pDate --and branch_code = @pBranchCode
	group by branch_code)start_bal_total
	on fr.branch_code = start_bal_total.branch_code
	group by total_start_bal, fR.branch_code


UNION

/** OPEX **/


	/** Staff Cost **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'STAFF COST' AS caption,
		NULL AS position,
		b.branch_code, 
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JAN, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS FEB, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS MAR,
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS APR, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS MAY, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JUN,
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JUL, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS AUG, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS SEP,
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS OCT, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS NOV, ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS DEC,
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 12), 0) AS YE_TOTAL,
		@pYear AS budget_year
	FROM wa_budget_comm_staff_cost a
	JOIN 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  b
	ON a.branch_code = b.branch_code AND a.year = YEAR(b.budget_date)
	WHERE a.year = @pYear --AND a.branch_code = @pBranchCode 
	GROUP BY b.branch_code, a.monthly

UNION

	/** Premises Maintenance Expense **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'PREMISES MAINTENANCE EXPENSE' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL,
		SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Premises Maintenance%'
	GROUP BY branch_code

	


UNION

	/** Depreciation **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'DEPRECIATION' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly) AS JAN, SUM(monthly) AS FEB, SUM(monthly) AS MAR, SUM(monthly) AS APR, SUM(monthly) AS MAY, SUM(monthly) AS JUN, 
		SUM(monthly) AS JUL, SUM(monthly) AS AUG, SUM(monthly) AS SEP, SUM(monthly) AS OCT, SUM(monthly) AS NOV, SUM(monthly) AS DEC, 
		SUM(ye_total) AS YE_TOTAL, @pYear AS budget_year
		FROM
		wa_budget_depreciation
		WHERE year = @pYear
		GROUP BY branch_code

	--	SUM(monthly_depr) AS JAN, SUM(monthly_depr) AS FEB, SUM(monthly_depr) AS MAR, SUM(monthly_depr) AS APR, SUM(monthly_depr) AS MAY, SUM(monthly_depr) AS JUN, 
	--	SUM(monthly_depr) AS JUL, SUM(monthly_depr) AS AUG, SUM(monthly_depr) AS SEP, SUM(monthly_depr) AS OCT, SUM(monthly_depr) AS NOV, SUM(monthly_depr) AS DEC, 
	--	SUM(depr_amount) AS YE_TOTAL
	--	--year AS budget_year
	--FROM 
	--(SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_capex_depr
	--UNION
	--SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_HO_capex_depr) a
	--wa_budget_depreciation
	--GROUP BY branch_code

	
UNION

	/** Public Relations and Advert Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'PUBLIC RELATIONS AND ADVERT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year

	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Public Relations and Advert%'
	GROUP BY branch_code


UNION

	/** Communication Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'COMMUNICATION EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Communication%'
	GROUP BY branch_code



UNION

	/** Printing and Stationery Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'PRINTING AND STATIONERY EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly_amort) AS JAN, SUM(monthly_amort) AS FEB, SUM(monthly_amort) AS MAR, SUM(monthly_amort) AS APR, SUM(monthly_amort) AS MAY, SUM(monthly_amort) AS JUN, 
		SUM(monthly_amort) AS JUL, SUM(monthly_amort) AS AUG, SUM(monthly_amort) AS SEP, SUM(monthly_amort) AS OCT, SUM(monthly_amort) AS NOV, SUM(monthly_amort) AS DEC, 
		SUM(total_cost) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 	
	(SELECT branch_code, monthly_amort, total_cost FROM wa_budget_stationery
	UNION
	SELECT branch_code, monthly_amort, total_cost FROM wa_budget_HO_stationery) a
	--JOIN wa_budget_HO_stationery
	GROUP BY branch_code


UNION

	/** Other Business Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'OTHER BUSINESS EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Business%'
	GROUP BY branch_code


UNION

	/** Transport Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'TRANSPORT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Transport%'
	GROUP BY branch_code


UNION

	/** Other Expenses **/

	SELECT 'INCOME STATEMENT' AS Report,
		'OPEX' AS report_group,
		'OTHER EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) AS FEB, SUM(month_year_amount) AS MAR, SUM(month_year_amount) AS APR, SUM(month_year_amount) AS MAY, 
		SUM(month_year_amount) AS JUN, SUM(month_year_amount) AS JUL, SUM(month_year_amount) AS AUG, SUM(month_year_amount) AS SEP, SUM(month_year_amount) AS OCT, 
		SUM(month_year_amount) AS NOV, SUM(month_year_amount) AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Expense%'
	GROUP BY branch_code









UNION

/** INCOME STATEMENT YTD **/

/** INTEREST INCOME & EXPENSE YTD **/
SELECT 'INCOME STATEMENT YTD' AS Report,
		CASE WHEN A.position IN (116, 125, 128, 119, 122, 131, 134, 137) THEN 'INTEREST INCOME YTD' 
				WHEN A.position IN (236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251) THEN 'INTEREST EXPENSE YTD'
				END AS report_group,
		A.caption,
		A.position,
		branch_code,
		SUM(A.JAN * (31/@pNyear) * B.[JAN ]) AS JAN,
		CASE WHEN @pNyear = 365 THEN SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB)) 
					WHEN @pNyear = 366 THEN SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (29/@pNyear) * B.FEB)) END AS FEB,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR)) AS MAR,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR)) AS APR,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY)) AS MAY,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN)) AS JUN,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL)) AS JUL,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG)) AS AUG,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT)) AS SEP,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT * (31/@pNyear) * B.OCT)) AS OCT,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT * (31/@pNyear) * B.OCT) 
				+ (A.NOV * (30/@pNyear) * B.NOV)) AS NOV,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) 
				+ (A.MAY * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL * (31/@pNyear) * B.JUL) 
				+ (A.AUG * (31/@pNyear) * B.AUG) + (A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT * (31/@pNyear) * B.OCT) 
				+ (A.NOV * (30/@pNyear) * B.NOV) + (A.DEC * (31/@pNyear) * B.DEC)) AS DEC,
		SUM((A.JAN * (31/@pNyear) * B.[JAN ]) + (A.FEB * (28/@pNyear) * B.FEB) + (A.MAR * (31/@pNyear) * B.MAR) + (A.APR * (30/@pNyear) * B.APR) + 
				(A.MAY  * (31/@pNyear) * B.MAY) + (A.JUN * (30/@pNyear) * B.JUN) + (A.JUL  * (31/@pNyear) * B.JUL) + (A.AUG * (31/@pNyear) * B.AUG) + 
				(A.SEP * (30/@pNyear) * B.SEPT) + (A.OCT  * (31/@pNyear) * B.OCT) + (A.NOV * (30/@pNyear) * B.NOV) + (A.DEC * (31/@pNyear) * B.DEC)) AS YE_TOTAL,
		@pYear as budget_year



FROM

	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((@factor*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((@factor*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((@factor*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((@factor*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((@factor*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((@factor*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((@factor*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((@factor*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((@factor*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((@factor*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((@factor*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((@factor*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC,
				dapp.budget_year
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
	--AND bs.branch_code = @pBranchCode
	--ORDER BY branch_code,map.position,map.class
	) A

JOIN wa_budget_rate_assumptions  B
	ON A.position = B.position

WHERE A.position IN (116, 125, 128, 119, 122, 131, 134, 137,	236, 239, 209, 221, 218, 203, 233, 227, 230, 245, 242, 251)
GROUP BY A.caption,	branch_code, A.position, A.budget_year



UNION

/** FEE BASED INCOME YTD **/


	SELECT distinct 'INCOME STATEMENT YTD' AS Report,
		'FEE BASED INCOME YTD' AS report_group,
		income_line AS caption,
		a.position,
		a.branch_code,
		monthly as JAN, monthly * 2 as FEB, monthly * 3 as MAR, monthly * 4 AS APR, monthly * 5 as MAY, monthly * 6 as JUN, 
		monthly * 7 as JUL, monthly * 8 as AUG, monthly * 9 as SEP, monthly * 10 as OCT, monthly * 11 as NOV, monthly * 12 as DEC, 
		monthly * 12 as ye_total,
		YEAR(a.structure_date) AS budget_year
	FROM
	
	(SELECT DISTINCT branch_code, 'Off Balance Sheet Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			off_balancesheet_fees/12 AS monthly, 607 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'fx income' AS income_line, 'FEE BASED INCOME'  as report, 
			fx_Income/12 AS monthly, 609 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'E-Business income' AS income_line, 'FEE BASED INCOME'  as report, 
			ebusiness_income/12 AS monthly, 610 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Other income' AS income_line, 'FEE BASED INCOME'  as report, 
			other_income/12 AS monthly, 634 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Commisions on Collections' AS income_line, 'FEE BASED INCOME'  as report, 
			com_on_collections/12 AS monthly, 614 AS position, structure_date
	FROM wa_budget_commission
	UNION
	SELECT DISTINCT branch_code, 'Account Maintenance Fees' AS income_line, 'FEE BASED INCOME'  as report, 
			account_maintenance_fees/12 AS monthly, 603 AS position, structure_date
	FROM wa_budget_commission ) a
	WHERE YEAR(structure_date) = @pYear




UNION


/** Facility Related Fees YTD **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'FEE BASED INCOME YTD' AS report_group, 'Facility Related Fees' as caption, 
		NULL AS position, fr.branch_code,
	sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12)) as JAN,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12))) as FEB,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) as MAR,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12))) as APR,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) as MAY,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) as JUN,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) as JUL,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) as AUG,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) as SEP,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) as OCT,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) as NOV,
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12))) as DEC,

	((sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jan)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(feb)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(mar)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(apr)*0.12)))  +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(may)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUN)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(jUL)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(aug)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(sep)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(oct)*0.12))) +
	(sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(nov)*0.12))) + (sum(jan)-(total_start_bal*0.01)  +(0.05*(sum(dec)*0.12)))) AS ye_total,
	@pYear AS budget_year
	from
	(SELECT DISTINCT UPPER(map.name) as caption,map.class,r.ratio,dapp.deposit_amt,bs.month_2_avg as starting_bal,
				isnull(r.ratio,0)*isnull(dapp.deposit_amt,0) as incremental,
				isnull(bs.month_2_avg,0) + (isnull(r.ratio,0)*isnull(dapp.deposit_amt,0)) as projected_end_bal,
				map.position,bs.branch_code,
				bs.month_2_avg + ((8.333*1/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JAN,
				bs.month_2_avg + ((8.333*2/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as FEB,
				bs.month_2_avg + ((8.333*3/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAR,
				bs.month_2_avg + ((8.333*4/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as APR,
				bs.month_2_avg + ((8.333*5/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as MAY,
				bs.month_2_avg + ((8.333*6/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUN,
				bs.month_2_avg + ((8.333*7/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as JUL,
				bs.month_2_avg + ((8.333*8/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as AUG,
				bs.month_2_avg + ((8.333*9/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as SEP,
				bs.month_2_avg + ((8.333*10/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as OCT,
				bs.month_2_avg + ((8.333*11/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as NOV,
				bs.month_2_avg + ((8.333*12/100)*(isnull(r.ratio,0)*isnull(dapp.deposit_amt,0))) as DEC
				
	FROM mpr_map map
	JOIN (select branch_code,caption,sum(month_2_avg) month_2_avg,position,eod_date
		FROM mpr_bal_sheet_report 
		WHERE eod_date = @pDate
		GROUP BY branch_code,caption,position,eod_date ) bs
	ON map.position = bs.position 

	JOIN (SELECT DISTINCT branch_code, ratio, position 
			FROM mpr_balance_sheet_budget_ratio 
			GROUP BY structure_date, branch_code, ratio, position 
			HAVING structure_date = MAX(structure_date)) r
	ON bs.position = r.position
		AND bs.branch_code = r.branch_code
		--AND EOMONTH(bs.eod_date) = r.structure_date
	
	LEFT JOIN wa_budget_apportion_branch dapp
	on bs.branch_code = dapp.branch_code
		and YEAR(bs.eod_date) = YEAR(dapp.budget_year)

	WHERE bs.eod_date = @pDate
		--and bs.branch_code = @pBranchCode
		and  map.class = 'ASSET')fR
	join
	(select branch_code,  sum(month_2_avg)as total_start_bal  
	from mpr_bal_sheet_report 
	where caption in('CBN/BOI LOAN','RETAIL PRODUCT LOAN', 
	'BUSINESS LOAN','TERM LOANS','OVERDRAFTS','LEASES','WEMA ASSET ACQUISITION SCHEME') 
	and eod_date = @pDate --and branch_code = @pBranchCode
	group by branch_code)start_bal_total
	on fr.branch_code = start_bal_total.branch_code
	group by total_start_bal, fR.branch_code



UNION

/** OPEX **/


	/** Staff Cost **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'STAFF COST' AS caption,
		NULL AS position,
		b.branch_code, 
		ROUND(a.monthly + (SUM(b.total_cost) / 12), 0) AS JAN, ROUND(((a.monthly + (SUM(b.total_cost) / 12) * 2)), 0) AS FEB, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 3), 0) AS MAR, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 4), 0) AS APR, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 5), 0) AS MAY, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 6), 0) AS JUN,
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 7), 0) AS JUL, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 8), 0) AS AUG, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 9), 0) AS SEP, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 10), 0) AS OCT, 
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 11), 0) AS NOV, ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 12), 0) AS DEC,
		ROUND(((a.monthly + (SUM(b.total_cost) / 12)) * 12), 0) AS YE_TOTAL,
		@pYear AS budget_year
	FROM wa_budget_comm_staff_cost a
	JOIN 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  b
	ON a.branch_code = b.branch_code AND a.year = YEAR(b.budget_date)
	--WHERE a.branch_code = @pBranchCode 
	GROUP BY b.branch_code, a.monthly

UNION

	/** Premises Maintenance Expense **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'PREMISES MAINTENANCE EXPENSE' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Premises Maintenance%'
	GROUP BY branch_code

	


UNION

	/** Depreciation **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'DEPRECIATION' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly) AS JAN, SUM(monthly)*2 AS FEB, SUM(monthly)*3 AS MAR, SUM(monthly)*4 AS APR, SUM(monthly)*5 AS MAY, SUM(monthly)*6 AS JUN, 
		SUM(monthly)*7 AS JUL, SUM(monthly)*8 AS AUG, SUM(monthly)*9 AS SEP, SUM(monthly)*10 AS OCT, SUM(monthly)*11 AS NOV, SUM(monthly)*12 AS DEC, 
		SUM(ye_total) AS YE_TOTAL, @pYear AS budget_year
	FROM wa_budget_depreciation
	WHERE year = @pYear
	GROUP BY branch_code

	--	SUM(monthly_depr) AS JAN, SUM(monthly_depr) * 2 AS FEB, SUM(monthly_depr) * 3 AS MAR, SUM(monthly_depr) * 4 AS APR, SUM(monthly_depr) * 5 AS MAY, 
	--	SUM(monthly_depr) * 6 AS JUN, SUM(monthly_depr) * 7 AS JUL, SUM(monthly_depr) * 8 AS AUG, SUM(monthly_depr) * 9 AS SEP, SUM(monthly_depr) * 10 AS OCT, 
	--	SUM(monthly_depr) * 11 AS NOV, SUM(monthly_depr) * 12 AS DEC, SUM(depr_amount) * 12 AS YE_TOTAL
	--	--year AS budget_year
	--FROM 
	--(SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_capex_depr
	--UNION
	--SELECT branch_code, monthly_depr, depr_amount FROM wa_budget_HO_capex_depr) a
	----wa_budget_depreciation
	--GROUP BY branch_code

	
UNION

	/** Public Relations and Advert Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'PUBLIC RELATIONS AND ADVERT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Public Relations and Advert%'
	GROUP BY branch_code


UNION

	/** Communication Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'COMMUNICATION EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 	
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Communication%'
	GROUP BY branch_code



UNION

	/** Printing and Stationery Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'PRINTING AND STATIONARY EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(monthly_amort) AS JAN, SUM(monthly_amort) * 2 AS FEB, SUM(monthly_amort) * 3 AS MAR, SUM(monthly_amort) * 4 AS APR, SUM(monthly_amort) * 5 AS MAY, 
		SUM(monthly_amort) * 6 AS JUN, SUM(monthly_amort) * 7 AS JUL, SUM(monthly_amort) * 8 AS AUG, SUM(monthly_amort) * 9 AS SEP, SUM(monthly_amort) * 10 AS OCT, 
		SUM(monthly_amort) * 11 AS NOV, SUM(monthly_amort) * 12 AS DEC, SUM(monthly_amort) * 12 AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, monthly_amort, total_cost FROM wa_budget_stationery
	UNION
	SELECT branch_code, monthly_amort, total_cost FROM wa_budget_HO_stationery) a
	GROUP BY branch_code


UNION

	/** Other Business Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'OTHER BUSINESS EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Business%'
	GROUP BY branch_code


UNION

	/** Transport Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'TRANSPORT EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Transport%'
	GROUP BY branch_code


UNION

	/** Other Expenses **/

	SELECT 'INCOME STATEMENT YTD' AS Report,
		'OPEX YTD' AS report_group,
		'OTHER EXPENSES' AS caption,
		NULL AS position,
		branch_code, 
		SUM(month_year_amount) AS JAN, SUM(month_year_amount) * 2 AS FEB, SUM(month_year_amount) * 3 AS MAR, SUM(month_year_amount) * 4 AS APR, SUM(month_year_amount) * 5 AS MAY, 
		SUM(month_year_amount) * 6 AS JUN, SUM(month_year_amount) * 7 AS JUL, SUM(month_year_amount) * 8 AS AUG, SUM(month_year_amount) * 9 AS SEP, SUM(month_year_amount) * 10 AS OCT, 
		SUM(month_year_amount) * 11 AS NOV, SUM(month_year_amount) * 12 AS DEC, SUM(base_month) AS YE_TOTAL,
		@pYear AS budget_year
	FROM 
	(SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_opex
	UNION
	SELECT branch_code, category, month_year_amount, base_month FROM wa_budget_HO_opex) a
	WHERE category like '%Other Expense%'
	GROUP BY branch_code
	--) B

--ON A.branch_code = B.branch_code AND 1=1

--WHERE B.branch_code = @pBranchCode --AND B.branch_code = @pBranchCode

END


	










