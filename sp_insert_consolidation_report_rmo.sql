USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_consolidation_report_rmo]    Script Date: 2/28/2023 10:08:02 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_insert_consolidation_report_rmo]
			 @pYear NVARCHAR(10)


AS

DECLARE @pNyear FLOAT
		--@pAccountOfficer NVARCHAR(10)
		


SET @pYear = '2022'
--SET @pAccountOfficer = 'S08697'
SET @pNyear = DATEPART(dy, @pYear +'1231') --number of days in a year



BEGIN

DELETE FROM wa_budget_consolidated_report_rmo WHERE year = @pYear

INSERT INTO wa_budget_consolidated_report_rmo


SELECT staff_id, report, report_group, position, caption, 
		JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, ye_total, @pYear AS year

		
FROM

(

/** BALANCE SHEET **/

select 'BALANCE SHEET' as report, [Report Group] AS report_group ,staff_id, position, caption,
jan, feb, mar, apr, may, jun, jul, aug, sep,
oct, nov, dec, [Y/E_BAL] AS ye_total
from
(select 'ASSET' as 'Report Group', products as caption,staff_id,
position, SUM(jan) as jan, SUM(feb) as feb, SUM(mar) as mar, SUM(apr) as apr, SUM(may) as may, SUM(jun) as jun, SUM(jul) jul, 
SUM(aug) as aug, SUM(sep) as sep, SUM(oct) as oct, SUM(nov) as nov,
SUM(dec) as dec, SUM(dec) as 'Y/E_BAL' 
from  wa_budget_asset_volume
WHERE year = @pYear
GROUP BY staff_id, products, position

union all



(select 'ASSET' as report,'Cash Reserve (Adjustment)' as caption,
staff_id, NULL AS position,
sum(jan)*0.0275 as jan, sum(feb)*0.0275 as feb, sum(mar)*0.275 as mar,
sum(apr)*0.275 as apr,sum(may)*0.0275 as may, sum(jun)*0.0275 as jun,
sum(jul)*0.0275 as jul, sum(aug)*0.0275 as aug, sum(sep) *0.0275 as sep,
sum(oct)*0.0275 as oct,sum(nov)*0.0275 as nov, sum(dec)*0.0275 as dec,
sum(dec)*0.3 as 'Y/E_BAL'
from wa_budget_liab_volume
where liability_product in ('Std Demand Deposit Corp.', 'Std Demand Deposit Ind.',
'Savings Accounts', 'Wema Treasure Account','Wema Target Savings Account',
'Purple','Prestige Current Account', 'Royal','Moment',
'Call Deposits','Domicilliary Accounts','MyBusiness', 'Time Deposit')
AND year = @pYear
group by staff_id)



union all



(select 'ASSET' as report,'Liquidity Position (Adjustment)' as caption,
staff_id, NULL AS position,
sum(jan)*0.3 as jan, sum(feb)*0.3 as feb, sum(mar)*0.275 as mar,
sum(apr)*0.275 as apr, sum(may)*0.3 as may, sum(jun)*0.3 as jun,
sum(jul)*0.3 as jul, sum(aug)*0.3 as aug, sum(sep) *0.3 as sep,
sum(oct)*0.3 as oct, sum(nov)*0.3 as nov, sum(dec)*0.3 as dec,    
sum(dec)*0.3 as 'Y/E_BAL'
from wa_budget_liab_volume
where liability_product in ('Std Demand Deposit Corp.',
'Std Demand Deposit Ind.','Savings Accounts', 'Wema Treasure Account',
'Wema Target Savings Account','Purple','Prestige Current Account',
'Royal','Moment','Call Deposits','Domicilliary Accounts','MyBusiness',
'Time Deposit')
AND year = @pYear 
group by staff_id)



--union all




--(select 'ASSET' as report,'Sub total - uses' as captions,  --come back here
--staff_id, position,
--sum(jan) as jan,                                --group by staff_id, position
--sum(feb) as feb, sum(mar) as mar, sum(apr) as apr,
--sum(may) as may, sum(jun) as jun, sum(jul) as jul,
--sum(aug) as aug, sum(sep) as sep, sum(oct) as oct, sum(nov) as nov,
--sum(dec) as dec, sum([Y/E_BAL]) as 'Y/E_BAL'
--from (
--select 'ASSET' as report, products as captions,
--staff_id, position, SUM(jan) as jan, SUM(feb) as feb, SUM(mar) as mar, SUM(apr) as apr, SUM(may) as may,
--SUM(jun) as jun, SUM(jul) as jul, SUM(aug) as aug, SUM(sep) as sep, SUM(oct) as oct, SUM(nov) as nov, SUM(dec) as dec,
--SUM(dec) as 'Y/E_BAL' 
--from  wa_budget_asset_volume
----WHERE year = @pYear
--GROUP BY staff_id, products, position
--union all



--(select 'ASSET' as report,'Cash Reserve (Adjustment)' as captions,
--staff_id, position,sum(jan)*0.0275 as jan, sum(feb)*0.0275 as feb,
--sum(mar)*0.275 as mar, sum(apr)*0.275 as apr,sum(may)*0.0275 as may,
--sum(jun)*0.0275 as jun, sum(jul)*0.0275 as jul, sum(aug)*0.0275 as aug,
--sum(sep) *0.0275 as sep,
--sum(oct)*0.0275 as oct,sum(nov)*0.0275 as nov, sum(dec)*0.0275 as dec,
--sum(dec)*0.3 as 'Y/E_BAL'
--from wa_budget_liab_volume
--where liability_product in ('Std Demand Deposit Corp.', 'Std Demand Deposit Ind.',
--'Savings Accounts', 'Wema Treasure Account','Wema Target Savings Account','Purple',
--'Prestige Current Account', 'Royal','Moment','Call Deposits','Domicilliary Accounts',
--'MyBusiness', 'Time Deposit')
----AND year =@pYear
--group by staff_id, position))a
--group by staff_id, position )




union all




/*liabilities*/
(select 'LIABLILITY' as report, liability_product as caption,
staff_id, position, SUM(jan), SUM(feb), SUM(mar), SUm(apr), SUM(may), SUM(jun),
SUM(jul), SUM(aug), SUM(sep), SUM(oct), SUM(nov), SUM(dec), SUM(dec) as 'Y/E BAL'
from wa_budget_liab_volume
WHERE year = @pYear
GROUP BY staff_id, liability_product, position



--union all



--(select 'LIABLILITY' as report, 'Sub Total - sources' as caption,
--staff_id, position,sum(jan) as jan, sum(feb) as feb,
--sum(mar) as mar, sum(apr) as apr, sum(may) as may,
--sum(jun) as jun,
--sum(jul) as jul, sum(aug) as aug, sum(sep) as sep,
--sum(oct) as oct,sum(nov) as nov, sum(dec) as dec,
--sum(dec) as 'Y/E BAL'  
--from wa_budget_liab_volume
--WHERE year = @pYear
--group by staff_id, position)
)) a




	UNION

/** PROFIT & LOSS **/

	/** INTEREST INCOME **/

	SELECT 'PROFIT & LOSS' AS report, 'INTEREST INCOME' AS report_group, Z.staff_id, A.position, A.products AS caption, 
			SUM(A.JAN * C.JAN * 31/365) AS JAN, SUM(A.FEB * C.FEB * 28/365) AS FEB, SUM(A.MAR * C.MAR * 31/365) AS MAR,
			SUM(A.APR * C.APR * 30/365) AS APR, SUM(A.MAY * C.MAY * 31/365) AS MAY, SUM(A.JUN * C.JUN * 30/365) AS JUN,
			SUM(A.JUL * C.JUL * 31/365) AS JUL, SUM(A.AUG * C.AUG * 31/365) AS AUG, SUM(A.SEP * C.SEP * 30/365) AS SEP,
			SUM(A.OCT * C.OCT * 31/365) AS OCT, SUM(A.NOV * C.NOV * 30/365) AS NOV, SUM(A.DEC * C.DEC * 31/365) AS DEC,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365) + (A.DEC * C.DEC * 31/365)) AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_asset_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.year = @pYear
	GROUP BY Z.staff_id, A.position, A.products	


	UNION
	/** Interest on cash reserve & liquidity **/
	SELECT 'PROFIT & LOSS' AS report, 'INTEREST INCOME' AS report_group, Z.staff_id, C.position, 'Cash Reserve & Liquidity' AS caption,
			SUM((A.JAN * 0.3) * C.JAN * 31/365) AS JAN, SUM((A.FEB * 0.3) * C.FEB * 28/365) AS FEB, SUM((A.MAR * 0.3) * C.MAR * 31/365) AS MAR,
			SUM((A.APR * 0.3) * C.APR * 30/365) AS APR, SUM((A.MAY * 0.3) * C.MAY * 31/365) AS MAY, SUM((A.JUN * 0.3) * C.JUN * 30/365) AS JUN,
			SUM((A.JUL * 0.3) * C.JUL * 31/365) AS JUL, SUM((A.AUG * 0.3) * C.AUG * 31/365) AS AUG, SUM((A.SEP * 0.3) * C.SEP * 30/365) AS SEP,
			SUM((A.OCT * 0.3) * C.OCT * 31/365) AS OCT, SUM((A.NOV * 0.3) * C.NOV * 30/365) AS NOV, SUM((A.DEC * 0.3) * C.DEC * 31/365) AS DEC,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)  +
			((A.SEP * 0.3) * C.SEP * 31/365) + ((A.OCT * 0.3) * C.OCT * 31/365) + ((A.NOV * 0.3) * C.NOV * 31/365) + ((A.DEC * 0.3) * C.DEC * 31/365)) AS YE_TOTAL

	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON z.staff_id = A.staff_id AND 1=1
	JOIN (SELECT * FROM wa_budget_rate_assumptions_rmo WHERE position = '110') C
	ON A.year = C.year
	WHERE A.year = @pYear
	GROUP BY Z.staff_id, C.position	


	UNION

	/** INTEREST EXPENSE **/

	SELECT 'PROFIT & LOSS' AS report, 'INTEREST EXPENSE' AS report_group, Z.staff_id, C.position, A.liability_product, 
			SUM(A.JAN * C.JAN * 31/365) AS JAN, SUM(A.FEB * C.FEB * 28/365) AS FEB, SUM(A.MAR * C.MAR * 31/365) AS MAR,
			SUM(A.APR * C.APR * 30/365) AS APR, SUM(A.MAY * C.MAY * 31/365) AS MAY, SUM(A.JUN * C.JUN * 30/365) AS JUN,
			SUM(A.JUL * C.JUL * 31/365) AS JUL, SUM(A.AUG * C.AUG * 31/365) AS AUG, SUM(A.SEP * C.SEP * 30/365) AS SEP,
			SUM(A.OCT * C.OCT * 31/365) AS OCT, SUM(A.NOV * C.NOV * 30/365) AS NOV, SUM(A.DEC * C.DEC * 31/365) AS DEC,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365) + (A.DEC * C.DEC * 31/365)) AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.position IN ('239', '209', '227', '242', '245') AND A.year = @pYear
	GROUP BY Z.staff_id, C.position, A.liability_product	


	UNION

	/** Interest on Demand Deposits Corporate **/
		SELECT 'PROFIT & LOSS' AS report, 'INTEREST EXPENSE' AS report_group, Z.staff_id, C.position, A.liability_product, 
			SUM(A.JAN * 0.45 * C.JAN * 31/365) AS JAN, SUM(A.FEB * 0.45 *  C.FEB * 28/365) AS FEB, SUM(A.MAR * 0.45 *  C.MAR * 31/365) AS MAR,
			SUM(A.APR * 0.45 *  C.APR * 30/365) AS APR, SUM(A.MAY * 0.45 *  C.MAY * 31/365) AS MAY, SUM(A.JUN * 0.45 *  C.JUN * 30/365) AS JUN,
			SUM(A.JUL * 0.45 *  C.JUL * 31/365) AS JUL, SUM(A.AUG * 0.45 *  C.AUG * 31/365) AS AUG, SUM(A.SEP * 0.45 *  C.SEP * 30/365) AS SEP,
			SUM(A.OCT * 0.45 *  C.OCT * 31/365) AS OCT, SUM(A.NOV * 0.45 *  C.NOV * 30/365) AS NOV, SUM(A.DEC * 0.45 *  C.DEC * 31/365) AS DEC,
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) +
			(A.SEP * 0.45 *  C.SEP * 30/365) + (A.OCT * 0.45 *  C.OCT * 31/365) + (A.NOV * 0.45 *  C.NOV * 30/365) + (A.DEC * 0.45 *  C.DEC * 31/365)) AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.position = '236' AND C.position = '236' AND A.year = @pYear
	GROUP BY Z.staff_id, C.position, A.liability_product


	UNION

	/** Fee Based Revenue **/
		/** Commission and Fees **/

	SELECT 'PROFIT & LOSS' AS report, 'FEE BASED REVENUE' AS report_group, A.staff_id, NULL AS position, 'Commision and Fees' AS caption,  
			(A.JAN + B.JAN) AS JAN, (A.FEB + B.FEB) AS FEB, (A.MAR + B.MAR) AS MAR, (A.APR + B.APR) AS APR, (A.MAY + B.MAY) AS MAY, 
			(A.JUN + B.JUN) AS JUN, (A.JUL + B.JUL) AS JUL, (A.AUG + B.AUG) AS AUG, (A.SEP + B.SEP) AS SEP, (A.OCT + B.OCT) AS OCT, 
			(A.NOV + B.NOV) AS NOV, (A.DEC + B.DEC) AS DEC, ((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) +
			(A.JUN + B.JUN) + (A.JUL + B.JUL) + (A.AUG + B.AUG) + (A.SEP + B.SEP) + (A.OCT + B.OCT) + (A.NOV + B.NOV) +  (A.DEC + B.DEC)) AS YE_TOTAL
	FROM
	(SELECT Z.staff_id,	SUM((A.JAN * C.JAN * 31/365) * 0.25) * 0.05 AS JAN, SUM((A.FEB * C.FEB * 28/365) * 0.25) * 0.05 AS FEB, 
			SUM((A.MAR * C.MAR * 31/365) * 0.25) * 0.05 AS MAR, SUM((A.APR * C.APR * 30/365) * 0.25) * 0.05 AS APR, 
			SUM((A.MAY * C.MAY * 31/365) * 0.25) * 0.05 AS MAY, SUM((A.JUN * C.JUN * 30/365) * 0.25) * 0.05 AS JUN,
			SUM((A.JUL * C.JUL * 31/365) * 0.25) * 0.05 AS JUL, SUM((A.AUG * C.AUG * 31/365) * 0.25) * 0.05 AS AUG, 
			SUM((A.SEP * C.SEP * 30/365) * 0.25) * 0.05 AS SEP, SUM((A.OCT * C.OCT * 31/365) * 0.25) * 0.05 AS OCT, 
			SUM((A.NOV * C.NOV * 30/365) * 0.25) * 0.05 AS NOV, SUM((A.DEC * C.DEC * 31/365) * 0.25) * 0.05 AS DEC
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.position IN ('236', '239') AND A.year = @pYear
	GROUP BY Z.staff_id ) A

	JOIN
	(SELECT staff_id, (SUM(JAN) - AVG(closing_bal)) * 0.01 AS JAN, (SUM(FEB) - AVG(closing_bal)) * 0.01 AS FEB, (SUM(MAR) - AVG(closing_bal)) * 0.01 AS MAR,
			(SUM(APR) - AVG(closing_bal)) * 0.01 AS APR, (SUM(MAY) - AVG(closing_bal)) * 0.01 AS MAY, (SUM(JUN) - AVG(closing_bal)) * 0.01 AS JUN,
			(SUM(JUL) - AVG(closing_bal)) * 0.01 AS JUL, (SUM(AUG) - AVG(closing_bal)) * 0.01 AS AUG, (SUM(SEP) - AVG(closing_bal)) * 0.01 AS SEP,
			(SUM(OCT) - AVG(closing_bal)) * 0.01 AS OCT, (SUM(NOV) - AVG(closing_bal)) * 0.01 AS NOV, (SUM(DEC) - AVG(closing_bal)) * 0.01 AS DEC
	FROM wa_budget_asset_volume 
	GROUP BY staff_id) B
	ON A.staff_id = B.staff_id


	UNION


	/** Staff Costs **/

	SELECT 'PROFIT & LOSS' AS report, 'EXPENSES' AS report_group, z.staff_id, NULL AS position, 'Staff Costs' AS caption,
			b.monthly AS JAN, b.monthly AS FEB, b.monthly AS MAR, b.monthly AS APR, b.monthly AS MAY, b.monthly AS JUN, b.monthly AS JUl,
			b.monthly AS AUG, b.monthly AS SEP, b.monthly AS OCT, b.monthly AS NOV, b.monthly AS DEC, b.monthly * 12 AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN 
	wa_budget_non_financial a
	ON Z.staff_id = a.StaffId
	JOIN wa_budget_salary b
	ON a.staff_grade = b.staff_grade
	WHERE  A.year = @pYear




	UNION

/** PROFIT & LOSS CONSOLIDATION**/


	/** INTEREST INCOME **/

	SELECT 'PROFIT & LOSS CONSOLIDATION' AS report, 'INTEREST INCOME' AS report_group, Z.staff_id, A.position, A.products AS caption, 
			SUM(A.JAN * C.JAN * 31/365) AS JAN, SUM((A.FEB * C.FEB * 28/365) + (A.JAN * C.JAN * 31/365)) AS FEB, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365)) AS MAR,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365)) AS APR, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) + (A.MAY * C.MAY * 31/365)) AS MAY, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365)) AS JUN,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365)) AS JUL, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365)) AS AUG, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365)) AS SEP,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365)) AS OCT, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365)) AS NOV, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365) + (A.DEC * C.DEC * 31/365)) AS DEC,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365) + (A.DEC * C.DEC * 31/365)) AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_asset_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.year = @pYear
	GROUP BY Z.staff_id, A.position, A.products	


	UNION
	/** Interest on cash reserve & liquidity **/
	SELECT 'PROFIT & LOSS CONSOLIDATION' AS report, 'INTEREST INCOME' AS report_group, Z.staff_id, C.position, 'Cash Reserve & Liquidity' AS caption,
			SUM((A.JAN * 0.3) * C.JAN * 31/365) AS JAN, SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365)) AS FEB, 
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365)) AS MAR,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)) AS APR, 
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365)) AS MAY, 
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365)) AS JUN,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365)) AS JUL, 
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)) AS AUG, 
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)  +
			((A.SEP * 0.3) * C.SEP * 31/365)) AS SEP,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)  +
			((A.SEP * 0.3) * C.SEP * 31/365) + ((A.OCT * 0.3) * C.OCT * 31/365)) AS OCT,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365) + 
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)  +
			((A.SEP * 0.3) * C.SEP * 31/365) + ((A.OCT * 0.3) * C.OCT * 31/365) + ((A.NOV * 0.3)  * C.NOV * 31/365)) AS NOV,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)  +
			((A.SEP * 0.3) * C.SEP * 31/365) + ((A.OCT * 0.3) * C.OCT * 31/365) + ((A.NOV * 0.3) * C.NOV * 31/365) +  ((A.DEC * 0.3) * C.DEC * 31/365)) AS DEC,
			SUM(((A.JAN * 0.3) * C.JAN * 31/365) + ((A.FEB * 0.3) * C.FEB * 28/365) + ((A.MAR * 0.3) * C.MAR * 31/365) + ((A.APR * 0.3) * C.APR * 30/365)+
			((A.MAY * 0.3) * C.MAY * 31/365) + ((A.JUN * 0.3) * C.JUN * 30/365) + ((A.JUL * 0.3) * C.JUL * 31/365) + ((A.AUG * 0.3) * C.AUG * 31/365)  +
			((A.SEP * 0.3) * C.SEP * 31/365) + ((A.OCT * 0.3) * C.OCT * 31/365) + ((A.NOV * 0.3) * C.NOV * 31/365) +  ((A.DEC * 0.3) * C.DEC * 31/365)) AS YE_TOTAL

	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON z.staff_id = A.staff_id AND 1=1
	JOIN (SELECT * FROM wa_budget_rate_assumptions_rmo WHERE position = '110') C
	ON A.year = C.year
	WHERE A.year = @pYear
	GROUP BY Z.staff_id, C.position	


	UNION

	/** INTEREST EXPENSE **/

	SELECT 'PROFIT & LOSS CONSOLIDATION' AS report, 'INTEREST EXPENSE' AS report_group, Z.staff_id, C.position, A.liability_product, 
			SUM(A.JAN * C.JAN * 31/365) AS JAN, SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365)) AS FEB, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365)) AS MAR,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365)) AS APR, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) + (A.MAY * C.MAY * 31/365)) AS MAY, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365)) AS JUN,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365)) AS JUL, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365)) AS AUG, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) + (A.SEP * C.SEP * 30/365)) AS SEP,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365)) AS OCT, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365)) AS NOV, 
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365) + (A.DEC * C.DEC * 31/365)) AS DEC,
			SUM((A.JAN * C.JAN * 31/365) + (A.FEB * C.FEB * 28/365) + (A.MAR * C.MAR * 31/365) + (A.APR * C.APR * 30/365) +
			(A.MAY * C.MAY * 31/365) + (A.JUN * C.JUN * 30/365) + (A.JUL * C.JUL * 31/365) + (A.AUG * C.AUG * 31/365) +
			(A.SEP * C.SEP * 30/365) + (A.OCT * C.OCT * 31/365) + (A.NOV * C.NOV * 30/365) + (A.DEC * C.DEC * 31/365)) AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.position IN ('239', '209', '227', '242', '245') AND A.year = @pYear
	GROUP BY Z.staff_id, C.position, A.liability_product	


	UNION

	/** Interest on Demand Deposits Corporate **/
		SELECT 'PROFIT & LOSS CONSOLIDATION' AS report, 'INTEREST EXPENSE' AS report_group, Z.staff_id, C.position, A.liability_product, 
			SUM(A.JAN * 0.45 * C.JAN * 31/365) AS JAN, SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365)) AS FEB, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365)) AS MAR,
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365)) AS APR, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365)) AS MAY, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365)) AS JUN,
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365)) AS JUL, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) ) AS AUG, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) +
			(A.SEP * 0.45 *  C.SEP * 30/365)) AS SEP,
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) +
			(A.SEP * 0.45 *  C.SEP * 30/365) + (A.OCT * 0.45 *  C.OCT * 31/365)) AS OCT, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) +
			(A.SEP * 0.45 *  C.SEP * 30/365) + (A.OCT * 0.45 *  C.OCT * 31/365) + (A.NOV * 0.45 *  C.NOV * 30/365)) AS NOV, 
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) +
			(A.SEP * 0.45 *  C.SEP * 30/365) + (A.OCT * 0.45 *  C.OCT * 31/365) + (A.NOV * 0.45 *  C.NOV * 30/365) + (A.DEC * 0.45 *  C.DEC * 31/365)) AS DEC,
			SUM((A.JAN * 0.45 *  C.JAN * 31/365) + (A.FEB * 0.45 *  C.FEB * 28/365) + (A.MAR * 0.45 *  C.MAR * 31/365) + (A.APR * 0.45 *  C.APR * 30/365) +
			(A.MAY * 0.45 *  C.MAY * 31/365) + (A.JUN * 0.45 *  C.JUN * 30/365) + (A.JUL * 0.45 *  C.JUL * 31/365) + (A.AUG * 0.45 *  C.AUG * 31/365) +
			(A.SEP * 0.45 *  C.SEP * 30/365) + (A.OCT * 0.45 *  C.OCT * 31/365) + (A.NOV * 0.45 *  C.NOV * 30/365) + (A.DEC * 0.45 *  C.DEC * 31/365)) AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.position = '236' AND C.position = '236' AND A.year = @pYear
	GROUP BY Z.staff_id, C.position, A.liability_product


	UNION

	/** Fee Based Revenue **/
		/** Commission and Fees **/

	SELECT 'PROFIT & LOSS CONSOLIDATION' AS report, 'FEE BASED REVENUE' AS report_group, A.staff_id, NULL AS position, 'Commision and Fees' AS caption,  
			SUM(A.JAN + B.JAN) AS JAN, SUM((A.JAN + B.JAN) + (A.FEB + B.FEB)) AS FEB, SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR)) AS MAR, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR)) AS APR, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY)) AS MAY, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN)) AS JUN, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL)) AS JUL, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL) + 
				(A.AUG + B.AUG)) AS AUG, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL) + 
				(A.AUG + B.AUG) + (A.SEP + B.SEP)) AS SEP, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL) + 
				(A.AUG + B.AUG) + (A.SEP + B.SEP) + (A.OCT + B.OCT)) AS OCT, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL) + 
				(A.AUG + B.AUG) + (A.SEP + B.SEP) + (A.OCT + B.OCT) + (A.NOV + B.NOV)) AS NOV, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL) + 
				(A.AUG + B.AUG) + (A.SEP + B.SEP) + (A.OCT + B.OCT) + (A.NOV + B.NOV) +  (A.DEC + B.DEC)) AS DEC, 
			SUM((A.JAN + B.JAN) + (A.FEB + B.FEB) + (A.MAR + B.MAR) + (A.APR + B.APR) + (A.MAY + B.MAY) + (A.JUN + B.JUN) + (A.JUL + B.JUL) + 
				(A.AUG + B.AUG) + (A.SEP + B.SEP) + (A.OCT + B.OCT) + (A.NOV + B.NOV) +  (A.DEC + B.DEC)) AS YE_TOTAL
	FROM
	(SELECT Z.staff_id,	SUM((A.JAN * C.JAN * 31/365) * 0.25) * 0.05 AS JAN, SUM((A.FEB * C.FEB * 28/365) * 0.25) * 0.05 AS FEB, 
			SUM((A.MAR * C.MAR * 31/365) * 0.25) * 0.05 AS MAR, SUM((A.APR * C.APR * 30/365) * 0.25) * 0.05 AS APR, 
			SUM((A.MAY * C.MAY * 31/365) * 0.25) * 0.05 AS MAY, SUM((A.JUN * C.JUN * 30/365) * 0.25) * 0.05 AS JUN,
			SUM((A.JUL * C.JUL * 31/365) * 0.25) * 0.05 AS JUL, SUM((A.AUG * C.AUG * 31/365) * 0.25) * 0.05 AS AUG, 
			SUM((A.SEP * C.SEP * 30/365) * 0.25) * 0.05 AS SEP, SUM((A.OCT * C.OCT * 31/365) * 0.25) * 0.05 AS OCT, 
			SUM((A.NOV * C.NOV * 30/365) * 0.25) * 0.05 AS NOV, SUM((A.DEC * C.DEC * 31/365) * 0.25) * 0.05 AS DEC
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN wa_budget_liab_volume A
	ON Z.staff_id = A.staff_id AND 1=1
	JOIN wa_budget_rate_assumptions_rmo C
	ON A.position = C.position
	WHERE A.position IN ('236', '239') AND A.year = @pYear
	GROUP BY Z.staff_id ) A

	JOIN
	(SELECT staff_id, (SUM(JAN) - AVG(closing_bal)) * 0.01 AS JAN, (SUM(FEB) - AVG(closing_bal)) * 0.01 AS FEB, (SUM(MAR) - AVG(closing_bal)) * 0.01 AS MAR,
			(SUM(APR) - AVG(closing_bal)) * 0.01 AS APR, (SUM(MAY) - AVG(closing_bal)) * 0.01 AS MAY, (SUM(JUN) - AVG(closing_bal)) * 0.01 AS JUN,
			(SUM(JUL) - AVG(closing_bal)) * 0.01 AS JUL, (SUM(AUG) - AVG(closing_bal)) * 0.01 AS AUG, (SUM(SEP) - AVG(closing_bal)) * 0.01 AS SEP,
			(SUM(OCT) - AVG(closing_bal)) * 0.01 AS OCT, (SUM(NOV) - AVG(closing_bal)) * 0.01 AS NOV, (SUM(DEC) - AVG(closing_bal)) * 0.01 AS DEC
	FROM wa_budget_asset_volume
	WHERE year = @pYear
	GROUP BY staff_id) B
	ON A.staff_id = B.staff_id
	GROUP BY A.staff_id


	UNION


	/** Staff Costs **/

	SELECT 'PROFIT & LOSS CONSOLIDATION' AS report, 'EXPENSES' AS report_group, z.staff_id, NULL AS position, 'Staff Costs' AS caption,
			SUM(b.monthly) AS JAN, SUM(b.monthly) * 2 AS FEB, SUM(b.monthly) * 3 AS MAR, SUM(b.monthly) * 4 AS APR, SUM(b.monthly) * 5 AS MAY, 
			SUM(b.monthly) * 6 AS JUN, SUM(b.monthly) * 7 AS JUL, SUM(b.monthly) * 8 AS AUG, SUM(b.monthly) * 9 AS SEP, SUM(b.monthly) * 10 AS OCT, 
			SUM(b.monthly) * 11 AS NOV, SUM(b.monthly) * 12 AS DEC, SUM(b.monthly) * 12 AS YE_TOTAL
	FROM (SELECT DISTINCT staff_id from account_officers WHERE YEAR(structure_date) = @pYear AND staff_type = 'RMO') Z
	JOIN 
	wa_budget_non_financial a
	ON Z.staff_id = a.StaffId
	JOIN wa_budget_salary b
	ON a.staff_grade = b.staff_grade
	WHERE A.year = @pYear
	GROUP BY z.staff_id


) A

END