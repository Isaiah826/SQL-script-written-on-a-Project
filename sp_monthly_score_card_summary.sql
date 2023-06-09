USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_monthly_score_card_summary]    Script Date: 2/28/2023 8:58:00 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER   procedure [dbo].[sp_monthly_score_card_summary]
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
		@type NVARCHAR(50),
		@type2 NVARCHAR(50),
		@date VARCHAR(8),
		@performance DECIMAL(10,2),
		@score NVARCHAR(10),
		@Branchcode NVARCHAR(50)




/** Directorate Report **/

IF @pDirectorateCode = 'ALL'
			
	BEGIN

		/** Report Summary View **/

		
		SET @sql = '
			SELECT A.Measure AS Perspective, zone AS target, B.performance 
			FROM monthly_score_card_performance A
			RIGHT JOIN
			(
			(SELECT ''1'' AS id,  SUM(performance)/3 AS performance FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' AND year = '+@pYear+'
				AND perf_measure_code IN (06, 07, 08, 09))
				UNION					
			(SELECT ''2'', SUM(performance)/3 FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+' 
					AND perf_measure_code IN (15, 16))
				UNION
			(SELECT ''3'', SUM(performance)/3 FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' and year = '+@pYear+' 
					AND perf_measure_code IN (10, 11, 12, 13, 14))
				UNION
			(SELECT ''4'', SUM(performance)/3 FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' and year = '+@pYear+' 
					AND perf_measure_code IN (01,02,03,04, 05))
				UNION
			(SELECT ''5'', SUM(performance)/3 FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' and year = '+@pYear+' 
					AND perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24))
				UNION
			(SELECT ''6'',  SUM(performance)/3 FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+' 
					AND perf_measure_code BETWEEN 01 AND 24)		
					)B
			ON A.id = 	B.id'						
			
		
		
	EXECUTE SP_EXECUTESQL @sql
	

	END	


ELSE IF @pDirectorateCode IS NOT NULL
			
	BEGIN

		/** Report Summary View **/

		
		SET @sql = '
			SELECT A.Measure AS Perspective, zone AS target, B.performance 
			FROM monthly_score_card_performance A
			RIGHT JOIN
			(
			(SELECT ''1'' AS id,  SUM(performance) AS performance FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' AND year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+'''
				AND perf_measure_code IN (06, 07, 08, 09))
				UNION					
			(SELECT ''2'', SUM(performance) FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+'''
					AND perf_measure_code IN (15, 16))
				UNION
			(SELECT ''3'', SUM(performance) FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+'''
					AND perf_measure_code IN (10, 11, 12, 13, 14))
				UNION
			(SELECT ''4'', SUM(performance) FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+'''
					AND perf_measure_code IN (01,02,03,04, 05))
				UNION
			(SELECT ''5'', SUM(performance) FROM monthly_score_card_directorate 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+'''
					AND perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24))
				UNION
			(SELECT ''6'',  SUM(performance) FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24)		
					)B
			ON A.id = 	B.id'						
			
		
		
	EXECUTE SP_EXECUTESQL @sql
	

	END		


/** Region Report **/

IF @pRegionCode IS NOT NULL
			
	BEGIN

		/** Report Summary View **/

		
		SET @sql = '
			SELECT A.Measure AS Perspective, zone AS target, B.performance 
			FROM monthly_score_card_performance A
			RIGHT JOIN
			(
			(SELECT ''1'' AS id,  SUM(performance) AS performance FROM monthly_score_card_region 
				WHERE month = '+@pMonth+' AND year = '+@pYear+' AND region_code = '''+@pRegionCode+'''
				AND perf_measure_code IN (06, 07, 08, 09))
				UNION					
			(SELECT ''2'', SUM(performance) FROM monthly_score_card_region
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND region_code = '''+@pRegionCode+'''
					AND perf_measure_code IN (15, 16))
				UNION
			(SELECT ''3'', SUM(performance) FROM monthly_score_card_region 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND region_code = '''+@pRegionCode+'''
					AND perf_measure_code IN (10, 11, 12, 13, 14))
				UNION
			(SELECT ''4'', SUM(performance) FROM monthly_score_card_region 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND region_code = '''+@pRegionCode+'''
					AND perf_measure_code IN (01,02,03,04, 05))
				UNION
			(SELECT ''5'', SUM(performance) FROM monthly_score_card_region 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND region_code = '''+@pRegionCode+'''
					AND perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24))
				UNION
			(SELECT ''6'',  SUM(performance) FROM monthly_score_card_region
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND region_code = '''+@pRegionCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24)		
					)B
			ON A.id = 	B.id'						
			
		
		
	EXECUTE SP_EXECUTESQL @sql
	

	END		




/** Zone Report **/

IF @pZoneCode IS NOT NULL
			
	BEGIN

		/** Report Summary View **/

		SET @sql = '
			SELECT A.Measure AS Perspective, zone AS target, B.performance 
			FROM monthly_score_card_performance A
			RIGHT JOIN
			(
			(SELECT ''1'' AS id,  SUM(performance) AS performance FROM monthly_score_card_zone 
				WHERE month = '+@pMonth+' AND year = '+@pYear+' AND zone_code = '''+@pZoneCode+'''
				AND perf_measure_code IN (06, 07, 08, 09))
				UNION					
			(SELECT ''2'', SUM(performance) FROM monthly_score_card_zone
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND zone_code = '''+@pZoneCode+'''
					AND perf_measure_code IN (15, 16))
				UNION
			(SELECT ''3'', SUM(performance) FROM monthly_score_card_zone 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND zone_code = '''+@pZoneCode+'''
					AND perf_measure_code IN (10, 11, 12, 13, 14))
				UNION
			(SELECT ''4'', SUM(performance) FROM monthly_score_card_zone 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND zone_code = '''+@pZoneCode+'''
					AND perf_measure_code IN (01,02,03,04, 05))
				UNION
			(SELECT ''5'', SUM(performance) FROM monthly_score_card_zone 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND zone_code = '''+@pZoneCode+'''
					AND perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24))
				UNION
			(SELECT ''6'',  SUM(performance) FROM monthly_score_card_zone
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24)		
					)B
			ON A.id = 	B.id'						
			
		
		
	EXECUTE SP_EXECUTESQL @sql
	

	END		

	


	
	/** Branches Report **/

IF @pBranchCode IS NOT NULL
		
	BEGIN
		
		/** Report Summary View **/

			SET @sql = '
			SELECT A.Measure AS Perspective, branch AS target, B.performance 
			FROM monthly_score_card_performance A
			JOIN
			(
			(SELECT ''1'' AS id,  SUM(performance) AS performance FROM monthly_score_card_branch 
				WHERE month = '+@pMonth+' AND year = '+@pYear+' AND branch_code = '''+@pBranchCode+'''
				AND perf_measure_code IN (06, 07, 08, 09))
				UNION					
			(SELECT ''2'', SUM(performance) FROM monthly_score_card_branch
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND branch_code = '''+@pBranchcode+'''
					AND perf_measure_code IN (15, 16))
				UNION
			(SELECT ''3'', SUM(performance) FROM monthly_score_card_branch 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND branch_code = '''+@pBranchcode+'''
					AND perf_measure_code IN (10, 11, 12, 13, 14))
				UNION
			(SELECT ''4'', SUM(performance) FROM monthly_score_card_branch 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND branch_code = '''+@pBranchcode+'''
					AND perf_measure_code IN (01,02,03,04, 05))
				UNION
			(SELECT ''5'', SUM(performance) FROM monthly_score_card_branch 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND branch_code = '''+@pBranchcode+'''
					AND perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24))
				UNION
			(SELECT ''6'',  SUM(performance) FROM monthly_score_card_branch
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND branch_code = '''+@pBranchcode+''' 
					AND perf_measure_code BETWEEN 01 AND 24)		)B
			ON A.id = 	B.id'							
		
	
	EXECUTE SP_EXECUTESQL @sql

	END
		

	
	



/** Account Officer Reports **/

IF @pAccountOfficer IS NOT NULL
			
	BEGIN
			
				
		/** Checking for Staff Type**/
			SELECT @type = sbu_id from account_officers where staff_id = @pAccountOfficer
				
				IF @type = 'S001'
				SELECT @type2 = staff_type from account_officers where staff_id = @pAccountOfficer
					IF @type2 NOT IN ('DA', 'MA')
						SELECT @type2 = staff_type from account_officers where staff_id = @pAccountOfficer
							IF @type2 = 'RMO'
								SET @type2 = 'retail_rmo'
				IF @type = 'S002'
				SET @type2 = 'comm_rmo'

			IF @type IN ('S001', 'S002')

			BEGIN
					
			/** Report Summary View **/
			SET @sql = '
			SELECT A.Measure AS Perspective, '+@type2+' AS target, B.performance 
			FROM monthly_score_card_performance A
			JOIN
			(
			(SELECT ''1'' AS id,  SUM(performance) AS performance FROM monthly_score_card_account_officers 
				WHERE month = '+@pMonth+' AND year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+'''
				AND perf_measure_code IN (06, 07, 08, 09))
				UNION					
			(SELECT ''2'', SUM(performance) FROM monthly_score_card_account_officers
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+'''
					AND perf_measure_code IN (15, 16))
				UNION
			(SELECT ''3'', SUM(performance) FROM monthly_score_card_account_officers 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+'''
					AND perf_measure_code IN (10, 11, 12, 13, 14))
				UNION
			(SELECT ''4'', SUM(performance) FROM monthly_score_card_account_officers 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+'''
					AND perf_measure_code IN (01,02,03,04, 05))
				UNION
			(SELECT ''5'', SUM(performance) FROM monthly_score_card_account_officers 
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+'''
					AND perf_measure_code IN (17, 18, 19, 20, 21, 22, 23, 24))
				UNION
			(SELECT ''6'',  SUM(performance) FROM monthly_score_card_account_officers
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 01 AND 24)		)B
			ON A.id = 	B.id'	
		
		
			END
			

	EXECUTE SP_EXECUTESQL @sql
		
	END

	
	

