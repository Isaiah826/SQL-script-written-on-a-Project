USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_monthly_score_card_trend]    Script Date: 2/28/2023 8:58:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER     procedure [dbo].[sp_monthly_score_card_trend]
	@pZoneCode NVARCHAR(50),
    @pBranchCode NVARCHAR(50),
	@pAccountOfficer NVARCHAR(50),
    @pMonth NVARCHAR(50),
    @pYear NVARCHAR(50)


AS 

DECLARE @sql NVARCHAR(MAX),
		@sql1 NVARCHAR(MAX),
		@date VARCHAR(8)


IF @pZoneCode IS NOT NULL

BEGIN
			SET @sql = '
			SELECT 1 AS id, ''JAN'' AS month, SUM(performance) AS performance, 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END AS score
				FROM monthly_score_card_zone
				WHERE month = 1 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24

			UNION

			SELECT 2, ''FEB'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 2 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 3, ''MAR'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 3 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 4, ''APR'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 4 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 5, ''MAY'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 5 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 6, ''JUN'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 6 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 7, ''JUL'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 7 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 '

			SET @sql1 = '

			UNION

			SELECT 8, ''AUG'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 8 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 9, ''SEP'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 9 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 10, ''OCT'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 10 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24

			UNION

			SELECT 11, ''NOV'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 11 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 12, ''DEC'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = 12 AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24
					
			UNION
			
			SELECT 13, ''AVG'', ROUND((SUM(performance)/12), 2), CASE WHEN (SUM(performance)/12) BETWEEN 00 AND 54 THEN ''F''
								WHEN AVG(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN AVG(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN AVG(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN AVG(performance) BETWEEN 96 AND 100 THEN ''A+''
								END					
				FROM monthly_score_card_zone
				WHERE month IN (1,2,3,4,5,6,7,8,9,10,11,12) AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24	' 
			
			END

ELSE IF @pBranchCode IS NOT NULL

		BEGIN
			SET @sql = '
			SELECT 1 AS id, ''JAN'' AS month, SUM(performance) AS performance, 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END AS score
				FROM monthly_score_card_branch
				WHERE month = 1 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24

			UNION

			SELECT 2, ''FEB'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 2 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 3, ''MAR'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 3 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 4, ''APR'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 4 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 5, ''MAY'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 5 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 6, ''JUN'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 6 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 7, ''JUL'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 7 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 '

			SET @sql1 = '

			UNION

			SELECT 8, ''AUG'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 8 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 9, ''SEP'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 9 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 10, ''OCT'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 10 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24

			UNION

			SELECT 11, ''NOV'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 11 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 12, ''DEC'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = 12 AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24
					
			UNION
			
			SELECT 13, ''AVG'', ROUND((SUM(performance)/12), 2), CASE WHEN (SUM(performance)/12) BETWEEN 00 AND 54 THEN ''F''
								WHEN AVG(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN AVG(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN AVG(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN AVG(performance) BETWEEN 96 AND 100 THEN ''A+''
								END					
				FROM monthly_score_card_branch
				WHERE month IN (1,2,3,4,5,6,7,8,9,10,11,12) AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 1 AND 24	' 
			
			END




ELSE IF @pAccountOfficer IS NOT NULL

		BEGIN
			SET @sql = '
			SELECT 1 AS id, ''JAN'' AS month, SUM(performance) AS performance, 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END AS score
				FROM monthly_score_card_account_officers
				WHERE month = 1 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24

			UNION

			SELECT 2, ''FEB'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 2 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 3, ''MAR'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 3 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 4, ''APR'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 4 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 5, ''MAY'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 5 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 6, ''JUN'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 6 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24


			UNION

			SELECT 7, ''JUL'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 7 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24 '

			SET @sql1 = '

			UNION

			SELECT 8, ''AUG'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 8 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 9, ''SEP'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 9 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 10, ''OCT'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 10 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24

			UNION

			SELECT 11, ''NOV'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 11 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24 

			UNION

			SELECT 12, ''DEC'', SUM(performance), 
					CASE WHEN SUM(performance)BETWEEN 00 AND 54 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = 12 AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24
					
			UNION
			
			SELECT 13, ''AVG'', ROUND((SUM(performance)/12), 2), CASE WHEN (SUM(performance)/12) BETWEEN 00 AND 54 THEN ''F''
								WHEN AVG(performance) BETWEEN 55 AND 64 THEN ''C''
								WHEN AVG(performance) BETWEEN 65 AND 79 THEN ''B''
								WHEN AVG(performance) BETWEEN 80 AND 95 THEN ''A''
								WHEN AVG(performance) BETWEEN 96 AND 100 THEN ''A+''
								END					
				FROM monthly_score_card_account_officers
				WHERE month IN (1,2,3,4,5,6,7,8,9,10,11,12) AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 1 AND 24	' 
			
			END


EXECUTE (@sql + @sql1)

print (@sql+ @sql1)

	
	

