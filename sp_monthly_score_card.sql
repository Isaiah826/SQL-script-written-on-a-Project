USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_monthly_score_card]    Script Date: 2/28/2023 8:57:35 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER   procedure [dbo].[sp_monthly_score_card]
	@pDirectorateCode NVARCHAR(50),
	@pRegionCode NVARCHAR(50),
	@pZoneCode nvarchar(50),
	@pBranchCode nvarchar(50),
	@pAccountOfficer nvarchar(50),
	@pMonth nvarchar(50),
	@pYear nvarchar(50)


AS 

DECLARE @sql NVARCHAR(MAX),
		@sql1 NVARCHAR(MAX),
		@sql2 NVARCHAR(MAX),
		@type NVARCHAR(50),
		@type2 NVARCHAR(50),
		@date VARCHAR(8),
		@performance DECIMAL,
		@score NVARCHAR(10),
		@Branchcode NVARCHAR(50)



		/** Directorate Report **/

IF @pDirectorateCode = 'ALL'
			
	BEGIN

		/** Report script **/
	SET @sql = 'SELECT CASE WHEN perf_measure_code IN (06, 07, 08, 09) THEN ''DEPOSITS''
								WHEN perf_measure_code IN (15, 16) THEN ''LOANS''
								WHEN perf_measure_code IN (10, 11, 12, 13, 14) THEN ''EFFICIENCY''
								WHEN perf_measure_code IN (01,02,03,04, 05) THEN ''ACQUISITION''
								WHEN perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24) THEN ''RETENTION AND ENGAGEMENT''
								END AS ''group'',
						performance_measure,
						performance_description,
						ISNULL(AVG(weight),0) AS weight, 
						CASE WHEN perf_measure_code IN (06, 15) THEN ROUND(ISNULL(SUM(closing_balance)/1000 , 0), 2)
								ELSE 0.00 END AS closing_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(SUM(previous_actual)/1000 , 0), 2)
								ELSE ROUND(ISNULL(SUM(previous_actual), 0), 2) END AS previous_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(SUM(actual)/1000 , 0), 2)
								ELSE ROUND(ISNULL(SUM(actual), 0), 2) END AS actual, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15) THEN ROUND(ISNULL(SUM(target)/1000 , 0), 2)
							 WHEN perf_measure_code IN (10, 16) THEN 5
								ELSE ROUND(ISNULL(SUM(target), 0), 2) END  AS target, 
						CASE WHEN perf_measure_code IN (10, 16) THEN AVG(weight)
								WHEN SUM(actual) > SUM(target) THEN AVG(weight) 
								ELSE (SUM(actual)/SUM(target)) * AVG(weight) END AS performance
				
				FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+'  
					AND perf_measure_code IN (01, 02, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 24 )
				GROUP BY perf_measure_code, performance_measure, performance_description
				ORDER BY perf_measure_code asc'
	
	
	EXECUTE SP_EXECUTESQL @sql
	
	END

ELSE IF @pDirectorateCode IS NOT NULL
			
	BEGIN

		/** Report script **/
	SET @sql = 'SELECT CASE WHEN perf_measure_code IN (06, 07, 08, 09) THEN ''DEPOSITS''
								WHEN perf_measure_code IN (15, 16) THEN ''LOANS''
								WHEN perf_measure_code IN (10, 11, 12, 13, 14) THEN ''EFFICIENCY''
								WHEN perf_measure_code IN (01,02,03,04, 05) THEN ''ACQUISITION''
								WHEN perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24) THEN ''RETENTION AND ENGAGEMENT''
								END AS ''group'',
						performance_measure,
						performance_description,
						ISNULL(weight,0) AS weight, 
						CASE WHEN perf_measure_code IN (06, 15) THEN ROUND(ISNULL(closing_balance/1000 , 0), 2)
								ELSE 0.00 END AS closing_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(previous_actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(previous_actual, 0), 2) END AS previous_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(actual, 0), 2) END AS actual, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15) THEN ROUND(ISNULL(target/1000 , 0), 2)
								ELSE ROUND(ISNULL(target, 0), 2) END  AS target, 
						ISNULL(performance, 0) AS performance
				FROM monthly_score_card_directorate
				WHERE directorate_code = '''+@pDirectorateCode+''' AND month = '+@pMonth+' and year = '+@pYear+'  
					AND perf_measure_code IN (01, 02, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 24 )
				ORDER BY perf_measure_code asc'
	
	
	EXECUTE SP_EXECUTESQL @sql
	
	END



/** Region Report **/

IF @pRegionCode IS NOT NULL
			
	BEGIN

		/** Report script **/
		SET @sql = 'SELECT CASE WHEN perf_measure_code IN (06, 07, 08, 09) THEN ''DEPOSITS''
								WHEN perf_measure_code IN (15, 16) THEN ''LOANS''
								WHEN perf_measure_code IN (10, 11, 12, 13, 14) THEN ''EFFICIENCY''
								WHEN perf_measure_code IN (01,02,03,04, 05) THEN ''ACQUISITION''
								WHEN perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24) THEN ''RETENTION AND ENGAGEMENT''
								END AS ''group'',
						performance_measure,
						performance_description,
						ISNULL(weight,0) AS weight, 
						CASE WHEN perf_measure_code IN (06, 15) THEN ROUND(ISNULL(closing_balance/1000 , 0), 2)
								ELSE 0.00 END AS closing_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(previous_actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(previous_actual, 0), 2) END AS previous_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(actual, 0), 2) END AS actual, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15) THEN ROUND(ISNULL(target/1000 , 0), 2)
								ELSE ROUND(ISNULL(target, 0), 2) END  AS target, 
						ISNULL(performance, 0) AS performance
				FROM monthly_score_card_region
				WHERE region_code = '''+@pRegionCode+''' AND month = '+@pMonth+' and year = '+@pYear+'  
					AND perf_measure_code IN (01, 02, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 24 )
				ORDER BY perf_measure_code asc'
	
	
	EXECUTE SP_EXECUTESQL @sql
	
	END





/** Zone Report **/

IF @pZoneCode IS NOT NULL
			
	BEGIN

		/** Report script **/
		SET @sql = 'SELECT CASE WHEN perf_measure_code IN (06, 07, 08, 09) THEN ''DEPOSITS''
								WHEN perf_measure_code IN (15, 16) THEN ''LOANS''
								WHEN perf_measure_code IN (10, 11, 12, 13, 14) THEN ''EFFICIENCY''
								WHEN perf_measure_code IN (01,02,03,04, 05) THEN ''ACQUISITION''
								WHEN perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24) THEN ''RETENTION AND ENGAGEMENT''
								END AS ''group'',
						performance_measure,
						performance_description,
						ISNULL(weight,0) AS weight, 
						CASE WHEN perf_measure_code IN (06, 15) THEN ROUND(ISNULL(closing_balance/1000 , 0), 2)
								ELSE 0.00 END AS closing_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(previous_actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(previous_actual, 0), 2) END AS previous_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(actual, 0), 2) END AS actual, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15) THEN ROUND(ISNULL(target/1000 , 0), 2)
								ELSE ROUND(ISNULL(target, 0), 2) END  AS target, 
						ISNULL(performance, 0) AS performance
				FROM monthly_score_card_zone
				WHERE zone_code = '''+@pZoneCode+''' AND month = '+@pMonth+' and year = '+@pYear+'  
					AND perf_measure_code IN (01, 02, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 24 )
				ORDER BY perf_measure_code asc'
	
	EXECUTE SP_EXECUTESQL @sql
	
	END


	
	/** Branches Report **/

IF @pBranchCode IS NOT NULL
		
	BEGIN
		
		/** Report script **/
		SET @sql = 'SELECT CASE WHEN perf_measure_code IN (06, 07, 08, 09) THEN ''DEPOSITS''
								WHEN perf_measure_code IN (15, 16) THEN ''LOANS''
								WHEN perf_measure_code IN (10, 11, 12, 13, 14) THEN ''EFFICIENCY''
								WHEN perf_measure_code IN (01,02,03,04, 05) THEN ''ACQUISITION''
								WHEN perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24) THEN ''RETENTION AND ENGAGEMENT''
								END AS ''group'',
						performance_measure, 
						performance_description,
						ISNULL(weight,0) AS weight, 
						CASE WHEN perf_measure_code IN (06, 15) THEN ROUND(ISNULL(closing_balance/1000 , 0), 2)
								ELSE 0.00 END AS closing_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(previous_actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(previous_actual,0), 2) END AS previous_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(actual, 0), 2) END AS actual, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15) THEN ROUND(ISNULL(target/1000 , 0), 2)
								ELSE ROUND(ISNULL(target,0), 2) END  AS target,  
						ISNULL(performance, 0) AS performance
				FROM monthly_score_card_branch
				WHERE branch_code = '''+@pBranchCode+''' AND month = '+@pMonth+' AND year = '+@pYear+'  
					AND perf_measure_code IN (01, 02, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 24 )
				ORDER BY perf_measure_code asc'
	
				

	EXECUTE SP_EXECUTESQL @sql

	END



/** Account Officer Reports **/

IF @pAccountOfficer IS NOT NULL
			
		BEGIN
			
				
		/** Checking for Staff Type**/
			SELECT @type = sbu_id from account_officers where staff_id = @pAccountOfficer
				
			

			IF @type IN ('S001', 'S002')

			BEGIN
			/** Report script **/
			SET @sql = 'SELECT CASE WHEN perf_measure_code IN (06, 07, 08, 09) THEN ''DEPOSITS''
								WHEN perf_measure_code IN (15, 16) THEN ''LOANS''
								WHEN perf_measure_code IN (10, 11, 12, 13, 14) THEN ''EFFICIENCY''
								WHEN perf_measure_code IN (01,02,03,04, 05) THEN ''ACQUISITION''
								WHEN perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24) THEN ''RETENTION AND ENGAGEMENT''
								END AS ''group'',
						performance_measure,
						performance_description,
						ISNULL(weight,0) AS weight, 
						CASE WHEN perf_measure_code IN (06, 07, 15) THEN ROUND(ISNULL(closing_balance/1000 , 0), 2)
								ELSE 0.00 END AS closing_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(previous_actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(previous_actual,0), 2) END AS previous_balance, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15, 16) THEN ROUND(ISNULL(actual/1000 , 0), 2)
								ELSE ROUND(ISNULL(actual, 0), 2) END AS actual, 
						CASE WHEN perf_measure_code IN (06, 07, 08, 09, 11, 12, 13, 14, 15) THEN ROUND(ISNULL(target/1000 , 0), 2)
								ELSE ROUND(ISNULL(target,0), 2) END  AS target, 
						ISNULL(performance, 0) AS performance
				FROM monthly_score_card_account_officers
				WHERE staff_id = '''+@pAccountOfficer+''' AND month = '+@pMonth+' AND year = '+@pYear+'
							AND perf_measure_code IN (01, 02, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 24 )
				ORDER BY perf_measure_code asc'

			
			
			END



	EXECUTE SP_EXECUTESQL @sql

	END

	


	

