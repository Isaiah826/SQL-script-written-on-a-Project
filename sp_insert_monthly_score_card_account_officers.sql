USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_monthly_score_card_account_officers]    Script Date: 2/28/2023 10:08:38 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_insert_monthly_score_card_account_officers]
		
		@date DATE

AS

DECLARE @previous_month DATE,
		@closing_date	VARCHAR(8),
		@annualise DECIMAL(10),
		@suffix VARCHAR(50)	


SET @previous_month = DATEADD(month, -1, @date)
SET @annualise = MONTH(@date) / DATEDIFF(day, YEAR(@date), YEAR(@date)+1)
SET @closing_date = '20211031'



/** Remove existing records for loading date **/
DELETE FROM monthly_score_card_account_officers WHERE structure_date = @date;


/** Insert new records **/
INSERT INTO monthly_score_card_account_officers

SELECT	A.staff_id,
		A.staff_type,
		A.staff_grade,
		A.sbu_id,
		A.structure_date,
		A.month,
		A.year,
		B.perf_measure_code,
		B.performance_measure,
		B.weight,
		B.closing_balance,
		B.previous_actual,
		B.actual,
		B.target,
		B.performance,
		B.performance_description

	FROM


(SELECT staff_id, 
		staff_type, 
		staff_grade,
		sbu_id,
		branch_code,
		structure_date,
		MONTH(structure_date) AS month,
		YEAR(structure_date) AS year
	FROM account_officers
	WHERE structure_date = @date AND sbu_id In ('S001', 'S002') ) A




/** ACCOUNT OPENED WITH MINIMUM BALANCE**/

LEFT JOIN
(

(SELECT '01' AS perf_measure_code,
		'Account Opened with Minimum Ave Balance' as performance_measure,
		'Account Opened with Minimum Ave Balance' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,		
		a.eod_date
	FROM
	(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
	LEFT JOIN
	(SELECT a.acct_mgr_user_id AS staff_id, 
		COUNT (DISTINCT a.foracid) AS actual, 
		a.eod_date
	FROM (SELECT foracid, ACCT_MGR_USER_ID, eod_date 
			FROM accounts_open_monthly_base WHERE EOD_DATE = @date) a
	LEFT JOIN
	(SELECT foracid, acct_mgr_user_id, average_deposit, eod_date 
				FROM deposits_base WHERE eod_date = @date) b
	ON a.ACCT_MGR_USER_ID = b.acct_mgr_user_id
	--JOIN	
	--(SELECT a.staff_id, SUM(b.avg_vol) AS min_bal 
	--FROM 	(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) a
	--LEFT JOIN	staff_account_open_target_base b
	--ON a.sbu_id = b.sbu_id AND (a.staff_grade = b.grade_code OR a.staff_type = b.grade_code) --AND a.structure_date = b.structure_date
	--GROUP BY a.structure_date, a.staff_id) c /** getting minimum balance targets **/
	--ON b.acct_mgr_user_id = c.staff_id
	WHERE b.average_deposit > 2500 
	GROUP BY a.eod_date, a.acct_mgr_user_id   ) a		/** Actual **/
	ON z.staff_id = a.staff_id AND 1=1

	LEFT JOIN
	(SELECT a.acct_mgr_user_id AS staff_id, 
		COUNT (DISTINCT a.foracid) AS previous_actual, 
		a.eod_date
	FROM (SELECT foracid, ACCT_MGR_USER_ID, eod_date 
			FROM accounts_open_monthly_base WHERE EOD_DATE = @previous_month) a
	LEFT JOIN
	(SELECT foracid, acct_mgr_user_id, average_deposit, eod_date 
				FROM deposits_base WHERE eod_date = @previous_month) b
	ON a.ACCT_MGR_USER_ID = b.acct_mgr_user_id
	--JOIN	
	--(SELECT a.staff_id, SUM(b.avg_vol) AS min_bal 
	--FROM 	account_officers a
	--LEFT JOIN	staff_account_open_target_base b
	--ON a.sbu_id = b.sbu_id AND a.staff_grade = b.grade_code AND a.structure_date = b.structure_date
	--GROUP BY a.structure_date, a.staff_id) c /** getting minimum balance targets **/
	--ON b.acct_mgr_user_id = c.staff_id
	WHERE b.average_deposit > 2500 
	GROUP BY a.eod_date, a.acct_mgr_user_id ) b	/** getting previous actual **/
	ON z.staff_id = b.staff_id AND 1=1

	LEFT JOIN
	(SELECT staff_id,
		budget AS target
		--eod_date
	FROM account_open_min_bal_target) d		/** Targets **/
	ON a.staff_id = d.staff_id 	
	LEFT JOIN
	(SELECT b.staff_id,
			a.acct_open_min_bal AS weight
	FROM monthly_score_cards_weight_account_officers a
	JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
	ON z.staff_id = e.staff_id	AND 1=1	
GROUP BY z.staff_id, a.eod_date, e.weight, d.target			)




/** ACCOUNT REACTIVATED **/

UNION 

(SELECT '02' AS perf_measure_code,
		'Account Reactivated' as performance_measure,
		'Account Reactivated' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,	
		a.eod_date
		
	FROM
	(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
	LEFT JOIN
	(SELECT staff_id,
	ISNULL(SUM(total_accounts), 0) AS actual,
	EOMONTH(eod_date) AS eod_date
	FROM accounts_reactivated_monthly_aggr
	WHERE EOMONTH(eod_date) = @date
	GROUP BY EOMONTH(eod_date) , staff_id ) a							/** Actual **/
	ON z.staff_id = a.staff_id AND 1=1
	LEFT JOIN
	(SELECT staff_id,
	ISNULL(SUM(total_accounts), 0) AS previous_actual,
	EOMONTH(eod_date) AS eod_date
	FROM accounts_reactivated_monthly_aggr
	WHERE EOMONTH(eod_date) = @previous_month
	GROUP BY EOMONTH(eod_date) , staff_id ) b							/** Previous Actual **/
	ON z.staff_id = b.staff_id AND 1=1
	LEFT JOIN
	(SELECT staff_id,
			20 AS target
	FROM account_officers
	WHERE structure_date = @date AND (staff_type = 'RMO' OR staff_grade = 'MA' OR staff_grade = 'DA') ) d		/** Targets **/
	ON z.staff_id = d.staff_id AND 1=1
	LEFT JOIN
	(SELECT b.staff_id,
			a.acct_reactv AS weight
	FROM monthly_score_cards_weight_account_officers a
	JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
	ON z.staff_id = e.staff_id	AND 1=1	
GROUP BY z.staff_id, a.eod_date, e.weight, d.target			)




/** ACCOUNT OPEN AND FUNDED**/

UNION
(SELECT '03' AS perf_measure_code,
		'Account Open and Funded' as performance_measure,
		'Account Open and Funded' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,
		a.eod_date
	
	FROM
	(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
	LEFT JOIN
	(SELECT a.acct_mgr_user_id AS staff_id, 
		COUNT (DISTINCT a.foracid) AS actual, 
		a.eod_date
	FROM (SELECT foracid, ACCT_MGR_USER_ID, eod_date 
			FROM accounts_open_monthly_base WHERE EOD_DATE = @date) a
	LEFT JOIN
	(SELECT foracid, acct_mgr_user_id, average_deposit, eod_date 
				FROM deposits_base WHERE eod_date = @date) b
	ON a.ACCT_MGR_USER_ID = b.acct_mgr_user_id
	JOIN	account_officers c	
	ON b.acct_mgr_user_id = c.staff_id
	WHERE b.average_deposit > 10000 
	GROUP BY a.eod_date, a.acct_mgr_user_id ) a			/** actual **/	
	ON z.staff_id = a.staff_id AND 1=1
	
	LEFT JOIN
	(SELECT a.acct_mgr_user_id AS staff_id, 
		COUNT (DISTINCT a.foracid) AS previous_actual, 
		a.eod_date
	FROM (SELECT foracid, ACCT_MGR_USER_ID, eod_date 
			FROM accounts_open_monthly_base WHERE EOD_DATE = @previous_month) a
	LEFT JOIN
	(SELECT foracid, acct_mgr_user_id, average_deposit, eod_date 
				FROM deposits_base WHERE eod_date = @previous_month) b
	ON a.ACCT_MGR_USER_ID = b.acct_mgr_user_id
	JOIN	account_officers c	
	ON b.acct_mgr_user_id = c.staff_id
	WHERE b.average_deposit > 10000 
	GROUP BY a.eod_date, a.acct_mgr_user_id  ) b			/** Previous Balnace **/
	on z.staff_id = b.staff_id AND 1=1
	

	LEFT JOIN
	(SELECT b.staff_id,
			a.acct_open_funded AS weight
	FROM monthly_score_cards_weight_account_officers a
	JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
	ON z.staff_id = e.staff_id	AND 1=1	
GROUP BY z.staff_id, a.eod_date, e.weight			)



/** DIGITAL TO TOTAL ACQUSITION **/

UNION
(SELECT '04' AS perf_measure_code,
		'Digital to Total Acquisition' as performance_measure,
		'Digital to Total Acquisition' AS performance_description,
		a.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,
		a.eod_date
	FROM
	(SELECT a.staff_id,
		SUM(a.total_open / NULLIF(b.total_open, 0)) AS actual,
		a.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.staff_id = b.staff_id AND a.eod_date = b.eod_date
	WHERE a.eod_date = @date
	GROUP BY a.eod_date, a.staff_id ) a			/** Actual **/
	LEFT JOIN
	(SELECT a.staff_id,
		SUM(a.total_open /  NULLIF(b.total_open, 0)) AS previous_actual,
		a.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.staff_id = b.staff_id AND a.eod_date = b.eod_date
	WHERE a.eod_date = @previous_month
	GROUP BY a.eod_date, a.staff_id ) b			/** Previous Actual **/
	ON a.staff_id = b.staff_id

	LEFT JOIN
	(SELECT b.staff_id,
			a.dig_tot_acq AS weight
	FROM monthly_score_cards_weight_account_officers a
	JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
	ON a.staff_id = e.staff_id		
GROUP BY a.staff_id, a.eod_date, e.weight			)


	

/** TRADITIONAL TO TOTAL ACQUISITION **/

UNION

( SELECT '05' AS perf_measure_code, 
		'Traditional to Total Acquisition' as performance_measure,
		'Traditional to Total Acquisition' AS performance_description,
		a.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,
		a.eod_date
	FROM
	(SELECT b.staff_id,
		((SUM(b.total_open) - SUM(a.total_open)) / SUM(NULLIF(b.total_open, 0))) AS actual,
		b.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.staff_id = b.staff_id AND a.eod_date = b.eod_date
	WHERE a.eod_date = @date
	GROUP BY b.eod_date, b.staff_id ) a			/** Actual **/ 
	LEFT JOIN
	(SELECT b.staff_id,
		((SUM(b.total_open) - SUM(a.total_open)) / SUM(NULLIF(b.total_open, 0))) AS previous_actual,
		b.eod_date
	FROM account_status_aggregation_digital_total a
	JOIN account_status_aggregation b
	ON a.staff_id = b.staff_id AND a.eod_date = b.eod_date
	WHERE a.eod_date = @previous_month
	GROUP BY b.eod_date, b.staff_id ) b			/** Previous Actual **/
	ON a.staff_id = b.staff_id
	
	LEFT JOIN
	(SELECT b.staff_id,
			a.trad_tot_acq AS weight
	FROM monthly_score_cards_weight_account_officers a
	JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
	ON a.staff_id = e.staff_id		
GROUP BY a.staff_id, a.eod_date, e.weight			)





/** INCREMENTAL CASA VOLUME **/

UNION

( SELECT '06' AS perf_measure_code, 
		'Incremental CASA Volume' as performance_measure,
		'Incremental CASA Volume (N''000)' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		SUM(ISNULL(b.casa_avg, 0.00) - ISNULL(c.casa_avg, 0.00)) AS previous_actual,
		SUM(ISNULL(a.casa_avg, 0.00) - ISNULL(c.casa_avg, 0.00)) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.casa_avg) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.casa_avg)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,	
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT  a.account_officer AS staff_id,
		SUM(a.avg_vol) As casa_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'CASA' AND eod_date = @date
		GROUP BY a.eod_date, a.account_officer ) a		/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		
		LEFT JOIN
		(SELECT  a.account_officer AS staff_id,
		SUM(a.avg_vol) As casa_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'CASA' AND eod_date = @previous_month
		GROUP BY a.eod_date, a.account_officer ) b		/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1

		LEFT JOIN
		(SELECT  a.account_officer AS staff_id,
		SUM(a.avg_vol) As casa_avg,
		a.eod_date
		FROM mpr_balance_sheet_aggr a			
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
		WHERE b.score_card_class = 'CASA' AND eod_date = @closing_date
		GROUP BY a.eod_date, a.account_officer ) c		/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1

		LEFT JOIN
		(SELECT staff_id,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM monthly_score_card_targets_account_officers
		WHERE caption IN ('ALAT', 'SAVINGS ACCOUNTS', 'WEMA TARGET SAVINGS ACCOUNT', 'WEMA TREASURE ACCOUNT', 'MYBUSINESS ACCOUNT',
							'COLLECTIONS FLOAT', 'PRESTIGE CURRENT ACCOUNT', 'STD DEMAND DEPOSIT CORP.', 'STD DEMAND DEPOSIT IND.')
		GROUP BY structure_date, staff_id		)d			/** Target **/
		ON z.staff_id = d.staff_id AND 1=1

		LEFT JOIN
		(SELECT b.staff_id,
				a.inc_casa_vol AS weight
		FROM monthly_score_cards_weight_account_officers a
	JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id		AND 1=1
		GROUP BY z.staff_id, a.eod_date, e.weight, d.target			)



/** INCREMENTAL TENURED VOLUME **/
UNION

(SELECT '07' AS perf_measure_code,
		'Incremental Tenured Volume' AS performance_measure,
		'Incremental Tenured Volume (N''000)' AS performance_description,
		z.staff_id,
		0 AS weight,
		SUM(ISNULL(c.tenured_avg, 0.00)) AS closing_balance,
		SUM(ISNULL(b.tenured_avg, 0.00) - ISNULL(c.tenured_avg, 0.00)) AS previous_actual,
		SUM(ISNULL(a.tenured_avg, 0.00) - ISNULL(c.tenured_avg, 0.00)) AS actual,
		ISNULL(d.target, 0) AS target,
		0 AS performance,
		a.eod_date
		FROM

		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT A.account_officer AS staff_id,
		SUM(a.avg_vol) As tenured_avg,
		SUM(a.naira_value) AS tenured_actual, 
		a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'TERM DEPOSIT' AND eod_date = @date
		GROUP BY a.eod_date, a.account_officer ) a			/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		
		LEFT JOIN
		(SELECT A.account_officer AS staff_id,
		SUM(a.avg_vol) As tenured_avg,
		SUM(a.naira_value) AS tenured_actual, 
		a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'TERM DEPOSIT' AND eod_date = @previous_month
		GROUP BY a.eod_date, a.account_officer ) b			/** Previous Balance **/
		ON z.staff_id = b.staff_id AND 1=1

		LEFT JOIN

		(SELECT A.account_officer AS staff_id,
		SUM(a.avg_vol) As tenured_avg,
		SUM(a.naira_value) AS tenured_actual, 
		a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'TERM DEPOSIT' AND eod_date = @closing_date
		GROUP BY a.eod_date, a.account_officer ) c		/** Closing Balance **/
		ON z.staff_id =b.staff_id AND 1=1

		LEFT JOIN
		(SELECT staff_id,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM monthly_score_card_targets_account_officers
		WHERE caption IN ('ALAT GOAL', 'CALL DEPOSITS', 'TIME DEPOSIT')
		GROUP BY structure_date, staff_id		)d			/** Target **/
		ON z.staff_id = d.staff_id AND 1=1
		
		GROUP BY z.staff_id, a.eod_date, d.target		)


	
/** TOTAL CUMMULATIVE DEPOSIT **/

UNION

(SELECT '08' AS perf_measure_code,
		'Total Cummulative Deposit' as performance_measure,
		'Total Cummulative Deposit (N''000)' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		ISNULL(SUM(c.closing_balance), 0) AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,		
		a.eod_date
		
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN		
		(SELECT  staff_id,
		SUM(average_balance) As actual,
		eod_date
		FROM deposits_aggr
		WHERE eod_date = @date
		GROUP BY eod_date, staff_id ) a			/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT  staff_id,
		SUM(average_balance) As previous_actual,
		eod_date
		FROM deposits_aggr
		WHERE eod_date = @previous_month
		GROUP BY eod_date, staff_id ) b			/** Previous Balance **/
		ON z.staff_id = b.staff_id AND 1=1
		LEFT JOIN
		(SELECT  staff_id,
		SUM(average_balance) As closing_balance,
		eod_date
		FROM deposits_aggr
		WHERE eod_date = @closing_date
		GROUP BY eod_date, staff_id ) c			/** Closing Balance **/
		ON z.staff_id = c.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id,
		deposit_target AS target,
		structure_date
		FROM account_officer_targets
		WHERE structure_date = @date)d			/** Target **/
		ON z.staff_id = d.staff_id	AND 1=1		
		LEFT JOIN
		(SELECT b.staff_id,
				a.tot_cum_dep AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
	ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)



/** DOMICILIARY VOLUME **/

UNION

(SELECT '09' AS perf_measure_code,
		'Domiciliary Volume' as performance_measure,
		'Domiciliary Volume (N''000)' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		ISNULL(SUM(c.closing_balance), 0) AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,			
		a.eod_date
		FROM
			(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
			LEFT JOIN
			(SELECT A.account_officer AS staff_id,
			SUM(a.avg_vol) As actual,
			a.eod_date
			FROM mpr_balance_sheet_aggr a
			JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
			WHERE b.score_card_class IN ('DOMICILIARY BALANCE') AND eod_date = @date
			GROUP BY a.eod_date, a.account_officer ) a		/** Actual **/
			ON z.staff_id = a.staff_id AND 1=1
			LEFT JOIN
			(SELECT A.account_officer AS staff_id,
			SUM(a.avg_vol) As previous_actual,
			a.eod_date
			FROM mpr_balance_sheet_aggr a
			JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
			WHERE b.score_card_class IN ('DOMICILIARY BALANCE') AND eod_date = @previous_month
			GROUP BY a.eod_date, a.account_officer ) b		/** Previous Actual **/
			ON z.staff_id = b.staff_id AND 1=1
			LEFT JOIN
			(SELECT A.account_officer AS staff_id,
			SUM(a.avg_vol) As closing_balance,
			a.eod_date
			FROM mpr_balance_sheet_aggr a
			JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
			ON a.position = b.position
			WHERE b.score_card_class IN ('DOMICILIARY BALANCE') AND eod_date = '20211030'
			GROUP BY a.eod_date, a.account_officer ) c		/** Closing Balance **/
			ON z.staff_id = c.staff_id	AND 1=1
			LEFT JOIN
			(SELECT staff_id,
					SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
					WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
					WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
					WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
			FROM monthly_score_card_targets_account_officers
			WHERE caption IN ('DOMICILLIARY ACCOUNTS') AND Year = YEAR(@date)
			GROUP BY structure_date, staff_id		)d			/** Target **/
			ON z.staff_id = d.staff_id AND 1=1
			LEFT JOIN
			(SELECT b.staff_id,
					a.inc_dom_vol AS weight
			FROM monthly_score_cards_weight_account_officers a
			JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
			ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
			ON z.staff_id = e.staff_id	AND 1=1	
			GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)




/** COST OF FUNDS **/

UNION

(SELECT '10' AS perf_measure_code,
		'Cost of Funds' as performance_measure,
		'Cost of Funds (%)' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		5 AS target,
		CASE WHEN SUM(a.actual) <= 5 THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ 5) * e.weight), 2)) END AS performance,	
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT a.account_officer AS staff_id,
		SUM(((Total_Interest - Other_liabilities) / deposit) * @annualise) AS actual,
		a.eod_date
		FROM
		(SELECT account_officer, 
		ISNULL(SUM(interest_inc_exp), 0.00) AS Total_Interest,
		ISNULL(SUM(CASE WHEN name = 'OTHER LIABILITIES' THEN interest_inc_exp END), 0.00) AS Other_liabilities,
		eod_date
		FROM mpr_balance_sheet_aggr 
		WHERE eod_date = @date
		GROUP BY eod_date, account_officer )a
		LEFT JOIN
		(SELECT staff_id,
		SUM(NULLIF(average_balance, 0)) AS deposit,
		eod_date
		FROM deposits_aggr	 /** Getting Total Deposit **/
		WHERE eod_date = @date
		GROUP BY eod_date, staff_id)  b
		ON a.account_officer = b.staff_id
		GROUP BY a.eod_date, a.account_officer	) a				/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1

		LEFT JOIN

		(SELECT a.account_officer AS staff_id,
		SUM(((Total_Interest - Other_liabilities) / deposit) * 30/365) AS previous_actual,
		a.eod_date
		FROM
		(SELECT account_officer, 
		ISNULL(SUM(interest_inc_exp), 0.00) AS Total_Interest,
		ISNULL(SUM(CASE WHEN name = 'OTHER LIABILITIES' THEN interest_inc_exp END), 0.00) AS Other_liabilities,
		eod_date
		FROM mpr_balance_sheet_aggr 
		WHERE eod_date = @previous_month
		GROUP BY eod_date, account_officer )a
		JOIN
		(SELECT staff_id,
		SUM(NULLIF(average_balance, 0)) AS deposit,
		eod_date
		FROM deposits_aggr	 /** Getting Total Deposit **/
		WHERE eod_date = @previous_month
		GROUP BY eod_date, staff_id)  b
		ON a.account_officer = b.staff_id
		GROUP BY a.eod_date, a.account_officer	) b			/** Previous Actual **/

		ON z.staff_id = b.staff_id AND 1=1

		--LEFT JOIN

		--(SELECT a.account_officer AS staff_id,
		--SUM(((Total_Interest - Other_liabilities) / deposit) * @annualise) AS closing_balance,
		--a.eod_date
		--FROM
		--(SELECT account_officer, 
		--ISNULL(SUM(interest_inc_exp), 0.00) AS Total_Interest,
		--ISNULL(SUM(CASE WHEN name = 'OTHER LIABILITIES' THEN interest_inc_exp END), 0.00) AS Other_liabilities,
		--eod_date
		--FROM mpr_balance_sheet_aggr 
		--WHERE eod_date = @closing_date
		--GROUP BY eod_date, account_officer )a
		--JOIN
		--(SELECT staff_id,
		--SUM(NULLIF(average_balance, 0)) AS deposit,
		--eod_date
		--FROM deposits_aggr	 /** Getting Total Deposit **/
		--WHERE eod_date = @closing_date
		--GROUP BY eod_date, staff_id)  b
		--ON a.account_officer = b.staff_id
		--GROUP BY a.eod_date, a.account_officer	) c					/** Closing Balance **/
		--ON z.staff_id = c.staff_id	AND 1=1

		LEFT JOIN
		(SELECT b.staff_id,
				a.cost_funds AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1	
		
		GROUP BY a.eod_date, z.staff_id, e.weight		)



/** FEE INCOME **/

UNION

(SELECT '11' AS perf_measure_code,
		'Fee Income' as performance_measure,
		'Fee Income N''000' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,	
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT staff_id,
		SUM(total_income) AS actual,
		eod_date
		FROM comm_fees_aggr
		WHERE eod_date = @date
		GROUP BY eod_date, staff_id ) a			/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id,
		SUM(total_income) AS previous_actual,
		eod_date
		FROM comm_fees_aggr
		WHERE eod_date = @previous_month
		GROUP BY eod_date, staff_id ) b			/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT staff_id,
		--SUM(total_income) AS closing_balance,
		--eod_date
		--FROM comm_fees_aggr
		--WHERE eod_date = @closing_date
		--GROUP BY eod_date, staff_id ) c			/** Closing Balance **/
		--ON z.staff_id = c.staff_id	AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN Feb WHEN MONTH(@date) = 3 THEN Mar
				WHEN MONTH(@date) = 4 THEN Apr WHEN MONTH(@date) = 5 THEN May WHEN MONTH(@date) = 6 THEN June
				WHEN MONTH(@date) = 7 THEN July WHEN MONTH(@date) = 8 THEN Aug WHEN MONTH(@date) = 9 THEN Sep
				WHEN MONTH(@date) = 10 THEN Oct WHEN MONTH(@date) = 11 THEN Nov WHEN MONTH(@date) = 12 THEN Dec END) AS target
		FROM monthly_score_card_targets_account_officers
		WHERE caption IN ('COMMISSION AND FEE') AND Year = YEAR(@date)
		GROUP BY structure_date, staff_id		)d			/** Target **/
		ON z.staff_id = d.staff_id AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.fee_inc AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)


/** PBT **/
UNION

(SELECT '12' AS perf_measure_code,
		'PBT' as performance_measure,
		'PBT (N''000)' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN	
		(SELECT a.account_officer AS staff_id,
		SUM(a.int_inc_expense) AS actual,
		a.eod_date
		FROM mpr_inc_stmt_aggr a
		RIGHT JOIN account_officers b
		ON a.account_officer =	b.staff_id
		WHERE name = 'PROFIT BEFORE TAX' AND eod_date = @date AND b.staff_type = 'RMO'
		GROUP BY eod_date, account_officer ) a			/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT account_officer AS staff_id,
		SUM(int_inc_expense) AS previous_actual,
		eod_date
		FROM mpr_inc_stmt_aggr 
		WHERE name = 'PROFIT BEFORE TAX' AND eod_date = @previous_month
		GROUP BY eod_date, account_officer ) b			/** Previous Actual**/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT account_officer AS staff_id,
		--SUM(int_inc_expense) AS closing_balance,
		--eod_date
		--FROM mpr_inc_stmt_aggr 
		--WHERE name = 'PROFIT BEFORE TAX' AND eod_date = @closing_date
		--GROUP BY eod_date, account_officer ) c			/** Closing Balance **/
		--ON z.staff_id = c.staff_id	AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.pbt AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight		)



/** PBT YTD **/

UNION

(SELECT '13' AS perf_measure_code,
		'PBT YTD' as performance_measure,
		'PBT YTD BRANCH (N''000)' AS performance_description,
		z.staff_id,
		5 AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN 5
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * 5), 2)) END AS performance,
		a.eod_date
		FROM
		
		(SELECT staff_id,
				branch_code,
				structure_date
		FROM account_officers
		WHERE structure_date = EOMONTH(@date)) z
		LEFT JOIN
		(SELECT a.branch_code,
				SUM(CASE WHEN b.int_inc_expense < 0 THEN 0.00 ELSE b.int_inc_expense END) AS actual, 
				a.eod_date 
		FROM mpr_inc_stmt_aggr a
		LEFT JOIN mpr_inc_stmt_aggr B
		ON a.branch_code = b.branch_code
		AND datediff(year, b.eod_date, a.eod_date) = 0 
        AND b.eod_date <= a.eod_date
		WHERE a.name = 'PROFIT BEFORE TAX' AND b.name = 'PROFIT BEFORE TAX' AND a.eod_date = @date
		GROUP BY a.eod_date, a.branch_code) a				/** Actual **/
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
		ON z.branch_code = b.branch_code AND 1=1

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
		--ON z.branch_code = c.branch_code AND 1=1

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
		ON z.branch_code = d.branch_code AND 1=1

		LEFT JOIN
		(SELECT b.staff_id,
				a.pbt_ytd AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id			

	GROUP BY a.eod_date, z.staff_id, d.target	)



/** TOTAL CONTRIBUTIONS YTD**/

UNION

(SELECT '14' AS perf_measure_code,
		'Total Contribution' as performance_measure,
		'Total Contribution N''000' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN		
		(SELECT a.account_officer AS staff_id,
		SUM(b.int_inc_expense) AS actual,
		a.eod_date
		FROM mpr_inc_stmt_aggr a
		LEFT JOIN mpr_inc_stmt_aggr b
		ON a.account_officer = b.account_officer
		and datediff(year, b.eod_date, a.eod_date) = 0 
        and b.eod_date <= a.eod_date
		WHERE a.name = 'CONTRIBUTION' AND b.name = 'CONTRIBUTION' AND a.eod_date = @date
		GROUP BY a.eod_date, a.account_officer) a				/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT a.account_officer,
		SUM(b.int_inc_expense) AS previous_actual,
		a.eod_date
		FROM mpr_inc_stmt_aggr a
		LEFT JOIN mpr_inc_stmt_aggr b
		ON a.account_officer = b.account_officer
		and datediff(year, b.eod_date, a.eod_date) = 0 
        and b.eod_date <= a.eod_date
		WHERE a.name = 'CONTRIBUTION' AND b.name = 'CONTRIBUTION' AND a.eod_date = @previous_month
		GROUP BY a.eod_date, a.account_officer) b				/** Previous Actual **/
		ON z.staff_id = b.account_officer AND 1=1
		--LEFT JOIN
		--(SELECT a.account_officer,
		--SUM(b.int_inc_expense) AS closing_balance,
		--a.eod_date
		--FROM mpr_inc_stmt_aggr a
		--LEFT JOIN mpr_inc_stmt_aggr b
		--ON a.account_officer = b.account_officer
		--and datediff(year, b.eod_date, a.eod_date) = 0 
  --      and b.eod_date <= a.eod_date
		--WHERE a.name = 'CONTRIBUTION' AND b.name = 'CONTRIBUTION' AND a.eod_date = @closing_date
		--GROUP BY a.eod_date, a.account_officer) c			/** Closing Balance **/
		--ON z.staff_id = c.account_officer	AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				SUM(CASE WHEN MONTH(@date) = 1 THEN Jan WHEN MONTH(@date) = 2 THEN (Jan + Feb) WHEN MONTH(@date) = 3 THEN (Jan + Feb + Mar)
				WHEN MONTH(@date) = 4 THEN (Jan + Feb + Mar + Apr) WHEN MONTH(@date) = 5 THEN (Jan + Feb + Mar + Apr + May) 
				WHEN MONTH(@date) = 6 THEN (Jan + Feb + Mar + Apr + May + June) WHEN MONTH(@date) = 7 THEN (Jan + Feb + Mar + Apr + May + June + July) 
				WHEN MONTH(@date) = 8 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug) 
				WHEN MONTH(@date) = 9 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep)
				WHEN MONTH(@date) = 10 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct) 
				WHEN MONTH(@date) = 11 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct + Nov) 
				WHEN MONTH(@date) = 12 THEN (Jan + Feb + Mar + Apr + May + June + July + Aug + Sep + Oct + Nov + Dec) END) AS target
		FROM monthly_score_card_targets_account_officers
		WHERE caption IN ('CONTRIBUTION')
		GROUP BY structure_date, staff_id		)d			/** Target **/
		ON z.staff_id = d.staff_id AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.tot_cont AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)




/** GROSS LOANS **/

UNION

(SELECT '15' AS perf_measure_code,
		'Gross Loans' as performance_measure,
		'Gross Loans N''000' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,		
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN		
		(SELECT  a.account_officer AS staff_id,
		SUM(a.avg_vol * -1) AS actual,
		a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS' AND eod_date = @date
		GROUP BY a.eod_date, account_officer) a				/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT  a.account_officer,
		SUM(a.avg_vol * -1) AS previous_actual,
		a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE score_card_class = 'LOANS' AND eod_date = @previous_month
		GROUP BY a.eod_date, account_officer) b				/** Previous Actual **/
		ON z.staff_id = b.account_officer AND 1=1
		--LEFT JOIN
		--(SELECT  a.account_officer,
		--SUM(a.avg_vol * -1) AS closing_balance,
		--a.eod_date
		--FROM mpr_balance_sheet_aggr a
		--JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		--ON a.position = b.position
		--WHERE b.score_card_class = 'LOANS' AND eod_date = @closing_date
		--GROUP BY a.eod_date, account_officer) c				/** Closing Balance **/
		--ON z.staff_id = c.account_officer	AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				NULLIF(loan_target, 0) AS target,
				structure_date
				FROM account_officer_targets
				WHERE structure_date = @date)d			/** Target **/
		ON z.staff_id = d.staff_id	AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.gross_loan  AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)
		
		
/** NON-PERFORMING LOANS **/

UNION

(SELECT '16' AS perf_measure_code,
		'Non-Performing Loans' as performance_measure,
		'Non-Performing Loans (%)' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL((SUM(b.previous_actual)/NULLIF(SUM(d.prev_month_target), 0)) * 100, 0) AS previous_actual,
		ISNULL((SUM(a.actual)/NULLIF(SUM(d.month_target), 0)) * 100, 0) AS actual,
		5 AS target,
		CASE WHEN SUM(a.actual) <= (SUM(d.month_target)*0.05) THEN e.weight
					ELSE 0 END AS performance,		
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT staff_id,
				actual,
				eod_date
		FROM npl_account_officer_base
		WHERE eod_date = @date) a					/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				actual AS previous_actual,
				eod_date
		FROM npl_account_officer_base
		WHERE eod_date = @previous_month) b			/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT staff_id,
		--		actual AS closing_balance,
		--		eod_date
		--FROM npl_account_officer_base
		--WHERE eod_date = @closing_date) c			/** Closing Balance **/	
		--ON z.staff_id = c.staff_id AND 1=1
		LEFT JOIN
		(SELECT  a.account_officer,
				CASE WHEN eod_date = @date THEN SUM(a.naira_value * -1) * 0.05 END AS month_target,
				CASE WHEN eod_date = @previous_month THEN SUM(a.naira_value * -1) * 0.05 END AS prev_month_target,
				CASE WHEN eod_date = @closing_date THEN SUM(a.naira_value * -1) * 0.05 END AS closing_target,
		a.eod_date
		FROM mpr_balance_sheet_aggr a
		JOIN (SELECT DISTINCT name, position, score_card_class from mpr_map) b
		ON a.position = b.position
		WHERE b.score_card_class = 'LOANS'
		GROUP BY a.eod_date, account_officer)		d				/** Target **/	
		ON z.staff_id = d.account_officer AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.npl  AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight	)


/** CARDS ACTIVATION **/

UNION

(SELECT '17' AS perf_measure_code,
		'Cards Activation' as performance_measure,
		'Cards Activation' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0 ) AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,	
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN	
		(SELECT acct_mgr_user_id AS staff_id,
				COUNT(DISTINCT foracid) AS actual,
				EOMONTH(activated_date) AS eod_date
		FROM cards_base
		WHERE EOMONTH(activated_date) = @date
		GROUP BY EOMONTH(activated_date), acct_mgr_user_id  ) a			/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT acct_mgr_user_id AS staff_id,
				COUNT(DISTINCT foracid) AS previous_actual,
				EOMONTH(activated_date) AS eod_date
		FROM cards_base
		WHERE EOMONTH(activated_date) = @previous_month
		GROUP BY EOMONTH(activated_date), acct_mgr_user_id  ) b			/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT acct_mgr_user_id AS staff_id,
		--		COUNT(DISTINCT foracid) AS closing_balance,
		--		EOMONTH(activated_date) AS eod_date
		--FROM cards_base
		--WHERE EOMONTH(activated_date) = @closing_date
		--GROUP BY EOMONTH(activated_date), acct_mgr_user_id  ) c			/** Closing Balance **/
		--ON z.staff_id = c.staff_id	 AND 1=1
		LEFT JOIN
		(SELECT staff_id,
			CASE WHEN staff_type = 'RMO' THEN 40
					WHEN staff_grade IN ('MA', 'DA') THEN 50 END AS target
		FROM account_officers
		WHERE structure_date = @date	 ) d							/** Targets **/
		ON z.staff_id = d.staff_id AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.cards_actv AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)
		




/** CREDIT CARD ISSUANCE**/

UNION

(SELECT '18' AS perf_measure_code,
		'Credit Card Issuance' as performance_measure,
		'Credit Card Issuance' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		0 AS target,
		0 AS performance,
		a.eod_date
		FROM
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT acct_mgr_user_id AS staff_id,
				COUNT(DISTINCT foracid) AS actual,
				EOMONTH(issue_date) AS eod_date
		FROM cards_base
		WHERE card_type = 'CREDIT' AND EOMONTH(issue_date) = @date
		GROUP BY EOMONTH(issue_date), acct_mgr_user_id ) a		/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT acct_mgr_user_id AS staff_id,
				COUNT(DISTINCT foracid) AS previous_actual,
				EOMONTH(issue_date) AS eod_date
		FROM cards_base
		WHERE card_type = 'CREDIT' AND EOMONTH(issue_date) = @previous_month
		GROUP BY EOMONTH(issue_date), acct_mgr_user_id ) b		/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT acct_mgr_user_id AS staff_id,
		--		COUNT(DISTINCT foracid) AS closing_balance,
		--		EOMONTH(issue_date) AS eod_date
		--FROM cards_base
		--WHERE card_type = 'CREDIT' AND EOMONTH(issue_date) = @closing_date
		--GROUP BY EOMONTH(issue_date), acct_mgr_user_id ) c		/** Closing Balance **/
		--ON z.staff_id = c.staff_id	AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.credit_card AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight		)
		

	


/** DATA QUALITY INDEX **/


UNION

(SELECT '19' AS perf_measure_code,
		'Data Quality Index' as performance_measure,
		'Data Quality Index' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0)  AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,		
		a.eod_date
		FROM	
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN	
		(SELECT a.staff_id,
				a.branch_code,
				CASE WHEN a.sbu_id = 'S001' THEN b.ind_dqi
					WHEN a.sbu_id = 'S002' THEN b.corp_dqi
					ELSE b.avg_dqi END AS actual,
				eod_date
		FROM account_officers a
		JOIN dqi_base b
		ON a.branch_code = b.branch_code AND a.structure_date = b.eod_date
		WHERE eod_date = @date
		GROUP BY b.eod_date, a.staff_id, a.sbu_id, b.ind_dqi, b.corp_dqi,a.branch_code, b.avg_dqi ) a			/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		
		LEFT JOIN
		(SELECT a.staff_id,
				a.branch_code,
				CASE WHEN a.sbu_id = 'S001' THEN b.ind_dqi
					WHEN a.sbu_id = 'S002' THEN b.corp_dqi
					ELSE b.avg_dqi END AS previous_actual,
				eod_date
		FROM account_officers a
		JOIN dqi_base b
		ON a.branch_code = b.branch_code AND a.structure_date = b.eod_date
		WHERE eod_date = @previous_month
		GROUP BY b.eod_date, a.staff_id, a.sbu_id, b.ind_dqi, b.corp_dqi,a.branch_code, b.avg_dqi) b			/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1
		
		--LEFT JOIN
		--(SELECT a.staff_id,
		--		a.branch_code,
		--		CASE WHEN a.sbu_id = 'S001' THEN b.ind_dqi
		--			WHEN a.sbu_id = 'S002' THEN b.corp_dqi
		--			ELSE b.avg_dqi END AS closing_balance,
		--		eod_date
		--FROM account_officers a
		--JOIN dqi_base b
		--ON a.branch_code = b.branch_code AND a.structure_date = b.eod_date
		--WHERE eod_date = @closing_date
		--GROUP BY b.eod_date, a.staff_id, a.sbu_id, b.ind_dqi, b.corp_dqi,a.branch_code, b.avg_dqi) c			/** Closing Balance **/
		--ON z.staff_id = c.staff_id AND 1=1
		
		LEFT JOIN
		(SELECT a.staff_id,
				a.branch_code,
				CASE WHEN a.sbu_id = 'S001' THEN b.ind_dqi_target
					WHEN a.sbu_id = 'S002' THEN b.corp_dqi_target
					ELSE b.avg_dqi_target END AS target,
				eod_date
		FROM account_officers a
		JOIN dqi_base b
		ON a.branch_code = b.branch_code AND a.structure_date = b.eod_date
		WHERE eod_date = @date
		GROUP BY b.eod_date, a.staff_id, a.sbu_id, b.ind_dqi_target, b.corp_dqi_target,a.branch_code, b.avg_dqi_target) d			/** Target **/
		ON z.staff_id = d.staff_id AND 1=1
		
		LEFT JOIN
		(SELECT b.staff_id,
				a.dqi AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)



	
		
/** DIGITAL PENETRATION **/


UNION

(SELECT '20' AS perf_measure_code,
		'Digital Penetration' as performance_measure,
		'Digital Penetration' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0)  AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,		
		a.eod_date
		FROM	
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT staff_id, 
				actual,
				eod_date
		FROM digital_penetration_account_officers_base
		WHERE eod_date = @date	) a				/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id, 
				actual AS previous_actual,
				eod_date
		FROM digital_penetration_account_officers_base
		WHERE eod_date = @previous_month	) b				/** Previous Actual **/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT staff_id, 
		--		actual AS closing_balance,
		--		eod_date
		--FROM digital_penetration_account_officers_base
		--WHERE eod_date = @closing_date	) c			/** Closing Balance **/
		--ON z.staff_id = c.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				budget AS target,
				eod_date
		FROM digital_penetration_account_officers_base
		WHERE eod_date = @date		) d		/** Target **/
		ON z.staff_id = d.staff_id AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.dig_pen AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)


/** NO OF AGENTS **/



/** POS DEPLOYED **/


UNION

(SELECT '22' AS perf_measure_code,
		'POS Deployed / Volume / MCASH / AGENT' as performance_measure,
		'NO OF POS/MCASH  Deployed' AS performance_description,
		z.staff_id,
		ISNULL(e.weight, 0) AS weight,
		0 AS closing_balance,
		ISNULL(SUM(b.previous_actual), 0) AS previous_actual,
		ISNULL(SUM(a.actual), 0) AS actual,
		ISNULL(d.target, 0)  AS target,
		CASE WHEN SUM(a.actual) >= d.target THEN e.weight
					ELSE (ROUND(((SUM(a.actual)/ NULLIF(d.target, 0)) * e.weight), 2)) END AS performance,		
		a.eod_date
		FROM	
		(SELECT  DISTINCT staff_id from account_officers WHERE structure_date = @date AND sbu_id IN ('S001', 'S002')) z
		LEFT JOIN
		(SELECT staff_id,
				actual,
				eod_date
		FROM pos_deployed_account_officer_base	
		WHERE eod_date = @date) a				/** Actual **/
		ON z.staff_id = a.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				actual AS previous_actual,
				eod_date
		FROM pos_deployed_account_officer_base	
		WHERE eod_date = @previous_month) b				/** Previous Month **/
		ON z.staff_id = b.staff_id AND 1=1
		--LEFT JOIN
		--(SELECT staff_id,
		--		actual AS closing_balance,
		--		eod_date
		--FROM pos_deployed_account_officer_base	
		--WHERE eod_date = @closing_date	) c				/** Closing Balance **/
		--ON z.staff_id = c.staff_id AND 1=1
		LEFT JOIN
		(SELECT staff_id,
				target,
				eod_date
		FROM pos_deployed_account_officer_base	
		WHERE eod_date = @date) d						/** Target **/
		ON z.staff_id = d.staff_id AND 1=1
		LEFT JOIN
		(SELECT b.staff_id,
				a.pos_dep AS weight
		FROM monthly_score_cards_weight_account_officers a
		JOIN (SELECT staff_id, sbu_id, staff_grade, staff_type FROM account_officers WHERE structure_date = @date) b
		ON a.sbu_id = b.sbu_id AND a.staff_type = b.staff_type ) e 			/** Weight **/
		ON z.staff_id = e.staff_id	AND 1=1
		
		GROUP BY a.eod_date, z.staff_id, e.weight, d.target		)



/** CHANNELS TRANSACTION **/




		)B

ON  A.staff_id = B.staff_id	--AND A.structure_date = EOMONTH(B.eod_date)

ORDER BY perf_measure_code asc;



