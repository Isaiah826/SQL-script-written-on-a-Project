USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_monthly_score_card_zone]    Script Date: 2/28/2023 10:47:26 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER   PROCEDURE [dbo].[sp_insert_monthly_score_card_zone]
		
		@date DATE

AS

DECLARE @previous_month DATE,
		@closing_date	VARCHAR(8),
		@annualise DECIMAL(10)
		--@date DATE
		
		
--SET @date = '20220831'
SET @previous_month = DATEADD(month, -1, @date)
SET @annualise = DAY(DATEADD(DD,-1,DATEADD(month, DATEDIFF(month, 0, @date) + 1, 0)))  / DATEPART(dy,YEAR(@date) +'1231')
SET @closing_date = '20211031'



/** Remove existing records for loading date **/
DELETE FROM monthly_score_card_zone WHERE structure_date = @date;


/** Insert new records **/
INSERT INTO monthly_score_card_zone




SELECT A.zone_code,
		A.structure_date,
		A.month,
		A.year,
		B.perf_measure_code,
		B.performance_measure,
		B.weight,
		SUM(B.closing_balance) AS closing_balance,
		SUM(B.previous_actual) AS previous_actual,
		SUM(B.actual) AS actual,
		SUM(ISNULL(B.target, 0))AS target,
		B.performance,
		B.performance_description


	FROM
(SELECT DISTINCT zone_code,
		branch_code,
		structure_date,
		MONTH(structure_date) AS month,
		YEAR(structure_date) AS year
	FROM vw_base_structure 
	WHERE structure_date = @date ) A




/** ACCOUNT OPENED WITH MINIMUM BALANCE**/

LEFT JOIN
(
(SELECT '01' AS perf_measure_code,
		'Account Opened with Minimum Ave Balance' as performance_measure,
		'Account Opened with Minimum Ave Balance' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		SUM(b.prev_actual) AS  previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,		
		z.structure_date
	FROM

	(SELECT DISTINCT zone_code,
		branch_code,
		structure_date
		FROM vw_base_structure 
	WHERE structure_date = @date ) z
	
	LEFT JOIN 
		(SELECT a.acct_mgr_user_id AS staff_id, a.sol_id, 
		COUNT (DISTINCT a.foracid) AS actual, 
		a.eod_date
	FROM (SELECT foracid, ACCT_MGR_USER_ID, sol_id, eod_date 
			FROM accounts_open_monthly_base WHERE EOD_DATE = @date) a
	JOIN
	(SELECT foracid, acct_mgr_user_id, average_deposit, sol_id, eod_date 
				FROM deposits_base WHERE eod_date = @date) b
	ON a.sol_id = b.sol_id AND 1=1
	WHERE b.average_deposit > 2500 
	GROUP BY a.eod_date, a.sol_id, a.acct_mgr_user_id   ) a		/** Actual **/
	ON z.branch_code = a.SOL_ID AND 1=1

	LEFT JOIN 
		(SELECT a.acct_mgr_user_id AS staff_id, a.sol_id, 
		COUNT (DISTINCT a.foracid) AS prev_actual, 
		a.eod_date
	FROM (SELECT foracid, ACCT_MGR_USER_ID, sol_id, eod_date 
			FROM accounts_open_monthly_base WHERE EOD_DATE = @previous_month) a
	JOIN
	(SELECT foracid, acct_mgr_user_id, average_deposit, sol_id, eod_date 
				FROM deposits_base WHERE eod_date = @previous_month) b
	ON a.sol_id = b.sol_id AND 1=1
	WHERE b.average_deposit > 2500 
	GROUP BY a.eod_date, a.sol_id, a.acct_mgr_user_id   ) b		/** Previous Actual **/
	ON z.branch_code = b.SOL_ID AND 1=1

	LEFT JOIN
	(SELECT a.branch_code, 
		AVG(CASE WHEN MONTH(a.eod_date) = 1 THEN b.Jan WHEN MONTH(a.eod_date) = 2 THEN b.Feb WHEN MONTH(a.eod_date) = 3 THEN b.Mar
		WHEN MONTH(a.eod_date) = 4 THEN b.Apr WHEN MONTH(a.eod_date) = 5 THEN b.May WHEN MONTH(a.eod_date) = 6 THEN b.June
		WHEN MONTH(a.eod_date) = 7 THEN b.July WHEN MONTH(a.eod_date) = 8 THEN b.Aug WHEN MONTH(a.eod_date) = 9 THEN b.Sep
		WHEN MONTH(a.eod_date) = 10 THEN b.Oct WHEN MONTH(a.eod_date) = 11 THEN b.Nov WHEN MONTH(a.eod_date) = 12 THEN b.Dec END) AS target, 
		a.eod_date
	FROM mpr_balance_sheet_aggr a 
	JOIN	
	branch_account_open_target_base b 
	ON a.branch_code = b.branch_code AND a.eod_date = b.structure_date
	GROUP BY a.eod_date, a.branch_code) d					/** Targets **/
	ON z.branch_code = d.branch_code

	JOIN
	(SELECT zone_code,
			acct_open_min_bal AS weight
	FROM monthly_score_cards_weight_zone ) e				/** Weight **/
	ON z.zone_code = e.zone_code		
	GROUP BY z.structure_date, z.zone_code, e.weight		)  






/** ACCOUNT REACTIVATED **/

UNION


(SELECT '02' AS perf_measure_code,
		'Account Reactivated' as performance_measure,
		'Account Reactivated' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,			
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		LEFT JOIN 
		(SELECT branch_code,
			ISNULL(SUM(total_accounts), 0) AS actual,
			eod_date
		FROM accounts_reactivated_monthly_aggr
		WHERE eod_date = @date
		GROUP BY eod_date , branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
			ISNULL(SUM(total_accounts), 0) AS previous_actual,
			eod_date
		FROM accounts_reactivated_monthly_aggr
		WHERE eod_date = @previous_month
		GROUP BY eod_date , branch_code ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM account_reactivation_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON a.branch_code = d.branch_code
		LEFT JOIN
		(SELECT zone_code,
			acct_reactv AS weight
		FROM monthly_score_cards_weight_zone) e
		ON z.zone_code= e.zone_code		
	GROUP BY z.structure_date, z.zone_code, e.weight	)  





--/** ACCOUNT OPEN AND FUNDED**/

--UNION

--(SELECT '03' AS perf_measure_code,
--		'Account Open and Funded' as performance_measure,
--		'Account Open and Funded' AS performance_description,
--		z.zone_code,
--		ISNULL(e.weight, 0) AS weight,
--		0 AS closing_balance,
--		ISNULL(SUM(b.prev_actual), 0) AS previous_actual,
--		ISNULL(SUM(a.actual), 0) AS actual,
--		0 AS target,
--		0 AS performance,		
--		z.structure_date
--		FROM
--	(SELECT DISTINCT zone_code,
--				branch_code,
--				structure_date
--		FROM vw_base_structure 
--		WHERE structure_date = @date ) z
	
--	LEFT JOIN 
--	(SELECT a.acct_mgr_user_id AS staff_id, a.sol_id,
--		COUNT (DISTINCT a.foracid) AS actual, 
--		a.eod_date
--	FROM (SELECT foracid, ACCT_MGR_USER_ID, sol_id, eod_date 
--			FROM accounts_open_monthly_base WHERE EOD_DATE = @date) a
--	LEFT JOIN
--	(SELECT foracid, acct_mgr_user_id, sol_id, average_deposit, eod_date 
--				FROM deposits_base WHERE eod_date = @date) b
--	ON a.SOL_ID = b.sol_id
--	WHERE b.average_deposit > 10000 
--	GROUP BY a.eod_date, a.SOL_ID, a.acct_mgr_user_id ) a			/** Actual **/  
--	ON z.branch_code = a.SOL_ID AND 1=1

--	LEFT JOIN 
--	(SELECT a.acct_mgr_user_id AS staff_id, a.sol_id,
--		COUNT (DISTINCT a.foracid) AS prev_actual, 
--		a.eod_date
--	FROM (SELECT foracid, ACCT_MGR_USER_ID, sol_id, eod_date 
--			FROM accounts_open_monthly_base WHERE EOD_DATE = @previous_month) a
--	LEFT JOIN
--	(SELECT foracid, acct_mgr_user_id, sol_id, average_deposit, eod_date 
--				FROM deposits_base WHERE eod_date = @previous_month) b
--	ON a.SOL_ID = b.sol_id
--	WHERE b.average_deposit > 10000 
--	GROUP BY a.eod_date, a.SOL_ID, a.acct_mgr_user_id ) b			/** Previous Actual **/  
--	ON z.branch_code = b.SOL_ID AND 1=1
	
--	JOIN
--	(SELECT zone_code,
--			acct_open_funded AS weight
--	FROM monthly_score_cards_weight_zone) e
--	ON z.zone_code = e.zone_code		
--GROUP BY z.structure_date, z.zone_code, e.weight	)  






/** DIGITAL TO TOTAL ACQUSITION **/

UNION

(SELECT '04' AS perf_measure_code,
		'Digital to Total Acquisition' as performance_measure,
		'Digital to Total Acquisition' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,		
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
	(SELECT a.branch_code,
		SUM(a.total_open / NULLIF(b.total_open, 0)) AS actual,
		a.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.branch_code = b.branch_code AND a.eod_date = b.eod_date
	WHERE b.total_open > 0 AND a.eod_date = @date
	GROUP BY a.eod_date, a.branch_code ) a					/** Actual **/
	ON z.branch_code = a.branch_code
	LEFT JOIN
	(SELECT a.branch_code,
		SUM(a.total_open / NULLIF(b.total_open, 0)) AS previous_actual,
		a.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.branch_code = b.branch_code AND a.eod_date = b.eod_date
	WHERE b.total_open > 0 AND a.eod_date = @previous_month
	GROUP BY a.eod_date, a.branch_code ) b				/** Previous Actual **/
	ON z.branch_code = b.branch_code

	LEFT JOIN
	(SELECT zone_code,
			dig_tot_acq AS weight
	FROM monthly_score_cards_weight_zone ) e
	ON z.zone_code = e.zone_code		
GROUP BY z.structure_date, z.zone_code, e.weight	)  




/** TRADITIONAL TO TOTAL ACQUISITION **/

UNION

( SELECT '05' AS perf_measure_code, 
		'Traditional to Total Acquisition' as performance_measure,
		'Traditional to Total Acquisition' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,		
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
	
	(SELECT b.branch_code,
		((SUM(b.total_open) - SUM(a.total_open)) / NULLIF(SUM(b.total_open), 0)) AS actual,
		b.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.branch_code = b.branch_code AND a.eod_date = b.eod_date
	WHERE b.total_open > 0 AND a.eod_date = @date
	GROUP BY b.eod_date, b.branch_code ) a			/** Actual **/ 
	ON z.branch_code = a.branch_code AND 1=1

	LEFT JOIN
	(SELECT b.branch_code,
		((SUM(b.total_open) - SUM(a.total_open)) / NULLIF(SUM(b.total_open), 0)) AS previous_actual,
		b.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.branch_code = b.branch_code AND a.eod_date = b.eod_date
	WHERE b.total_open > 0 AND a.eod_date = @previous_month
	GROUP BY b.eod_date, b.branch_code ) b			/** Previous Actual **/
	ON z.branch_code = b.branch_code
	
	LEFT JOIN
	(SELECT zone_code,
			trad_tot_acq AS weight
	FROM monthly_score_cards_weight_zone) e
	ON z.zone_code = e.zone_code	
GROUP BY z.structure_date, z.zone_code, e.weight	)  





/** INCREMENTAL CASA VOLUME **/

UNION
		
( SELECT '06' AS perf_measure_code, 
		'Incremental CASA Volume' as performance_measure,
		'Incremental CASA Volume (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		SUM(ISNULL(c.casa_avg, 0.00)) AS closing_balance,
		SUM(ISNULL(b.casa_avg, 0.00) - ISNULL(c.casa_avg, 0.00)) AS previous_actual,
		SUM(ISNULL(a.casa_avg, 0.00) - ISNULL(c.casa_avg, 0.00)) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.casa_avg) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.casa_avg)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT  A.branch_code AS branch_code,
		SUM(a.avg_vol) As casa_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'CASA' AND eod_date = @date
		GROUP BY a.eod_date, a.branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT  A.branch_code AS branch_code,
		SUM(a.avg_vol) As casa_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'CASA' AND eod_date = @previous_month
		GROUP BY a.eod_date, a.branch_code ) b			/** Previous Balance **/
		ON z.branch_code = b.branch_code

		LEFT JOIN
		(SELECT  A.branch_code AS branch_code,
		SUM(a.avg_vol) As casa_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'CASA' AND eod_date = @closing_date
		GROUP BY a.eod_date, a.branch_code ) c			/** Closing Balance **/
		ON z.branch_code = c.branch_code
				
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM casa_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code

		JOIN
		(SELECT zone_code,
				inc_casa_vol AS weight
		FROM monthly_score_cards_weight_zone) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)  


	   
/** TENURED VOLUME **/

UNION

(SELECT '07' AS perf_measure_code,
		'Tenured Volume' AS performance_measure,
		'Tenured Volume (N''000)' AS performance_description,
		z.zone_code,
		0 AS weight,
		SUM(ISNULL(c.tenured_avg, 0.00)) AS closing_balance,
		SUM(ISNULL(b.tenured_avg, 0.00)) AS previous_actual,
		SUM(ISNULL(a.tenured_avg, 0.00)) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		0.00 AS performance,
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		LEFT JOIN 
		(SELECT  A.branch_code AS branch_code,
		SUM(a.avg_vol) As tenured_avg,
		SUM(a.naira_value) AS tenured_actual,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'TERM DEPOSIT' AND eod_date = @date
		GROUP BY a.eod_date, a.branch_code ) a					/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1

		LEFT JOIN
		(SELECT  A.branch_code AS branch_code,
		SUM(a.avg_vol) As tenured_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'TERM DEPOSIT' AND eod_date = @previous_month
		GROUP BY a.eod_date, a.branch_code ) b					/** Previous Actual **/
		ON z.branch_code = b.branch_code

		LEFT JOIN
		(SELECT  A.branch_code AS branch_code,
		SUM(a.avg_vol) As tenured_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'TERM DEPOSIT' AND eod_date = @closing_date
		GROUP BY a.eod_date, a.branch_code ) c					/** Closing Balance **/
		ON z.branch_code = c.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM tenured_deposit_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code
		
	GROUP BY z.structure_date, z.zone_code			)  




/** TOTAL CUMMULATIVE DEPOSIT **/

UNION

(SELECT '08' AS perf_measure_code,
		'Total Cummulative Deposit' as performance_measure,
		'Total Cummulative Deposit (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		ISNULL(SUM(c.closing_balance), 0) AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0 ) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,		
		z.structure_date
		
		FROM
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT  branch_code,
		SUM(average_balance) As actual,
		eod_date
		FROM deposits_aggr
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT  branch_code,
		SUM(average_balance) As previous_actual,
		eod_date
		FROM deposits_aggr
		WHERE eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		LEFT JOIN
		(SELECT  branch_code,
		SUM(average_balance) As closing_balance,
		eod_date
		FROM deposits_aggr
		WHERE eod_date = @closing_date
		GROUP BY eod_date, branch_code ) c			/** Closing Balance **/
		ON z.branch_code = c.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM total_deposit_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON a.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				tot_cum_dep AS weight
		FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)  

		


/** DOMICILIARY VOLUME **/

UNION

(SELECT '09' AS perf_measure_code,
		'Domiciliary Volume' as performance_measure,
		'Domiciliary Volume (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		ISNULL(SUM(c.closing_balance), 0) AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
			(SELECT A.branch_code AS branch_code,
					SUM(a.avg_vol) As actual,
					a.eod_date
			FROM mpr_balance_sheet_aggr a
			JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
			WHERE b.score_card_class IN ('DOMICILIARY BALANCE') AND eod_date = @date
			GROUP BY a.eod_date, a.branch_code ) a					/** Actual **/
			ON z.branch_code = a.branch_code AND 1=1
			LEFT JOIN
			(SELECT A.branch_code AS branch_code,
					SUM(a.avg_vol) As previous_actual,
					a.eod_date
			FROM mpr_balance_sheet_aggr a
			JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
			WHERE b.score_card_class IN ('DOMICILIARY BALANCE') AND eod_date = @previous_month
			GROUP BY a.eod_date, a.branch_code ) b					/**Previous Actual **/
			ON z.branch_code = b.branch_code
			LEFT JOIN
			(SELECT A.branch_code AS branch_code,
					SUM(a.avg_vol) As closing_balance,
					a.eod_date
			FROM mpr_balance_sheet_aggr a
			JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
			WHERE b.score_card_class IN ('DOMICILIARY BALANCE') AND eod_date = @closing_date
			GROUP BY a.eod_date, a.branch_code ) c					/** Closing Balance **/
			ON a.branch_code = c.branch_code
			LEFT JOIN
			(SELECT branch_code,
					SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
					WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
					WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
					WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
			FROM domiciliary_budget_branch
			GROUP BY branch_code	) d					/** Target **/
			ON z.branch_code = d.branch_code
			JOIN
			(SELECT zone_code,
					inc_dom_vol AS weight
			FROM monthly_score_cards_weight_zone ) e
			ON z.zone_code = e.zone_code
		GROUP BY z.structure_date, z.zone_code, e.weight	)


			

/** COST OF FUNDS **/

UNION

(SELECT '10' AS perf_measure_code,
		'Cost of Funds' as performance_measure,
		'Cost of Funds (%)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) <= 5 THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ 5) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM		
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		
		JOIN 
		(SELECT a.branch_code,
				SUM(((Total_Interest - Other_liabilities) / deposit) * @annualise) AS actual,
				a.eod_date
		FROM
			(SELECT branch_code, 
					ISNULL(SUM(interest_inc_exp), 0.00) AS Total_Interest,
					ISNULL(SUM(CASE WHEN name = 'OTHER LIABILITIES' THEN interest_inc_exp END), 0.00) AS Other_liabilities,
					eod_date
			FROM mpr_balance_sheet_aggr 
			WHERE eod_date = @date
			GROUP BY eod_date, branch_code )a
			JOIN
			(SELECT branch_code,
			SUM(average_balance) AS deposit,
			eod_date
			FROM deposits_aggr	 /** Getting Total Deposit **/
			WHERE eod_date = @date
			GROUP BY eod_date, branch_code)  b
			ON a.branch_code = b.branch_code
			WHERE b.deposit > 0
		GROUP BY a.eod_date, a.branch_code	) a						/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
			
		LEFT JOIN
		(SELECT a.branch_code,
				SUM(((Total_Interest - Other_liabilities) / deposit) * @annualise) AS previous_actual,
				a.eod_date
		FROM
			(SELECT branch_code, 
					ISNULL(SUM(interest_inc_exp), 0.00) AS Total_Interest,
					ISNULL(SUM(CASE WHEN name = 'OTHER LIABILITIES' THEN interest_inc_exp END), 0.00) AS Other_liabilities,
					eod_date
			FROM mpr_balance_sheet_aggr 
			WHERE eod_date = @previous_month
			GROUP BY eod_date, branch_code )a
			JOIN
			(SELECT branch_code,
			SUM(average_balance) AS deposit,
			eod_date
			FROM deposits_aggr	 /** Getting Total Deposit **/
			WHERE eod_date = @previous_month
			GROUP BY eod_date, branch_code)  b
			ON a.branch_code = b.branch_code
			WHERE b.deposit > 0
		GROUP BY a.eod_date, a.branch_code	) b						/** Previous Actual **/
		ON z.branch_code = b.branch_code

		--LEFT JOIN
		--(SELECT a.branch_code,
		--		SUM(((Total_Interest - Other_liabilities) / deposit) * @annualise) AS closing_balance,
		--		a.eod_date
		--FROM
		--	(SELECT branch_code, 
		--			ISNULL(SUM(interest_inc_exp), 0.00) AS Total_Interest,
		--			ISNULL(SUM(CASE WHEN name = 'OTHER LIABILITIES' THEN interest_inc_exp END), 0.00) AS Other_liabilities,
		--			eod_date
		--	FROM mpr_balance_sheet_aggr 
		--	WHERE eod_date = @closing_date
		--	GROUP BY eod_date, branch_code )a
		--	JOIN
		--	(SELECT branch_code,
		--	SUM(average_balance) AS deposit,
		--	eod_date
		--	FROM deposits_aggr	 /** Getting Total Deposit **/
		--	WHERE eod_date = @closing_date
		--	GROUP BY eod_date, branch_code)  b
		--	ON a.branch_code = b.branch_code
		--	WHERE b.deposit > 0
		--GROUP BY a.eod_date, a.branch_code	) c				/** Closing Balance **/
		--ON z.branch_code = c.branch_code
		LEFT JOIN
		(SELECT DISTINCT zone_code,
				5 AS target,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) d
		ON z.zone_code = d.zone_code
		LEFT JOIN
			(SELECT zone_code,
					cost_funds AS weight
			FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, d.target, e.weight	)
			
			

/** FEE INCOME **/

UNION

(SELECT '11' AS perf_measure_code,
		'Fee Income' as performance_measure,
		'Fee Income (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
	(SELECT branch_code,
			SUM(total_income) AS actual,
			eod_date
	FROM comm_fees_aggr
	WHERE eod_date = @date
	GROUP BY eod_date, branch_code ) a			/** Actual **/
	ON z.branch_code = a.branch_code AND 1=1
	LEFT JOIN
	(SELECT branch_code,
			SUM(total_income) AS previous_actual,
			eod_date
	FROM comm_fees_aggr
	WHERE eod_date = @previous_month
	GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
	ON z.branch_code = b.branch_code
	--LEFT JOIN
	--(SELECT branch_code,
	--		SUM(total_income) AS closing_balance,
	--		eod_date
	--FROM comm_fees_aggr
	--WHERE eod_date = @closing_date
	--GROUP BY eod_date, branch_code ) c			/** Closing Balance **/
	--ON z.branch_code = c.branch_code
	LEFT JOIN
	(SELECT branch_code,
			SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
			WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
			WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
			WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
	FROM fee_income_budget_branch
	GROUP BY branch_code	) d					/** Target **/
	ON z.branch_code = d.branch_code
	JOIN
	(SELECT zone_code,
			fee_inc AS weight
			FROM monthly_score_cards_weight_zone ) e
	ON z.zone_code = e.zone_code
GROUP BY z.structure_date, z.zone_code, e.weight	)
		



/** PBT **/

UNION

(SELECT '12' AS perf_measure_code,
		'PBT' as performance_measure,
		'PBT (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT branch_code AS branch_code,
				SUM(int_inc_expense) AS actual,
				eod_date
		FROM mpr_inc_stmt_aggr 
		WHERE name = 'PROFIT BEFORE TAX' AND eod_date = @date
		GROUP BY eod_date, branch_code ) a				/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code AS branch_code,
				SUM(int_inc_expense) AS previous_actual,
				eod_date
		FROM mpr_inc_stmt_aggr 
		WHERE name = 'PROFIT BEFORE TAX' AND eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b				/** Previous Actual **/
		ON z.branch_code = b.branch_code
		--LEFT JOIN
		--(SELECT branch_code AS branch_code,
		--		SUM(int_inc_expense) AS closing_balance,
		--		eod_date
		--FROM mpr_inc_stmt_aggr 
		--WHERE name = 'PROFIT BEFORE TAX' AND eod_date = @closing_date
		--GROUP BY eod_date, branch_code ) c				/** Closing Balance **/
		--ON z.branch_code = c.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM pbt_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				pbt AS weight
				FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)


/** PBT YTD **/

UNION

(SELECT '13' AS perf_measure_code,
		'PBT YTD' as performance_measure,
		'PBT YTD BRANCH (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT a.branch_code, 
				SUM(CASE WHEN b.int_inc_expense < 0 THEN 0.00 ELSE b.int_inc_expense END) AS actual, 
				a.eod_date 
		FROM mpr_inc_stmt_aggr a
		LEFT JOIN mpr_inc_stmt_aggr B
		ON a.branch_code = b.branch_code
		AND datediff(year, b.eod_date, a.eod_date) = 0 
        AND b.eod_date <= a.eod_date
		WHERE a.name = 'PROFIT BEFORE TAX' AND b.name = 'PROFIT BEFORE TAX' AND a.eod_date = @date
		GROUP BY a.eod_date, a.branch_code ) a				/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1

		LEFT JOIN
		(SELECT a.branch_code, 
				SUM(CASE WHEN b.int_inc_expense < 0 THEN 0.00 ELSE b.int_inc_expense END) AS previous_actual, 
				a.eod_date 
		FROM mpr_inc_stmt_aggr a
		LEFT JOIN mpr_inc_stmt_aggr B
		ON a.branch_code = b.branch_code
		AND datediff(year, b.eod_date, a.eod_date) = 0 
        AND b.eod_date <= a.eod_date
		WHERE a.name = 'PROFIT BEFORE TAX' AND b.name = 'PROFIT BEFORE TAX' AND a.eod_date = @previous_month
		GROUP BY a.eod_date, a.branch_code ) b				/** Previous Actual **/
		ON z.branch_code = b.branch_code

		--LEFT JOIN
		--(SELECT a.branch_code, 
		--		SUM(CASE WHEN b.int_inc_expense < 0 THEN 0.00 ELSE b.int_inc_expense END) AS closing_balance, 
		--		a.eod_date 
		--FROM mpr_inc_stmt_aggr a
		--LEFT JOIN mpr_inc_stmt_aggr B
		--ON a.branch_code = b.branch_code
		--AND datediff(year, b.eod_date, a.eod_date) = 0 
  --      AND b.eod_date <= a.eod_date
		--WHERE a.name = 'PROFIT BEFORE TAX' AND b.name = 'PROFIT BEFORE TAX' AND a.eod_date = @closing_date
		--GROUP BY a.eod_date, a.branch_code ) c					/** Closing Balance **/
		--ON z.branch_code = c.branch_code

		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN (Jan + Feb) WHEN MONTH(@date) = 3 THEN (Jan + Feb + Mar)
				WHEN MONTH(@date) = 4 THEN (Jan + Feb + Mar + Apr) WHEN MONTH(@date) = 5 THEN (Jan + Feb + Mar + Apr + May) 
				WHEN MONTH(@date) = 6 THEN (Jan + Feb + Mar + Apr + May + June) WHEN MONTH(@date) = 7 THEN (Jan + Feb + Mar + Apr + May + June + July) 
				WHEN MONTH(@date) = 8 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug) 
				WHEN MONTH(@date) = 9 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep)
				WHEN MONTH(@date) = 10 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct) 
				WHEN MONTH(@date) = 11 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct + Nov) 
				WHEN MONTH(@date) = 12 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct + Nov + Dec) END) AS target
		FROM pbt_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON a.branch_code = d.branch_code

		JOIN
		(SELECT zone_code,
				pbt_ytd AS weight
				FROM monthly_score_cards_weight_zone) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)



--/** TOTAL CONTRIBUTIONS YTD**/

--UNION

--(SELECT '14' AS perf_measure_code,
--		'Total Contributions' as performance_measure,
--		'Total Contribution ' AS performance_description,
--		z.zone_code,
--		ISNULL(e.weight, 0) AS weight,
--		ISNULL(SUM(c.closing_balance), 0) AS closing_balance,
--		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
--		ISNULL(SUM(a.actual), 0) AS actual,
--		ISNULL(SUM(d.target), 0) AS target,
--		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
--					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,
--		z.structure_date
--		FROM
		
--		(SELECT DISTINCT zone_code,
--				branch_code,
--				structure_date
--		FROM vw_base_structure 
--		WHERE structure_date = @date ) z
--		JOIN 
--		(SELECT a.branch_code,
--		SUM(b.int_inc_expense) AS actual,
--		a.eod_date
--		FROM mpr_inc_stmt_aggr a
--		LEFT JOIN mpr_inc_stmt_aggr b
--		ON a.branch_code = b.branch_code
--			AND datediff(year, b.eod_date, a.eod_date) = 0 
--			AND b.eod_date <= a.eod_date
--		WHERE a.name = 'CONTRIBUTION' AND b.name = 'CONTRIBUTION'  AND a.eod_date = @date
--		GROUP BY a.eod_date, a.branch_code) a			/** Actual **/
--		ON z.branch_code = a.branch_code

--		LEFT JOIN
--		(SELECT a.branch_code,
--		SUM(b.int_inc_expense) AS previous_actual,
--		a.eod_date
--		FROM mpr_inc_stmt_aggr a
--		LEFT JOIN mpr_inc_stmt_aggr b
--		ON a.branch_code = b.branch_code
--			AND datediff(year, b.eod_date, a.eod_date) = 0 
--			AND b.eod_date <= a.eod_date
--		WHERE a.name = 'CONTRIBUTION' AND b.name = 'CONTRIBUTION'  AND a.eod_date = @previous_month
--		GROUP BY a.eod_date, a.branch_code) b			/** Previous Actual **/
--		ON a.branch_code = b.branch_code

--		LEFT JOIN
--		(SELECT a.branch_code,
--		SUM(b.int_inc_expense) AS closing_balance,
--		a.eod_date
--		FROM mpr_inc_stmt_aggr a
--		LEFT JOIN mpr_inc_stmt_aggr b
--		ON a.branch_code = b.branch_code
--			AND datediff(year, b.eod_date, a.eod_date) = 0 
--			AND b.eod_date <= a.eod_date
--		WHERE a.name = 'CONTRIBUTION' AND b.name = 'CONTRIBUTION'  AND a.eod_date = @closing_date
--		GROUP BY a.eod_date, a.branch_code) c			/** Closing Balance **/
--		ON a.branch_code = c.branch_code

--		LEFT JOIN
--		(SELECT branch_code,
--				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN (Jan + Feb) WHEN MONTH(@date) = 3 THEN (Jan + Feb + Mar)
--				WHEN MONTH(@date) = 4 THEN (Jan + Feb + Mar + Apr) WHEN MONTH(@date) = 5 THEN (Jan + Feb + Mar + Apr + May) 
--				WHEN MONTH(@date) = 6 THEN (Jan + Feb + Mar + Apr + May + June) WHEN MONTH(@date) = 7 THEN (Jan + Feb + Mar + Apr + May + June + July) 
--				WHEN MONTH(@date) = 8 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug) 
--				WHEN MONTH(@date) = 9 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep)
--				WHEN MONTH(@date) = 10 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct) 
--				WHEN MONTH(@date) = 11 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct + Nov) 
--				WHEN MONTH(@date) = 12 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct + Nov + Dec) END) AS target
--		FROM contributions_budget_branch
--		GROUP BY branch_code	) d					/** Target **/
--		ON a.branch_code = d.branch_code

--		JOIN
--		(SELECT zone_code,
--				tot_cont AS weight
--		FROM monthly_score_cards_weight_zone) e
--		ON z.zone_code = e.zone_code
--	GROUP BY z.structure_date, z.zone_code, e.weight	)


		

/** GROSS LOANS **/

UNION

(SELECT '15' AS perf_measure_code,
		'Gross Loans' as performance_measure,
		'Gross Loans (N''000)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		ISNULL(SUM(c.closing_balance), 0) AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,		
		z.structure_date
		FROM
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT  a.branch_code,
				SUM(a.avg_vol * -1) AS actual,
				a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS' AND eod_date = @date
		GROUP BY a.eod_date, branch_code) a					/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1

		LEFT JOIN
		(SELECT  a.branch_code,
				SUM(a.avg_vol * -1) AS previous_actual,
				a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS' AND eod_date = @previous_month
		GROUP BY a.eod_date, branch_code) b					/** Previous Actual **/
		ON z.branch_code = b.branch_code

		LEFT JOIN
		(SELECT  a.branch_code,
				SUM(a.avg_vol * -1) AS closing_balance,
				a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS' AND eod_date = @closing_date
		GROUP BY a.eod_date, branch_code) c					/** Closing Balance **/
		ON z.branch_code = c.branch_code
		
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM loan_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code

		JOIN
		(SELECT zone_code,
				gross_loan AS weight
		FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)
	


/** NON-PERFORMING LOANS **/

UNION

(SELECT '16' AS perf_measure_code,
		'Non-Performing Loans' as performance_measure,
		'Non-Performing Loans (%)' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL((SUM(b.npl_avg)/NULLIF(SUM(d2.prev_month_target), 0)), 0) AS previous_actual,
		ISNULL((SUM(a.npl_avg)/NULLIF(SUM(d1.month_target), 0)), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.npl_avg) <= (SUM(d1.month_target)*0.05) THEN e.weight
					ELSE 0 END AS performance,
		z.structure_date
		FROM	
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		LEFT JOIN 
		(SELECT branch_code,
				SUM(balance) AS npl_act,
				SUM(average) AS npl_avg,
				eod_date
		FROM npl_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
				SUM(balance) AS npl_act,
				SUM(average) AS npl_avg,
				eod_date
		FROM npl_base
		WHERE eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		--LEFT JOIN
		--(SELECT branch_code,
		--		SUM(balance) AS npl_act,
		--		SUM(average) AS npl_avg,
		--		eod_date
		--FROM npl_base
		--WHERE eod_date = @closing_date
		--GROUP BY eod_date, branch_code ) c			/** Closing Balance **/			
		--ON z.branch_code = c.branch_code
		LEFT JOIN
		(SELECT  a.branch_code, SUM(a.naira_value * -1) * 0.05 AS month_target
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS' AND eod_date = @date
		GROUP BY a.eod_date, branch_code) d1			/** Actual Targets **/
		ON z.branch_code = d1.branch_code 
		LEFT JOIN
		(SELECT  a.branch_code,  SUM(a.naira_value * -1) * 0.05 AS prev_month_target
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS' AND eod_date = @previous_month
		GROUP BY a.eod_date, branch_code) d2			/** Prev Month Targets **/
		ON z.branch_code = d2.branch_code 
		LEFT JOIN
		(SELECT DISTINCT zone_code,
				5 AS target,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) d
		ON z.zone_code = d.zone_code
		LEFT JOIN
		(SELECT zone_code,
				npl AS weight
		FROM monthly_score_cards_weight_zone) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, d.target, e.weight	)


/** CARDS ACTIVATION **/

UNION

(SELECT '17' AS perf_measure_code,
		'Cards Activation' as performance_measure,
		'Cards Activation' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT SOL_ID AS branch_code,
				COUNT(DISTINCT foracid) AS actual,
				EOMONTH(activated_date) AS eod_date
		FROM cards_base
		WHERE EOMONTH(activated_date) = @date
		GROUP BY EOMONTH(activated_date), SOL_ID) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT SOL_ID AS branch_code,
				COUNT(DISTINCT foracid) AS previous_actual,
				EOMONTH(activated_date) AS eod_date
		FROM cards_base
		WHERE EOMONTH(activated_date) = @previous_month
		GROUP BY EOMONTH(activated_date), SOL_ID) b			/** Previous Actual **/
		ON a.branch_code = b.branch_code

		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM cards_activation_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				cards_actv AS weight
		FROM monthly_score_cards_weight_zone) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)

	

/** CREDIT CARD ISSUANCE**/

UNION

(SELECT '18' AS perf_measure_code,
		'Credit Card Issuance' as performance_measure,
		'Credit Card Issuance' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT SOL_ID AS branch_code,
				COUNT(DISTINCT foracid) AS actual,
				EOMONTH(issue_date) AS eod_date
		FROM cards_base
		WHERE card_type = 'CREDIT' AND EOMONTH(issue_date) = @date
		GROUP BY EOMONTH(issue_date), SOL_ID ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT SOL_ID AS branch_code,
				COUNT(DISTINCT foracid) AS previous_actual,
				EOMONTH(issue_date) AS eod_date
		FROM cards_base
		WHERE card_type = 'CREDIT' AND EOMONTH(issue_date) = @previous_month
		GROUP BY EOMONTH(issue_date), SOL_ID ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM credit_card_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				credit_card AS weight
		FROM monthly_score_cards_weight_zone) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)




/** DATA QUALITY INDEX **/

UNION

(SELECT '19' AS perf_measure_code,
		'Data Quality Index' as performance_measure,
		'Data Quality Index' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0)  AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,		
		z.structure_date
		FROM	
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT branch_code,
				branch_avg_dqi AS actual,
				eod_date
		FROM dqi_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code, branch_avg_dqi ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
				branch_avg_dqi AS previous_actual,
				eod_date
		FROM dqi_base
		WHERE eod_date = @previous_month
		GROUP BY eod_date, branch_code, branch_avg_dqi ) b			/** Previous Actual **/
		ON a.branch_code = b.branch_code
		LEFT JOIN
		(SELECT branch_code,
				avg_dqi_target AS target,
				eod_date
		FROM dqi_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code, avg_dqi_target ) d			/** Target **/
		ON a.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				dqi AS weight
		FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)



/** DIGITAL PENETRATION **/


UNION

(SELECT '20' AS perf_measure_code,
		'Digital Penetration' as performance_measure,
		'Digital Penetration' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) > SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,		
		z.structure_date
		FROM	

		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT branch_code,
				SUM(actual) AS actual,
				eod_date
		FROM digital_penetration_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
				SUM(actual) AS previous_actual,
				eod_date
		FROM digital_penetration_base
		WHERE eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(budget) AS target,
				eod_date
		FROM digital_penetration_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code ) d			/** Target **/
		ON z.branch_code = d.branch_code AND 1=1
		JOIN
		(SELECT zone_code,
				dig_pen AS weight
		FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight		)





/** NO OF AGENTS **/

UNION

(SELECT '21' AS perf_measure_code,
		'No of Agents' as performance_measure,
		'NO of Agents' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT branch_code,
				COUNT(DISTINCT merchant_name) AS actual,
				eod_date
		FROM pos_score_card_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
				COUNT(DISTINCT merchant_name) AS previous_actual,
				eod_date
		FROM pos_score_card_base
		WHERE eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM agents_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON a.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				no_agents AS weight
		FROM monthly_score_cards_weight_zone) e		/** Weight **/
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)




/** POS DEPLOYED / MCASH / AGENT  **/

UNION

(SELECT '22' AS perf_measure_code,
		'POS Deployed / Volume / MCASH / AGENT' as performance_measure,
		'NO OF POS/MCASH  Deployed' AS performance_description,
		z.zone_code,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		CASE WHEN SUM(a.actual) >= SUM(d.target) THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(SUM(d.target), 0)) * e.weight), 2)) END AS performance,	
		z.structure_date
		FROM
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT branch_code,
				COUNT(DISTINCT terminal_id) AS actual,
				eod_date
		FROM pos_score_card_base
		WHERE eod_date = @date
		GROUP BY eod_date, branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
				COUNT(DISTINCT terminal_id) AS previous_actual,
				eod_date
		FROM pos_score_card_base
		WHERE eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
		ON z.branch_code = b.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM pos_deployed_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code
		JOIN
		(SELECT zone_code,
				pos_dep AS weight
		FROM monthly_score_cards_weight_zone ) e
		ON z.zone_code = e.zone_code
	GROUP BY z.structure_date, z.zone_code, e.weight	)


	

	   
/** POS VOLUME **/

UNION

(SELECT '23' AS perf_measure_code,
		'POS Volume' as performance_measure,
		'POS Volume' AS performance_description,
		z.zone_code,
		0 AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(SUM(d.target), 0) AS target,
		0 AS performance,
		z.structure_date
		FROM		
		
		(SELECT DISTINCT zone_code,
				branch_code,
				structure_date
		FROM vw_base_structure 
		WHERE structure_date = @date ) z
		JOIN 
		(SELECT branch_code,
				SUM(volume) AS actual,
				eod_date
		FROM pos_score_card_base
		WHERE status = 'Active' AND eod_date = @date
		GROUP BY eod_date, branch_code ) a			/** Actual **/
		ON z.branch_code = a.branch_code AND 1=1
		LEFT JOIN
		(SELECT branch_code,
				SUM(volume) AS previous_actual,
				eod_date
		FROM pos_score_card_base
		WHERE status = 'Active' AND eod_date = @previous_month
		GROUP BY eod_date, branch_code ) b			/** Previous Actual **/
		ON a.branch_code = b.branch_code
		LEFT JOIN
		(SELECT branch_code,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM pos_volume_budget_branch
		GROUP BY branch_code	) d					/** Target **/
		ON z.branch_code = d.branch_code AND 1=1
		
	GROUP BY z.structure_date, z.zone_code		)


/** CHANNELS TRANSACTION **/

-- (24)




			)B

ON  A.zone_code = B.zone_code AND A.structure_date = B.structure_date

--WHERE B.perf_measure_code IS NOT NULL AND performance_description IS NOT NULL AND B.target IS NOT NULL

GROUP BY A.zone_code, A.structure_date, A.month, A.year, B.perf_measure_code, B.performance_measure, B.performance_description, B.weight, B.performance

ORDER BY A.zone_code, B.perf_measure_code asc










