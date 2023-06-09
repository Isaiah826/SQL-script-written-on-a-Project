USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_budget_certificate]    Script Date: 2/21/2023 10:38:03 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_budget_certificate]
		@pDirectorateCode NVARCHAR(10),
		@pRegionCode NVARCHAR(10),
		@pZoneCode NVARCHAR(10),
		@pBranchCode NVARCHAR(10),
		@pYear NVARCHAR(10)
		
		
		
		

--SET @pYear = '2022'
--SET @pBranchCode = '001'


AS

DECLARE @pNyear FLOAT
SET @pNyear = DATEPART(dy, @pYear +'1231')

IF @pBranchCode IS NOT NULL

BEGIN

/** Balance sheet size **/
	SELECT A.branch_code, '2022 Budget' AS cert_group, 1 AS caption_id, 'Balance sheet size' AS caption, 
			(A.Liabilities + B.pool_sources) AS val, NULL AS perc
	FROM (SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode	GROUP BY budget_year, branch_code) A
	JOIN
	(SELECT a.branch_code, CASE WHEN b.Liabilities > a.Asset THEN 0 ELSE (a.Asset - b.liabilities) END AS pool_sources, a.budget_year 
	FROM 
	(SELECT  branch_code, SUM(ye_total) AS Asset, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b
	ON a.branch_code = b.branch_code	) B

	ON A.branch_code = B.branch_code  AND A.budget_year = B.budget_year
	WHERE A.branch_code = @pBranchCode AND A.budget_year = @pYear


UNION

/** CASA Deposits **/
	SELECT  A.branch_code, '2022 Budget' AS cert_group, 2 AS caption_id, 'CASA Deposits' AS caption, 
			a.casa_deposits AS val, ROUND(((100* a.casa_deposits) / b.total_deposits), 0) AS perc 
	FROM
	(SELECT branch_code, SUM(ye_total) AS casa_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON a.branch_code = b.branch_code AND a.budget_year = b.budget_year
	

UNION

/** Tenured Deposits **/
	SELECT  A.branch_code, '2022 Budget' AS cert_group, 3 AS caption_id, 'Tenured Deposits' AS caption, 
			a.tenured_deposits AS val, ROUND(((100* a.tenured_deposits) / b.total_deposits), 0) AS perc 
	FROM
	(SELECT branch_code, SUM(ye_total) AS tenured_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('206', '245', '242')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON a.branch_code = b.branch_code AND a.budget_year = b.budget_year


UNION


/** Total Deposits **/

	SELECT branch_code, '2022 Budget' AS cert_group, 4 AS caption_id, 'Total Deposits' AS caption, 
			SUM(ye_total) AS val, 100 AS perc 
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code 


UNION

/** Loans and Advances **/

	SELECT branch_code, '2022 Budget' AS cert_group, 5 AS caption_id, 'Loans and Advances' AS caption, 
			SUM(ye_total) AS val, NULL AS perc 
	FROM wa_budget_consolidated_report
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code 



UNION

/** Loan Deposit Ratio (LDR) **/

	SELECT a.branch_code, '2022 Budget' AS cert_group, 6 AS caption_id, 'Loan Deposit Ratio (LDR)' AS caption, 
			ROUND(((100* a.val) / b.val), 0) AS val, NULL AS perc  
	FROM
	(SELECT branch_code, SUM(ye_total) AS val, budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val,budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON a.branch_code = b.branch_code  AND a.budget_year = b.budget_year



UNION

/** Interest Income **/

	SELECT  branch_code, 'Income Statement' AS cert_group, 7 AS caption_id, 'Interest Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST INCOME YTD'AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY branch_code



UNION

/** Interest Expense **/

	SELECT  branch_code, 'Income Statement' AS cert_group, 8 AS caption_id, 'Interest Expense' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE YTD' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code


UNION

/** Fee Based Income **/


	SELECT  branch_code, 'Income Statement' AS cert_group, 9 AS caption_id, 'Fee Based Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'FEE BASED INCOME YTD' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code


UNION

/** OPEX **/

	SELECT  branch_code, 'Income Statement' AS cert_group, 10 AS caption_id, 'OPEX' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'OPEX YTD' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code


UNION


/** Cost of Fund **/

	SELECT  a.branch_code, 'Income Statement' AS cert_group, 11 AS caption_id, 'Cost of Fund' AS caption, 
			ROUND(((100 * a.tot_interest_expense) / b.tot_deposits), 0) AS val, NULL AS perc  
	FROM 	
	(SELECT  branch_code, SUM(DEC) * 12 AS tot_interest_expense  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	JOIN
	(SELECT branch_code, SUM(DEC) AS tot_deposits
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224', '251', '206', '245', '242')
		AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON a.branch_code = b.branch_code



UNION


/**===============================================================================**/
/** PBT **/
	
	SELECT c.branch_code, 'Income Statement' AS cert_group, 12 AS caption_id, 'PBT' AS caption, 
			(c.YE_TOTAL - ho.YE_TOTAL) AS val, NULL AS perc  
				 
	FROM

	(SELECT branch_code, monthly AS JAN, monthly * 2 AS FEB, monthly * 3 AS MAR, monthly * 4 AS APR, monthly * 5 AS MAY, monthly * 6 AS JUN,
				monthly * 7 AS JUL, monthly * 8 AS AUG, monthly * 9 AS SEP, monthly * 10 AS OCT, monthly * 11 AS NOV, monthly * 12 AS DEC,
				monthly * 12 AS YE_TOTAL
	FROM wa_budget_head_office 
	WHERE branch_code = @pBranchCode AND budget_date = @pYear) ho /** Head Office Expense **/

	JOIN
	/** Contribution **/
	(SELECT r.branch_code, (r.JAN - o.JAN) AS JAN, (r.FEB - o.FEB) AS FEB, (r.MAR - o.MAR) AS MAR, (r.APR - o.APR) AS APR,
			(r.MAY - o.MAY) AS MAY, (r.JUN - o.JUN) AS JUN, (r.JUL - o.JUL) AS JUL, (r.AUG - o.AUG) AS AUG, (r.SEP - o.SEP) AS SEP,
			(r.OCT - o.OCT) AS OCT, (r.NOV - o.NOV) AS NOV, (r.DEC - o.DEC) AS DEC, (r.YE_TOTAL - o.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'OPEX YTD'AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY branch_code ) o		/** OPEX YTD **/
	JOIN

	/** Total Revenue **/
	(SELECT nr.branch_code, (nr.JAN + fbi.JAN) AS JAN, (nr.FEB + fbi.FEB) AS FEB, (nr.MAR + fbi.MAR) AS MAR, (nr.APR + fbi.APR) AS APR,
			(nr.MAY + fbi.MAY) AS MAY, (nr.JUN + fbi.JUN) AS JUN, (nr.JUL + fbi.JUL) AS JUL, (nr.AUG + fbi.AUG) AS AUG, 
			(nr.SEP + fbi.SEP) AS SEP, (nr.OCT + fbi.OCT) AS OCT, (nr.NOV + fbi.NOV) AS NOV, (nr.DEC + fbi.DEC) AS DEC,
			(nr.YE_TOTAL + fbi.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'FEE BASED INCOME YTD'AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY branch_code ) fbi		/** Fee Based Income YTD **/

	JOIN

	/** Net Revenue from Funds **/
	(SELECT p.branch_code, (II.JAN + p.JAN - IE.JAN - ll.JAN) AS JAN, (II.FEB + p.FEB - IE.FEB - ll.FEB) AS FEB, (II.MAR + p.MAR - IE.MAR - ll.MAR) AS MAR,
			(II.APR + p.APR - IE.APR - ll.APR) AS APR, (II.MAY + p.MAY - IE.MAY - ll.MAY) AS MAY, (II.JUN + p.JUN - IE.JUN - ll.JUN) AS JUN,
			(II.JUL + p.JUL - IE.JUL - ll.JUL) AS JUL, (II.AUG + p.AUG - IE.AUG - ll.AUG) AS AUG, (II.SEP + p.SEP - IE.SEP - ll.SEP) AS SEP,
			(II.OCT + p.OCT - IE.OCT - ll.OCT) AS OCT, (II.NOV + p.NOV - IE.NOV - ll.NOV) AS NOV, (II.DEC + p.DEC - IE.DEC - ll.DEC) AS DEC,
			(II.YE_TOTAL + p.YE_TOTAL - IE.YE_TOTAL - ll.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST INCOME YTD'AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY branch_code ) II /** Interest Income YTD **/
	JOIN
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE YTD'AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY branch_code ) IE /** Interest Expense YTD **/
	ON II.branch_code = IE.branch_code

	JOIN
	/** Loan Loss Expense **/
	(SELECT branch_code, loan_loss_budget AS JAN, loan_loss_budget * 2 AS FEB, loan_loss_budget * 3 AS MAR, loan_loss_budget * 4 AS APR,
					loan_loss_budget * 5 AS MAY, loan_loss_budget * 6 AS JUN, loan_loss_budget * 7 AS JUL, loan_loss_budget * 8 AS AUG,
					loan_loss_budget * 9 AS SEP, loan_loss_budget * 10 AS OCT, loan_loss_budget * 11 AS NOV,
					loan_loss_budget * 12 AS DEC, loan_loss_budget * 12 AS YE_TOTAL
	FROM wa_budget_loan_loss
	WHERE branch_code = @pBranchCode AND YEAR(budget_date) = @pYear) ll
	ON IE.branch_code = ll.branch_code

	JOIN
	/** Pool Credit - Income Statement YTD **/
	(SELECT pc.branch_code, (pc.JAN) AS JAN, (pc.JAN + pc.FEB) AS FEB, (pc.JAN + pc.FEB + pc.MAR) AS MAR, (pc.JAN + pc.FEB + pc.MAR + pc.APR) AS APR, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY) AS MAY, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN) AS JUN, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL) AS JUL, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG) AS AUG, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP) AS SEP, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT) AS OCT,
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV) AS NOV, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS DEC, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS YE_TOTAL
	FROM

	/** Pool Credit **/
	(SELECT branch_code, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, 
			(JAN + FEB + MAR + APR + MAY + JUN + JUL + AUG + SEP + OCT + NOV + DEC) AS YE_TOTAL
	FROM
	(SELECT pu.branch_code, 
			CASE WHEN pu.JAN > 0 THEN (pu.JAN * r.JAN * 31/@pNyear) ELSE (ps.JAN * r2.JAN * 31/@pNyear) END AS JAN,
			CASE WHEN pu.FEB > 0 THEN (pu.FEB * r.FEB * 28/@pNyear) ELSE (ps.FEB * r2.FEB * 28/@pNyear) END AS FEB,
			CASE WHEN pu.MAR > 0 THEN (pu.MAR * r.MAR * 31/@pNyear) ELSE (ps.MAR * r2.MAR * 31/@pNyear) END AS MAR,
			CASE WHEN pu.APR > 0 THEN (pu.APR * r.APR * 30/@pNyear) ELSE (ps.APR * r2.APR * 30/@pNyear) END AS APR,
			CASE WHEN pu.MAY > 0 THEN (pu.MAY * r.MAY * 31/@pNyear) ELSE (ps.MAY * r2.MAY * 31/@pNyear) END AS MAY,
			CASE WHEN pu.JUN > 0 THEN (pu.JUN * r.JUN * 30/@pNyear) ELSE (ps.JUN * r2.JUN * 30/@pNyear) END AS JUN,
			CASE WHEN pu.JUL > 0 THEN (pu.JUL * r.JUL * 31/@pNyear) ELSE (ps.JUL * r2.JUL * 31/@pNyear) END AS JUL,
			CASE WHEN pu.AUG > 0 THEN (pu.AUG * r.AUG * 31/@pNyear) ELSE (ps.AUG * r.AUG * 31/@pNyear) END AS AUG,
			CASE WHEN pu.SEP > 0 THEN (pu.SEP * r.SEPT * 30/@pNyear) ELSE (ps.SEP * r2.SEPT * 30/@pNyear) END AS SEP,
			CASE WHEN pu.OCT > 0 THEN (pu.OCT * r.OCT * 31/@pNyear) ELSE (ps.OCT * r2.OCT * 31/@pNyear) END AS OCT,
			CASE WHEN pu.NOV > 0 THEN (pu.NOV * r.NOV * 30/@pNyear) ELSE (ps.NOV * r2.NOV * 30/@pNyear) END AS NOV,
			CASE WHEN pu.DEC > 0 THEN (pu.DEC * r.DEC * 31/@pNyear) ELSE (ps.DEC * r2.DEC * 31/@pNyear) END AS DEC

	FROM

	/** Pool Uses **/
	(SELECT a.branch_code, 
			(CASE WHEN a.JAN > b.JAN THEN 0 ELSE b.JAN - a.JAN END  ) AS JAN, 
			(CASE WHEN a.FEB > b.FEB THEN 0 ELSE b.FEB - a.FEB END ) AS FEB, 
			(CASE WHEN a.MAR > b.MAR THEN 0 ELSE b.MAR - a.MAR END ) AS MAR, 
			(CASE WHEN a.APR > b.APR THEN 0 ELSE b.APR - a.APR END) AS APR,
			(CASE WHEN a.MAY > b.MAY THEN 0 ELSE b.MAY - a.MAY END) AS MAY, 
			(CASE WHEN a.JUN > b.JUN THEN 0 ELSE b.JUN - a.JUN END) AS JUN,
			(CASE WHEN a.JUL > b.JUL THEN 0 ELSE b.JUL - a.JUL END) AS JUL,
			(CASE WHEN a.AUG > b.AUG THEN 0 ELSE b.AUG - a.AUG END) AS AUG,
			(CASE WHEN a.SEP > b.SEP THEN 0 ELSE b.SEP - a.SEP END) AS SEP, 
			(CASE WHEN a.OCT > b.OCT THEN 0 ELSE b.OCT - a.OCT END) AS OCT,
			(CASE WHEN a.NOV > b.NOV THEN 0 ELSE b.NOV - a.NOV END) AS NOV,
			(CASE WHEN a.DEC > b.DEC THEN 0 ELSE b.DEC - a.DEC END) AS DEC,
			(CASE WHEN a.YE_TOTAL > b.YE_TOTAL THEN 0 ELSE b.YE_TOTAL - a.YE_TOTAL END) AS YE_TOTAL,
			budget_year
	FROM
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL, budget_year  
			FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a /** ASSET **/
	JOIN
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL 
	FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b /** LIABILITIES **/
	ON a.branch_code = b.branch_code	) pu	
	JOIN

	----------Pool Sources-----------
	(SELECT a.branch_code, 
			(CASE WHEN b.JAN > a.JAN THEN 0 ELSE a.JAN - b.JAN END  ) AS JAN, 
			(CASE WHEN b.FEB > a.FEB THEN 0 ELSE a.FEB - b.FEB END ) AS FEB, 
			(CASE WHEN b.MAR > a.MAR THEN 0 ELSE a.MAR - b.MAR END ) AS MAR, 
			(CASE WHEN b.APR > a.APR THEN 0 ELSE a.APR - b.APR END) AS APR,
			(CASE WHEN b.MAY > a.MAY THEN 0 ELSE a.MAY - b.MAY END) AS MAY, 
			(CASE WHEN b.JUN > a.JUN THEN 0 ELSE a.JUN - b.JUN END) AS JUN,
			(CASE WHEN b.JUL > a.JUL THEN 0 ELSE a.JUL - b.JUL END) AS JUL,
			(CASE WHEN b.AUG > a.AUG THEN 0 ELSE a.AUG - b.AUG END) AS AUG,
			(CASE WHEN b.SEP > a.SEP THEN 0 ELSE a.SEP - b.SEP END) AS SEP, 
			(CASE WHEN b.OCT > a.OCT THEN 0 ELSE a.OCT - b.OCT END) AS OCT,
			(CASE WHEN b.NOV > a.NOV THEN 0 ELSE a.NOV - b.NOV END) AS NOV,
			(CASE WHEN b.DEC > a.DEC THEN 0 ELSE a.DEC - b.DEC END) AS DEC,
			(CASE WHEN b.YE_TOTAL > a.YE_TOTAL THEN 0 ELSE a.YE_TOTAL - b.YE_TOTAL END) AS YE_TOTAL,
			budget_year
	FROM
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL, budget_year  
			FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a /** ASSET **/
	JOIN
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL 
	FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b /** LIABILITIES **/
	ON a.branch_code = b.branch_code	) ps
	
	ON pu.branch_code = ps.branch_code and pu.budget_year = ps.budget_year	

	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Sourced') AND budget_date = @pYear) r	 --, 'Transfer Price for Funds Used')) r  /** Rates 1**/
	ON pu.budget_year = r.budget_date  	 
	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Used') AND budget_date = @pYear) r2	 --, 'Transfer Price for Funds Used')) r  /** Rates 2**/
	ON pu.budget_year = r.budget_date  ) p ) pc		) p
	ON ll.branch_code = p.branch_code ) nr
	ON fbi.branch_code = nr.branch_code ) r
	ON o.branch_code = r.branch_code	) c
	ON ho.branch_code = c.branch_code

/**=============================================================**/


UNION

/** NUMBER OF ADDITIONAL STAFF **/

	SELECT branch_code, 'Non Financial' AS cert_group, 13 AS caption_id, 'Number of Additional Staff' AS caption, 
		SUM(total_count) AS val, NULL AS perc
	FROM 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  b
	WHERE branch_code = @pBranchCode AND YEAR(budget_date) = @pYear
	GROUP by branch_code



UNION

/** ADDITIONAL FIXED ASSETS **/

	SELECT branch_code, 'Non Financial' AS cert_group, 14 AS caption_id, 'Additional Fixed Assets' AS caption,  
	SUM(total_cost) AS val, NULL as perc
	FROM 
	(SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_capex GROUP BY branch_code
	UNION
	SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_HO_capex GROUP BY branch_code ) A
	WHERE branch_code = @pBranchCode --AND year = @pYear
	GROUP by branch_code

	   
END







IF @pZoneCode IS NOT NULL

BEGIN

/** Balance sheet size **/
	SELECT z.zone_code, '2022 Budget' AS cert_group, 1 AS caption_id, 'Balance sheet size' AS caption, 
			SUM(A.Liabilities + B.pool_sources) AS val, NULL AS perc
	FROM 
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' 	GROUP BY budget_year, branch_code) A
	ON z.branch_code = A.branch_code AND 1=1
	JOIN
	(SELECT a.branch_code, CASE WHEN b.Liabilities > a.Asset THEN 0 ELSE (a.Asset - b.liabilities) END AS pool_sources, a.budget_year 
	FROM 
	(SELECT  branch_code, SUM(ye_total) AS Asset, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b
	ON a.branch_code = b.branch_code	) B

	ON z.branch_code = B.branch_code  AND A.budget_year = B.budget_year
	WHERE z.zone_code = @pZoneCode
	GROUP BY z.zone_code


UNION

/** CASA Deposits **/
	SELECT  z.zone_code, '2022 Budget' AS cert_group, 2 AS caption_id, 'CASA Deposits' AS caption, 
			SUM(a.casa_deposits) AS val, ROUND(((100* SUM(a.casa_deposits)) / SUM(b.total_deposits)), 0) AS perc 
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS casa_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.zone_code = @pZoneCode
	GROUP BY z.zone_code


UNION

/** Tenured Deposits **/
	SELECT  z.zone_code, '2022 Budget' AS cert_group, 3 AS caption_id, 'Tenured Deposits' AS caption, 
			SUM(a.tenured_deposits) AS val, ROUND(((100* SUM(a.tenured_deposits)) / SUM(b.total_deposits)), 0) AS perc 
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS tenured_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.zone_code = @pZoneCode
	GROUP BY z.zone_code


UNION


/** Total Deposits **/

	SELECT z.zone_code, '2022 Budget' AS cert_group, 4 AS caption_id, 'Total Deposits' AS caption, 
			SUM(a.ye_total) AS val, 100 AS perc 
	FROM 
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear AND z.zone_code = @pZoneCode
	GROUP BY z.zone_code 


UNION

/** Loans and Advances **/

	SELECT z.zone_code, '2022 Budget' AS cert_group, 5 AS caption_id, 'Loans and Advances' AS caption, 
			SUM(ye_total) AS val, NULL AS perc 
	FROM 
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND budget_year = @pYear AND z.zone_code = @pZoneCode
	GROUP BY  z.zone_code 



UNION

/** Loan Deposit Ratio (LDR) **/

	SELECT z.zone_code, '2022 Budget' AS cert_group, 6 AS caption_id, 'Loan Deposit Ratio (LDR)' AS caption, 
			ROUND(((100* SUM(a.val)) / SUM(b.val)), 0) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val, budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val,budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.zone_code = @pZoneCode
	GROUP BY z.zone_code



UNION

/** Interest Income **/

	SELECT  z.zone_code, 'Income Statement' AS cert_group, 7 AS caption_id, 'Interest Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE z.zone_code = @pZoneCode AND report_group = 'INTEREST INCOME YTD' AND budget_year = @pYear
	GROUP BY z.zone_code



UNION

/** Interest Expense **/

	SELECT  z.zone_code, 'Income Statement' AS cert_group, 8 AS caption_id, 'Interest Expense' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM 
		(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'INTEREST EXPENSE YTD' AND z.zone_code = @pZoneCode AND budget_year = @pYear
	GROUP BY z.zone_code


UNION

/** Fee Based Income **/


	SELECT  z.zone_code, 'Income Statement' AS cert_group, 9 AS caption_id, 'Fee Based Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'FEE BASED INCOME YTD' AND z.zone_code = @pZoneCode AND budget_year = @pYear
	GROUP BY z.zone_code


UNION

/** OPEX **/

	SELECT  z.zone_code, 'Income Statement' AS cert_group, 10 AS caption_id, 'OPEX' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM 
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIn wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'OPEX YTD' AND z.zone_code = @pZoneCode AND budget_year = @pYear
	GROUP BY z.zone_code


UNION


/** Cost of Fund **/

	SELECT  z.zone_code, 'Income Statement' AS cert_group, 11 AS caption_id, 'Cost of Fund' AS caption, 
			ROUND(((100 * SUM(a.tot_interest_expense)) / SUM(b.tot_deposits)), 0) AS val, NULL AS perc  
	FROM 
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT  branch_code, SUM(DEC) * 12 AS tot_interest_expense  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(DEC) AS tot_deposits
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224', '251', '206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code
	WHERE z.zone_code = @pZoneCode
	GROUP BY z.zone_code



UNION


/**===============================================================================**/
/** PBT **/
	
	SELECT z.zone_code, 'Income Statement' AS cert_group, 12 AS caption_id, 'PBT' AS caption, 
			(SUM(c.YE_TOTAL) - SUM(ho.YE_TOTAL)) AS val, NULL AS perc  
				 
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, monthly AS JAN, monthly * 2 AS FEB, monthly * 3 AS MAR, monthly * 4 AS APR, monthly * 5 AS MAY, monthly * 6 AS JUN,
				monthly * 7 AS JUL, monthly * 8 AS AUG, monthly * 9 AS SEP, monthly * 10 AS OCT, monthly * 11 AS NOV, monthly * 12 AS DEC,
				monthly * 12 AS YE_TOTAL
	FROM wa_budget_head_office 
	WHERE budget_date = @pYear) ho /** Head Office Expense **/
	ON z.branch_code = ho.branch_code

	JOIN
	/** Contribution **/
	(SELECT r.branch_code, (r.JAN - o.JAN) AS JAN, (r.FEB - o.FEB) AS FEB, (r.MAR - o.MAR) AS MAR, (r.APR - o.APR) AS APR,
			(r.MAY - o.MAY) AS MAY, (r.JUN - o.JUN) AS JUN, (r.JUL - o.JUL) AS JUL, (r.AUG - o.AUG) AS AUG, (r.SEP - o.SEP) AS SEP,
			(r.OCT - o.OCT) AS OCT, (r.NOV - o.NOV) AS NOV, (r.DEC - o.DEC) AS DEC, (r.YE_TOTAL - o.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'OPEX YTD' AND budget_year = @pYear
	GROUP BY branch_code ) o		/** OPEX YTD **/
	JOIN

	/** Total Revenue **/
	(SELECT nr.branch_code, (nr.JAN + fbi.JAN) AS JAN, (nr.FEB + fbi.FEB) AS FEB, (nr.MAR + fbi.MAR) AS MAR, (nr.APR + fbi.APR) AS APR,
			(nr.MAY + fbi.MAY) AS MAY, (nr.JUN + fbi.JUN) AS JUN, (nr.JUL + fbi.JUL) AS JUL, (nr.AUG + fbi.AUG) AS AUG, 
			(nr.SEP + fbi.SEP) AS SEP, (nr.OCT + fbi.OCT) AS OCT, (nr.NOV + fbi.NOV) AS NOV, (nr.DEC + fbi.DEC) AS DEC,
			(nr.YE_TOTAL + fbi.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'FEE BASED INCOME YTD' AND budget_year = @pYear
	GROUP BY branch_code ) fbi		/** Fee Based Income YTD **/

	JOIN

	/** Net Revenue from Funds **/
	(SELECT p.branch_code, (II.JAN + p.JAN - IE.JAN - ll.JAN) AS JAN, (II.FEB + p.FEB - IE.FEB - ll.FEB) AS FEB, (II.MAR + p.MAR - IE.MAR - ll.MAR) AS MAR,
			(II.APR + p.APR - IE.APR - ll.APR) AS APR, (II.MAY + p.MAY - IE.MAY - ll.MAY) AS MAY, (II.JUN + p.JUN - IE.JUN - ll.JUN) AS JUN,
			(II.JUL + p.JUL - IE.JUL - ll.JUL) AS JUL, (II.AUG + p.AUG - IE.AUG - ll.AUG) AS AUG, (II.SEP + p.SEP - IE.SEP - ll.SEP) AS SEP,
			(II.OCT + p.OCT - IE.OCT - ll.OCT) AS OCT, (II.NOV + p.NOV - IE.NOV - ll.NOV) AS NOV, (II.DEC + p.DEC - IE.DEC - ll.DEC) AS DEC,
			(II.YE_TOTAL + p.YE_TOTAL - IE.YE_TOTAL - ll.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST INCOME YTD' AND budget_year = @pYear
	GROUP BY branch_code ) II /** Interest Income YTD **/
	JOIN
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE YTD' AND budget_year = @pYear
	GROUP BY branch_code ) IE /** Interest Expense YTD **/
	ON II.branch_code = IE.branch_code

	JOIN
	/** Loan Loss Expense **/
	(SELECT branch_code, loan_loss_budget AS JAN, loan_loss_budget * 2 AS FEB, loan_loss_budget * 3 AS MAR, loan_loss_budget * 4 AS APR,
					loan_loss_budget * 5 AS MAY, loan_loss_budget * 6 AS JUN, loan_loss_budget * 7 AS JUL, loan_loss_budget * 8 AS AUG,
					loan_loss_budget * 9 AS SEP, loan_loss_budget * 10 AS OCT, loan_loss_budget * 11 AS NOV,
					loan_loss_budget * 12 AS DEC, loan_loss_budget * 12 AS YE_TOTAL
	FROM wa_budget_loan_loss
	WHERE YEAR(budget_date) = @pYear) ll
	ON IE.branch_code = ll.branch_code

	JOIN
	/** Pool Credit - Income Statement YTD **/
	(SELECT pc.branch_code, (pc.JAN) AS JAN, (pc.JAN + pc.FEB) AS FEB, (pc.JAN + pc.FEB + pc.MAR) AS MAR, (pc.JAN + pc.FEB + pc.MAR + pc.APR) AS APR, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY) AS MAY, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN) AS JUN, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL) AS JUL, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG) AS AUG, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP) AS SEP, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT) AS OCT,
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV) AS NOV, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS DEC, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS YE_TOTAL
	FROM

	/** Pool Credit **/
	(SELECT branch_code, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, 
			(JAN + FEB + MAR + APR + MAY + JUN + JUL + AUG + SEP + OCT + NOV + DEC) AS YE_TOTAL
	FROM
	(SELECT pu.branch_code, 
			CASE WHEN pu.JAN > 0 THEN (pu.JAN * r.JAN * 31/@pNyear) ELSE (pu.JAN * r2.JAN * 31/@pNyear) END AS JAN,
			CASE WHEN pu.FEB > 0 THEN (pu.FEB * r.FEB * 28/@pNyear) ELSE (pu.FEB * r2.FEB * 28/@pNyear) END AS FEB,
			CASE WHEN pu.MAR > 0 THEN (pu.MAR * r.MAR * 31/@pNyear) ELSE (pu.MAR * r2.MAR * 31/@pNyear) END AS MAR,
			CASE WHEN pu.APR > 0 THEN (pu.APR * r.APR * 30/@pNyear) ELSE (pu.APR * r2.APR * 30/@pNyear) END AS APR,
			CASE WHEN pu.MAY > 0 THEN (pu.MAY * r.MAY * 31/@pNyear) ELSE (pu.MAY * r2.MAY * 31/@pNyear) END AS MAY,
			CASE WHEN pu.JUN > 0 THEN (pu.JUN * r.JUN * 30/@pNyear) ELSE (pu.JUN * r2.JUN * 30/@pNyear) END AS JUN,
			CASE WHEN pu.JUL > 0 THEN (pu.JUL * r.JUL * 31/@pNyear) ELSE (pu.JUL * r2.JUL * 31/@pNyear) END AS JUL,
			CASE WHEN pu.AUG > 0 THEN (pu.AUG * r.AUG * 31/@pNyear) ELSE (pu.AUG * r.AUG * 31/@pNyear) END AS AUG,
			CASE WHEN pu.SEP > 0 THEN (pu.SEP * r.SEPT * 30/@pNyear) ELSE (pu.SEP * r2.SEPT * 30/@pNyear) END AS SEP,
			CASE WHEN pu.OCT > 0 THEN (pu.OCT * r.OCT * 31/@pNyear) ELSE (pu.OCT * r2.OCT * 31/@pNyear) END AS OCT,
			CASE WHEN pu.NOV > 0 THEN (pu.NOV * r.NOV * 30/@pNyear) ELSE (pu.NOV * r2.NOV * 30/@pNyear) END AS NOV,
			CASE WHEN pu.DEC > 0 THEN (pu.DEC * r.DEC * 31/@pNyear) ELSE (pu.DEC * r2.DEC * 31/@pNyear) END AS DEC

	FROM

	/** Pool Uses **/
	(SELECT a.branch_code, 
			(b.JAN - a.JAN) AS JAN, (b.FEB - a.FEB) AS FEB, (b.MAR - a.MAR) AS MAR, (b.APR - a.APR) AS APR, (b.MAY - a.MAY) AS MAY, (b.JUN - a.JUN) AS JUN,
			(b.JUL - a.JUL) AS JUL,	(b.AUG - a.AUG) AS AUG, (b.SEP - a.SEP) AS SEP, (b.OCT - a.OCT) AS OCT, (b.NOV - a.NOV) AS NOV, (b.DEC - a.DEC) AS DEC,
			(b.YE_TOTAL - a.YE_TOTAL) AS YE_TOTAL,
			budget_year
	FROM
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL, budget_year  
			FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a /** ASSET **/
	JOIN
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL 
	FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b /** LIABILITIES **/
	ON a.branch_code = b.branch_code	) pu	

	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Sourced') AND budget_date = @pYear) r	 --, 'Transfer Price for Funds Used')) r  /** Rates 1**/
	ON pu.budget_year = r.budget_date  	 
	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Used') AND budget_date = @pYear) r2	 --, 'Transfer Price for Funds Used')) r  /** Rates 2**/
	ON pu.budget_year = r.budget_date  ) p ) pc		) p
	ON ll.branch_code = p.branch_code ) nr
	ON fbi.branch_code = nr.branch_code ) r
	ON o.branch_code = r.branch_code	) c
	ON z.branch_code = c.branch_code

	WHERE z.zone_code = @pZoneCode
	GROUP BY z.zone_code

/**=============================================================**/


UNION

/** NUMBER OF ADDITIONAL STAFF **/

	SELECT z.zone_code, 'Non Financial' AS cert_group, 13 AS caption_id, 'Number of Additional Staff' AS caption, 
		SUM(total_count) AS val, NULL AS perc
	FROM 
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN  
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  a
	ON z.branch_code = a.branch_code
	WHERE z.zone_code = @pZoneCode AND YEAR(a.budget_date) = @pYear
	GROUP by z.zone_code



UNION

/** ADDITIONAL FIXED ASSETS **/

	SELECT z.zone_code, 'Non Financial' AS cert_group, 14 AS caption_id, 'Additional Fixed Assets' AS caption,  
	SUM(total_cost) AS val, NULL as perc
	FROM
	(SELECT DISTINCT zone_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN 
	(SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_capex GROUP BY branch_code
	UNION
	SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_HO_capex GROUP BY branch_code ) a
	ON z.branch_code = a.branch_code
	WHERE z.zone_code = @pZoneCode --AND year = @pYear
	GROUP by z.zone_code




END










IF @pRegionCode IS NOT NULL

BEGIN

/** Balance sheet size **/
	SELECT z.region_code, '2022 Budget' AS cert_group, 1 AS caption_id, 'Balance sheet size' AS caption, 
			SUM(A.Liabilities + B.pool_sources) AS val, NULL AS perc
	FROM 
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' 	GROUP BY budget_year, branch_code) A
	ON z.branch_code = A.branch_code AND 1=1
	JOIN
	(SELECT a.branch_code, CASE WHEN b.Liabilities > a.Asset THEN 0 ELSE (a.Asset - b.liabilities) END AS pool_sources, a.budget_year 
	FROM 
	(SELECT  branch_code, SUM(ye_total) AS Asset, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b
	ON a.branch_code = b.branch_code	) B

	ON z.branch_code = B.branch_code  AND A.budget_year = B.budget_year
	WHERE z.region_code = @pRegionCode
	GROUP BY z.region_code


UNION

/** CASA Deposits **/
	SELECT  z.region_code, '2022 Budget' AS cert_group, 2 AS caption_id, 'CASA Deposits' AS caption, 
			SUM(a.casa_deposits) AS val, ROUND(((100* SUM(a.casa_deposits)) / SUM(b.total_deposits)), 0) AS perc 
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS casa_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.region_code = @pRegionCode
	GROUP BY z.region_code


UNION

/** Tenured Deposits **/
	SELECT  z.region_code, '2022 Budget' AS cert_group, 3 AS caption_id, 'Tenured Deposits' AS caption, 
			SUM(a.tenured_deposits) AS val, ROUND(((100* SUM(a.tenured_deposits)) / SUM(b.total_deposits)), 0) AS perc 
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS tenured_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.region_code = @pRegionCode
	GROUP BY z.region_code


UNION


/** Total Deposits **/

	SELECT z.region_code, '2022 Budget' AS cert_group, 4 AS caption_id, 'Total Deposits' AS caption, 
			SUM(a.ye_total) AS val, 100 AS perc 
	FROM 
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear AND z.region_code = @pRegionCode
	GROUP BY z.region_code 


UNION

/** Loans and Advances **/

	SELECT z.region_code, '2022 Budget' AS cert_group, 5 AS caption_id, 'Loans and Advances' AS caption, 
			SUM(ye_total) AS val, NULL AS perc 
	FROM 
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND budget_year = @pYear AND z.region_code = @pRegionCode
	GROUP BY  z.region_code 



UNION

/** Loan Deposit Ratio (LDR) **/

	SELECT z.region_code, '2022 Budget' AS cert_group, 6 AS caption_id, 'Loan Deposit Ratio (LDR)' AS caption, 
			ROUND(((100* SUM(a.val)) / SUM(b.val)), 0) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val, budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val,budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.region_code = @pRegionCode
	GROUP BY z.region_code



UNION

/** Interest Income **/

	SELECT  z.region_code, 'Income Statement' AS cert_group, 7 AS caption_id, 'Interest Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE z.region_code = @pRegionCode AND report_group = 'INTEREST INCOME YTD' AND budget_year = @pYear
	GROUP BY z.region_code



UNION

/** Interest Expense **/

	SELECT  z.region_code, 'Income Statement' AS cert_group, 8 AS caption_id, 'Interest Expense' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM 
		(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'INTEREST EXPENSE YTD' AND z.region_code = @pRegionCode AND budget_year = @pYear
	GROUP BY z.region_code


UNION

/** Fee Based Income **/


	SELECT  z.region_code, 'Income Statement' AS cert_group, 9 AS caption_id, 'Fee Based Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'FEE BASED INCOME YTD' AND z.region_code = @pRegionCode AND budget_year = @pYear
	GROUP BY z.region_code


UNION

/** OPEX **/

	SELECT  z.region_code, 'Income Statement' AS cert_group, 10 AS caption_id, 'OPEX' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM 
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIn wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'OPEX YTD' AND z.region_code = @pRegionCode AND budget_year = @pYear
	GROUP BY z.region_code


UNION


/** Cost of Fund **/

	SELECT  z.region_code, 'Income Statement' AS cert_group, 11 AS caption_id, 'Cost of Fund' AS caption, 
			ROUND(((100 * SUM(a.tot_interest_expense)) / SUM(b.tot_deposits)), 0) AS val, NULL AS perc  
	FROM 
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT  branch_code, SUM(DEC) * 12 AS tot_interest_expense  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(DEC) AS tot_deposits
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224', '251', '206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code
	WHERE z.region_code = @pRegionCode
	GROUP BY z.region_code



UNION


/**===============================================================================**/
/** PBT **/
	
	SELECT z.region_code, 'Income Statement' AS cert_group, 12 AS caption_id, 'PBT' AS caption, 
			(SUM(c.YE_TOTAL) - SUM(ho.YE_TOTAL)) AS val, NULL AS perc  
				 
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, monthly AS JAN, monthly * 2 AS FEB, monthly * 3 AS MAR, monthly * 4 AS APR, monthly * 5 AS MAY, monthly * 6 AS JUN,
				monthly * 7 AS JUL, monthly * 8 AS AUG, monthly * 9 AS SEP, monthly * 10 AS OCT, monthly * 11 AS NOV, monthly * 12 AS DEC,
				monthly * 12 AS YE_TOTAL
	FROM wa_budget_head_office 
	WHERE budget_date = @pYear) ho /** Head Office Expense **/
	ON z.branch_code = ho.branch_code

	JOIN
	/** Contribution **/
	(SELECT r.branch_code, (r.JAN - o.JAN) AS JAN, (r.FEB - o.FEB) AS FEB, (r.MAR - o.MAR) AS MAR, (r.APR - o.APR) AS APR,
			(r.MAY - o.MAY) AS MAY, (r.JUN - o.JUN) AS JUN, (r.JUL - o.JUL) AS JUL, (r.AUG - o.AUG) AS AUG, (r.SEP - o.SEP) AS SEP,
			(r.OCT - o.OCT) AS OCT, (r.NOV - o.NOV) AS NOV, (r.DEC - o.DEC) AS DEC, (r.YE_TOTAL - o.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'OPEX YTD' AND budget_year = @pYear
	GROUP BY branch_code ) o		/** OPEX YTD **/
	JOIN

	/** Total Revenue **/
	(SELECT nr.branch_code, (nr.JAN + fbi.JAN) AS JAN, (nr.FEB + fbi.FEB) AS FEB, (nr.MAR + fbi.MAR) AS MAR, (nr.APR + fbi.APR) AS APR,
			(nr.MAY + fbi.MAY) AS MAY, (nr.JUN + fbi.JUN) AS JUN, (nr.JUL + fbi.JUL) AS JUL, (nr.AUG + fbi.AUG) AS AUG, 
			(nr.SEP + fbi.SEP) AS SEP, (nr.OCT + fbi.OCT) AS OCT, (nr.NOV + fbi.NOV) AS NOV, (nr.DEC + fbi.DEC) AS DEC,
			(nr.YE_TOTAL + fbi.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'FEE BASED INCOME YTD' AND budget_year = @pYear
	GROUP BY branch_code ) fbi		/** Fee Based Income YTD **/

	JOIN

	/** Net Revenue from Funds **/
	(SELECT p.branch_code, (II.JAN + p.JAN - IE.JAN - ll.JAN) AS JAN, (II.FEB + p.FEB - IE.FEB - ll.FEB) AS FEB, (II.MAR + p.MAR - IE.MAR - ll.MAR) AS MAR,
			(II.APR + p.APR - IE.APR - ll.APR) AS APR, (II.MAY + p.MAY - IE.MAY - ll.MAY) AS MAY, (II.JUN + p.JUN - IE.JUN - ll.JUN) AS JUN,
			(II.JUL + p.JUL - IE.JUL - ll.JUL) AS JUL, (II.AUG + p.AUG - IE.AUG - ll.AUG) AS AUG, (II.SEP + p.SEP - IE.SEP - ll.SEP) AS SEP,
			(II.OCT + p.OCT - IE.OCT - ll.OCT) AS OCT, (II.NOV + p.NOV - IE.NOV - ll.NOV) AS NOV, (II.DEC + p.DEC - IE.DEC - ll.DEC) AS DEC,
			(II.YE_TOTAL + p.YE_TOTAL - IE.YE_TOTAL - ll.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST INCOME YTD' AND budget_year = @pYear
	GROUP BY branch_code ) II /** Interest Income YTD **/
	JOIN
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE YTD' AND budget_year = @pYear
	GROUP BY branch_code ) IE /** Interest Expense YTD **/
	ON II.branch_code = IE.branch_code

	JOIN
	/** Loan Loss Expense **/
	(SELECT branch_code, loan_loss_budget AS JAN, loan_loss_budget * 2 AS FEB, loan_loss_budget * 3 AS MAR, loan_loss_budget * 4 AS APR,
					loan_loss_budget * 5 AS MAY, loan_loss_budget * 6 AS JUN, loan_loss_budget * 7 AS JUL, loan_loss_budget * 8 AS AUG,
					loan_loss_budget * 9 AS SEP, loan_loss_budget * 10 AS OCT, loan_loss_budget * 11 AS NOV,
					loan_loss_budget * 12 AS DEC, loan_loss_budget * 12 AS YE_TOTAL
	FROM wa_budget_loan_loss
	WHERE YEAR(budget_date) = @pYear) ll
	ON IE.branch_code = ll.branch_code

	JOIN
	/** Pool Credit - Income Statement YTD **/
	(SELECT pc.branch_code, (pc.JAN) AS JAN, (pc.JAN + pc.FEB) AS FEB, (pc.JAN + pc.FEB + pc.MAR) AS MAR, (pc.JAN + pc.FEB + pc.MAR + pc.APR) AS APR, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY) AS MAY, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN) AS JUN, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL) AS JUL, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG) AS AUG, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP) AS SEP, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT) AS OCT,
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV) AS NOV, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS DEC, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS YE_TOTAL
	FROM

	/** Pool Credit **/
	(SELECT branch_code, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, 
			(JAN + FEB + MAR + APR + MAY + JUN + JUL + AUG + SEP + OCT + NOV + DEC) AS YE_TOTAL
	FROM
	(SELECT pu.branch_code, 
			CASE WHEN pu.JAN > 0 THEN (pu.JAN * r.JAN * 31/@pNyear) ELSE (pu.JAN * r2.JAN * 31/@pNyear) END AS JAN,
			CASE WHEN pu.FEB > 0 THEN (pu.FEB * r.FEB * 28/@pNyear) ELSE (pu.FEB * r2.FEB * 28/@pNyear) END AS FEB,
			CASE WHEN pu.MAR > 0 THEN (pu.MAR * r.MAR * 31/@pNyear) ELSE (pu.MAR * r2.MAR * 31/@pNyear) END AS MAR,
			CASE WHEN pu.APR > 0 THEN (pu.APR * r.APR * 30/@pNyear) ELSE (pu.APR * r2.APR * 30/@pNyear) END AS APR,
			CASE WHEN pu.MAY > 0 THEN (pu.MAY * r.MAY * 31/@pNyear) ELSE (pu.MAY * r2.MAY * 31/@pNyear) END AS MAY,
			CASE WHEN pu.JUN > 0 THEN (pu.JUN * r.JUN * 30/@pNyear) ELSE (pu.JUN * r2.JUN * 30/@pNyear) END AS JUN,
			CASE WHEN pu.JUL > 0 THEN (pu.JUL * r.JUL * 31/@pNyear) ELSE (pu.JUL * r2.JUL * 31/@pNyear) END AS JUL,
			CASE WHEN pu.AUG > 0 THEN (pu.AUG * r.AUG * 31/@pNyear) ELSE (pu.AUG * r.AUG * 31/@pNyear) END AS AUG,
			CASE WHEN pu.SEP > 0 THEN (pu.SEP * r.SEPT * 30/@pNyear) ELSE (pu.SEP * r2.SEPT * 30/@pNyear) END AS SEP,
			CASE WHEN pu.OCT > 0 THEN (pu.OCT * r.OCT * 31/@pNyear) ELSE (pu.OCT * r2.OCT * 31/@pNyear) END AS OCT,
			CASE WHEN pu.NOV > 0 THEN (pu.NOV * r.NOV * 30/@pNyear) ELSE (pu.NOV * r2.NOV * 30/@pNyear) END AS NOV,
			CASE WHEN pu.DEC > 0 THEN (pu.DEC * r.DEC * 31/@pNyear) ELSE (pu.DEC * r2.DEC * 31/@pNyear) END AS DEC

	FROM

	/** Pool Uses **/
	(SELECT a.branch_code, 
			(b.JAN - a.JAN) AS JAN, (b.FEB - a.FEB) AS FEB, (b.MAR - a.MAR) AS MAR, (b.APR - a.APR) AS APR, (b.MAY - a.MAY) AS MAY, (b.JUN - a.JUN) AS JUN,
			(b.JUL - a.JUL) AS JUL,	(b.AUG - a.AUG) AS AUG, (b.SEP - a.SEP) AS SEP, (b.OCT - a.OCT) AS OCT, (b.NOV - a.NOV) AS NOV, (b.DEC - a.DEC) AS DEC,
			(b.YE_TOTAL - a.YE_TOTAL) AS YE_TOTAL,
			budget_year
	FROM
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL, budget_year  
			FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a /** ASSET **/
	JOIN
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL 
	FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b /** LIABILITIES **/
	ON a.branch_code = b.branch_code	) pu	

	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Sourced') AND budget_date = @pYear) r	 --, 'Transfer Price for Funds Used')) r  /** Rates 1**/
	ON pu.budget_year = r.budget_date  	 
	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Used') AND budget_date = @pYear) r2	 --, 'Transfer Price for Funds Used')) r  /** Rates 2**/
	ON pu.budget_year = r.budget_date  ) p ) pc		) p
	ON ll.branch_code = p.branch_code ) nr
	ON fbi.branch_code = nr.branch_code ) r
	ON o.branch_code = r.branch_code	) c
	ON z.branch_code = c.branch_code

	WHERE z.region_code = @pRegionCode
	GROUP BY z.region_code

/**=============================================================**/


UNION

/** NUMBER OF ADDITIONAL STAFF **/

	SELECT z.region_code, 'Non Financial' AS cert_group, 13 AS caption_id, 'Number of Additional Staff' AS caption, 
		SUM(total_count) AS val, NULL AS perc
	FROM 
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  a
	ON z.branch_code = a.branch_code
	WHERE z.region_code = @pRegionCode AND YEAR(a.budget_date) = @pYear
	GROUP by z.region_code



UNION

/** ADDITIONAL FIXED ASSETS **/

	SELECT z.region_code, 'Non Financial' AS cert_group, 14 AS caption_id, 'Additional Fixed Assets' AS caption,  
	SUM(total_cost) AS val, NULL as perc
	FROM
	(SELECT DISTINCT region_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN 
	(SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_capex GROUP BY branch_code
	UNION
	SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_HO_capex GROUP BY branch_code ) a
	ON z.branch_code = a.branch_code
	WHERE z.region_code = @pRegionCode --AND year = @pYear
	GROUP by z.region_code




END












IF @pDirectorateCode IS NOT NULL

BEGIN

/** Balance sheet size **/
	SELECT z.directorate_code, '2022 Budget' AS cert_group, 1 AS caption_id, 'Balance sheet size' AS caption, 
			SUM(A.Liabilities + B.pool_sources) AS val, NULL AS perc
	FROM 
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' 	GROUP BY budget_year, branch_code) A
	ON z.branch_code = A.branch_code AND 1=1
	JOIN
	(SELECT a.branch_code, CASE WHEN b.Liabilities > a.Asset THEN 0 ELSE (a.Asset - b.liabilities) END AS pool_sources, a.budget_year 
	FROM 
	(SELECT  branch_code, SUM(ye_total) AS Asset, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	JOIN
	(SELECT  branch_code, SUM(ye_total) AS Liabilities, budget_year FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b
	ON a.branch_code = b.branch_code	) B

	ON z.branch_code = B.branch_code  AND A.budget_year = B.budget_year
	WHERE z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code


UNION

/** CASA Deposits **/
	SELECT  z.directorate_code, '2022 Budget' AS cert_group, 2 AS caption_id, 'CASA Deposits' AS caption, 
			SUM(a.casa_deposits) AS val, ROUND(((100* SUM(a.casa_deposits)) / SUM(b.total_deposits)), 0) AS perc 
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS casa_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code


UNION

/** Tenured Deposits **/
	SELECT  z.directorate_code, '2022 Budget' AS cert_group, 3 AS caption_id, 'Tenured Deposits' AS caption, 
			SUM(a.tenured_deposits) AS val, ROUND(((100* SUM(a.tenured_deposits)) / SUM(b.total_deposits)), 0) AS perc 
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS tenured_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS total_deposits, budget_year FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code


UNION


/** Total Deposits **/

	SELECT z.directorate_code, '2022 Budget' AS cert_group, 4 AS caption_id, 'Total Deposits' AS caption, 
			SUM(a.ye_total) AS val, 100 AS perc 
	FROM 
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear AND z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code 


UNION

/** Loans and Advances **/

	SELECT z.directorate_code, '2022 Budget' AS cert_group, 5 AS caption_id, 'Loans and Advances' AS caption, 
			SUM(ye_total) AS val, NULL AS perc 
	FROM 
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND budget_year = @pYear AND z.directorate_code = @pDirectorateCode
	GROUP BY  z.directorate_code 



UNION

/** Loan Deposit Ratio (LDR) **/

	SELECT z.directorate_code, '2022 Budget' AS cert_group, 6 AS caption_id, 'Loan Deposit Ratio (LDR)' AS caption, 
			ROUND(((100* SUM(a.val)) / SUM(b.val)), 0) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val, budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'ASSET' AND position IN ('116', '125', '128', '119', '122', '131', '134', '137')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(ye_total) AS val,budget_year
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224',	'206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code 
	WHERE z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code



UNION

/** Interest Income **/

	SELECT  z.directorate_code, 'Income Statement' AS cert_group, 7 AS caption_id, 'Interest Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE z.directorate_code = @pDirectorateCode AND report_group = 'INTEREST INCOME YTD' AND budget_year = @pYear
	GROUP BY z.directorate_code



UNION

/** Interest Expense **/

	SELECT  z.directorate_code, 'Income Statement' AS cert_group, 8 AS caption_id, 'Interest Expense' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM 
		(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'INTEREST EXPENSE YTD' AND z.directorate_code = @pDirectorateCode AND budget_year = @pYear
	GROUP BY z.directorate_code


UNION

/** Fee Based Income **/


	SELECT  z.directorate_code, 'Income Statement' AS cert_group, 9 AS caption_id, 'Fee Based Income' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'FEE BASED INCOME YTD' AND z.directorate_code = @pDirectorateCode AND budget_year = @pYear
	GROUP BY z.directorate_code


UNION

/** OPEX **/

	SELECT  z.directorate_code, 'Income Statement' AS cert_group, 10 AS caption_id, 'OPEX' AS caption, 
			SUM(YE_TOTAL) AS val, NULL AS perc  
	FROM 
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIn wa_budget_consolidated_report a
	ON z.branch_code = a.branch_code
	WHERE report_group = 'OPEX YTD' AND z.directorate_code = @pDirectorateCode AND budget_year = @pYear
	GROUP BY z.directorate_code


UNION


/** Cost of Fund **/

	SELECT  z.directorate_code, 'Income Statement' AS cert_group, 11 AS caption_id, 'Cost of Fund' AS caption, 
			ROUND(((100 * SUM(a.tot_interest_expense)) / SUM(b.tot_deposits)), 0) AS val, NULL AS perc  
	FROM 
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT  branch_code, SUM(DEC) * 12 AS tot_interest_expense  
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE' AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a
	ON z.branch_code = a.branch_code
	JOIN
	(SELECT branch_code, SUM(DEC) AS tot_deposits
	FROM wa_budget_consolidated_report
	WHERE report_group = 'LIABILITIES' AND position IN ('236', '239', '209', '221', '203', '233', '227', '230', '224', '251', '206', '245', '242')
		AND budget_year = @pYear
	GROUP BY budget_year, branch_code ) b
	ON z.branch_code = b.branch_code
	WHERE z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code



UNION


/**===============================================================================**/
/** PBT **/
	
	SELECT z.directorate_code, 'Income Statement' AS cert_group, 12 AS caption_id, 'PBT' AS caption, 
			(SUM(c.YE_TOTAL) - SUM(ho.YE_TOTAL)) AS val, NULL AS perc  
				 
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN
	(SELECT branch_code, monthly AS JAN, monthly * 2 AS FEB, monthly * 3 AS MAR, monthly * 4 AS APR, monthly * 5 AS MAY, monthly * 6 AS JUN,
				monthly * 7 AS JUL, monthly * 8 AS AUG, monthly * 9 AS SEP, monthly * 10 AS OCT, monthly * 11 AS NOV, monthly * 12 AS DEC,
				monthly * 12 AS YE_TOTAL
	FROM wa_budget_head_office 
	WHERE budget_date = @pYear) ho /** Head Office Expense **/
	ON z.branch_code = ho.branch_code

	JOIN
	/** Contribution **/
	(SELECT r.branch_code, (r.JAN - o.JAN) AS JAN, (r.FEB - o.FEB) AS FEB, (r.MAR - o.MAR) AS MAR, (r.APR - o.APR) AS APR,
			(r.MAY - o.MAY) AS MAY, (r.JUN - o.JUN) AS JUN, (r.JUL - o.JUL) AS JUL, (r.AUG - o.AUG) AS AUG, (r.SEP - o.SEP) AS SEP,
			(r.OCT - o.OCT) AS OCT, (r.NOV - o.NOV) AS NOV, (r.DEC - o.DEC) AS DEC, (r.YE_TOTAL - o.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'OPEX YTD' AND budget_year = @pYear
	GROUP BY branch_code ) o		/** OPEX YTD **/
	JOIN

	/** Total Revenue **/
	(SELECT nr.branch_code, (nr.JAN + fbi.JAN) AS JAN, (nr.FEB + fbi.FEB) AS FEB, (nr.MAR + fbi.MAR) AS MAR, (nr.APR + fbi.APR) AS APR,
			(nr.MAY + fbi.MAY) AS MAY, (nr.JUN + fbi.JUN) AS JUN, (nr.JUL + fbi.JUL) AS JUL, (nr.AUG + fbi.AUG) AS AUG, 
			(nr.SEP + fbi.SEP) AS SEP, (nr.OCT + fbi.OCT) AS OCT, (nr.NOV + fbi.NOV) AS NOV, (nr.DEC + fbi.DEC) AS DEC,
			(nr.YE_TOTAL + fbi.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'FEE BASED INCOME YTD' AND budget_year = @pYear
	GROUP BY branch_code ) fbi		/** Fee Based Income YTD **/

	JOIN

	/** Net Revenue from Funds **/
	(SELECT p.branch_code, (II.JAN + p.JAN - IE.JAN - ll.JAN) AS JAN, (II.FEB + p.FEB - IE.FEB - ll.FEB) AS FEB, (II.MAR + p.MAR - IE.MAR - ll.MAR) AS MAR,
			(II.APR + p.APR - IE.APR - ll.APR) AS APR, (II.MAY + p.MAY - IE.MAY - ll.MAY) AS MAY, (II.JUN + p.JUN - IE.JUN - ll.JUN) AS JUN,
			(II.JUL + p.JUL - IE.JUL - ll.JUL) AS JUL, (II.AUG + p.AUG - IE.AUG - ll.AUG) AS AUG, (II.SEP + p.SEP - IE.SEP - ll.SEP) AS SEP,
			(II.OCT + p.OCT - IE.OCT - ll.OCT) AS OCT, (II.NOV + p.NOV - IE.NOV - ll.NOV) AS NOV, (II.DEC + p.DEC - IE.DEC - ll.DEC) AS DEC,
			(II.YE_TOTAL + p.YE_TOTAL - IE.YE_TOTAL - ll.YE_TOTAL) AS YE_TOTAL
	FROM
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST INCOME YTD' AND budget_year = @pYear
	GROUP BY branch_code ) II /** Interest Income YTD **/
	JOIN
	(SELECT  branch_code,SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL
	FROM wa_budget_consolidated_report
	WHERE report_group = 'INTEREST EXPENSE YTD' AND budget_year = @pYear
	GROUP BY branch_code ) IE /** Interest Expense YTD **/
	ON II.branch_code = IE.branch_code

	JOIN
	/** Loan Loss Expense **/
	(SELECT branch_code, loan_loss_budget AS JAN, loan_loss_budget * 2 AS FEB, loan_loss_budget * 3 AS MAR, loan_loss_budget * 4 AS APR,
					loan_loss_budget * 5 AS MAY, loan_loss_budget * 6 AS JUN, loan_loss_budget * 7 AS JUL, loan_loss_budget * 8 AS AUG,
					loan_loss_budget * 9 AS SEP, loan_loss_budget * 10 AS OCT, loan_loss_budget * 11 AS NOV,
					loan_loss_budget * 12 AS DEC, loan_loss_budget * 12 AS YE_TOTAL
	FROM wa_budget_loan_loss
	WHERE YEAR(budget_date) = @pYear) ll
	ON IE.branch_code = ll.branch_code

	JOIN
	/** Pool Credit - Income Statement YTD **/
	(SELECT pc.branch_code, (pc.JAN) AS JAN, (pc.JAN + pc.FEB) AS FEB, (pc.JAN + pc.FEB + pc.MAR) AS MAR, (pc.JAN + pc.FEB + pc.MAR + pc.APR) AS APR, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY) AS MAY, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN) AS JUN, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL) AS JUL, (pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG) AS AUG, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP) AS SEP, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT) AS OCT,
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV) AS NOV, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS DEC, 
				(pc.JAN + pc.FEB + pc.MAR + pc.APR + pc.MAY + pc.JUN + pc.JUL + pc.AUG + pc.SEP + pc.OCT + pc.NOV + pc.DEC) AS YE_TOTAL
	FROM

	/** Pool Credit **/
	(SELECT branch_code, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, 
			(JAN + FEB + MAR + APR + MAY + JUN + JUL + AUG + SEP + OCT + NOV + DEC) AS YE_TOTAL
	FROM
	(SELECT pu.branch_code, 
			CASE WHEN pu.JAN > 0 THEN (pu.JAN * r.JAN * 31/@pNyear) ELSE (pu.JAN * r2.JAN * 31/@pNyear) END AS JAN,
			CASE WHEN pu.FEB > 0 THEN (pu.FEB * r.FEB * 28/@pNyear) ELSE (pu.FEB * r2.FEB * 28/@pNyear) END AS FEB,
			CASE WHEN pu.MAR > 0 THEN (pu.MAR * r.MAR * 31/@pNyear) ELSE (pu.MAR * r2.MAR * 31/@pNyear) END AS MAR,
			CASE WHEN pu.APR > 0 THEN (pu.APR * r.APR * 30/@pNyear) ELSE (pu.APR * r2.APR * 30/@pNyear) END AS APR,
			CASE WHEN pu.MAY > 0 THEN (pu.MAY * r.MAY * 31/@pNyear) ELSE (pu.MAY * r2.MAY * 31/@pNyear) END AS MAY,
			CASE WHEN pu.JUN > 0 THEN (pu.JUN * r.JUN * 30/@pNyear) ELSE (pu.JUN * r2.JUN * 30/@pNyear) END AS JUN,
			CASE WHEN pu.JUL > 0 THEN (pu.JUL * r.JUL * 31/@pNyear) ELSE (pu.JUL * r2.JUL * 31/@pNyear) END AS JUL,
			CASE WHEN pu.AUG > 0 THEN (pu.AUG * r.AUG * 31/@pNyear) ELSE (pu.AUG * r.AUG * 31/@pNyear) END AS AUG,
			CASE WHEN pu.SEP > 0 THEN (pu.SEP * r.SEPT * 30/@pNyear) ELSE (pu.SEP * r2.SEPT * 30/@pNyear) END AS SEP,
			CASE WHEN pu.OCT > 0 THEN (pu.OCT * r.OCT * 31/@pNyear) ELSE (pu.OCT * r2.OCT * 31/@pNyear) END AS OCT,
			CASE WHEN pu.NOV > 0 THEN (pu.NOV * r.NOV * 30/@pNyear) ELSE (pu.NOV * r2.NOV * 30/@pNyear) END AS NOV,
			CASE WHEN pu.DEC > 0 THEN (pu.DEC * r.DEC * 31/@pNyear) ELSE (pu.DEC * r2.DEC * 31/@pNyear) END AS DEC

	FROM

	/** Pool Uses **/
	(SELECT a.branch_code, 
			(b.JAN - a.JAN) AS JAN, (b.FEB - a.FEB) AS FEB, (b.MAR - a.MAR) AS MAR, (b.APR - a.APR) AS APR, (b.MAY - a.MAY) AS MAY, (b.JUN - a.JUN) AS JUN,
			(b.JUL - a.JUL) AS JUL,	(b.AUG - a.AUG) AS AUG, (b.SEP - a.SEP) AS SEP, (b.OCT - a.OCT) AS OCT, (b.NOV - a.NOV) AS NOV, (b.DEC - a.DEC) AS DEC,
			(b.YE_TOTAL - a.YE_TOTAL) AS YE_TOTAL,
			budget_year
	FROM
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL, budget_year  
			FROM wa_budget_consolidated_report 
	WHERE report_group = 'ASSET' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) a /** ASSET **/
	JOIN
	(SELECT  branch_code, SUM(JAN) AS JAN, SUM(FEB) AS FEB, SUM(MAR) AS MAR, SUM(APR) AS APR, SUM(MAY) AS MAY, SUM(JUN) AS JUN, 
			SUM(JUL) AS JUL, SUM(AUG) AS AUG, SUM(SEP) AS SEP, SUM(OCT) AS OCT, SUM(NOV) AS NOV, SUM(DEC) AS DEC, SUM(YE_TOTAL) AS YE_TOTAL 
	FROM wa_budget_consolidated_report 
	WHERE report_group = 'LIABILITIES' AND branch_code = @pBranchCode AND budget_year = @pYear
	GROUP BY budget_year, branch_code) b /** LIABILITIES **/
	ON a.branch_code = b.branch_code	) pu	

	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Sourced') AND budget_date = @pYear) r	 --, 'Transfer Price for Funds Used')) r  /** Rates 1**/
	ON pu.budget_year = r.budget_date  	 
	JOIN (SELECT caption, [JAN ],FEB, MAR, APR, MAY, JUN, JUL, AUG, SEPT, OCT, NOV, DEC, budget_date, ROW_NUMBER()OVER(ORDER BY caption) AS id
			FROM wa_budget_rate_assumptions WHERE caption IN ('Transfer Price for Funds Used') AND budget_date = @pYear) r2	 --, 'Transfer Price for Funds Used')) r  /** Rates 2**/
	ON pu.budget_year = r.budget_date  ) p ) pc		) p
	ON ll.branch_code = p.branch_code ) nr
	ON fbi.branch_code = nr.branch_code ) r
	ON o.branch_code = r.branch_code	) c
	ON z.branch_code = c.branch_code

	WHERE z.directorate_code = @pDirectorateCode
	GROUP BY z.directorate_code

/**=============================================================**/


UNION

/** NUMBER OF ADDITIONAL STAFF **/

	SELECT z.directorate_code, 'Non Financial' AS cert_group, 13 AS caption_id, 'Number of Additional Staff' AS caption, 
		SUM(total_count) AS val, NULL AS perc
	FROM 
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN 
	(SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_staff_cost
	UNION
	SELECT branch_code, marketing, support, total_count, total_cost, budget_date FROM wa_budget_HO_staff_cost)  a
	ON z.branch_code = a.branch_code
	WHERE z.directorate_code = @pDirectorateCode AND YEAR(a.budget_date) = @pYear
	GROUP by z.directorate_code



UNION

/** ADDITIONAL FIXED ASSETS **/

	SELECT z.directorate_code, 'Non Financial' AS cert_group, 14 AS caption_id, 'Additional Fixed Assets' AS caption,  
	SUM(total_cost) AS val, NULL as perc
	FROM
	(SELECT DISTINCT directorate_code, branch_code FROM vw_base_structure WHERE YEAR(structure_date) = @pYear)z
	JOIN 
	(SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_capex GROUP BY branch_code
	UNION
	SELECT branch_code, SUM(total_cost) AS total_cost FROM wa_budget_HO_capex GROUP BY branch_code ) a
	ON z.branch_code = a.branch_code
	WHERE z.directorate_code = @pDirectorateCode --AND year = @pYear
	GROUP by z.directorate_code




END