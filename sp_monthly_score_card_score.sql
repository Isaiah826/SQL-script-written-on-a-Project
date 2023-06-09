USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_monthly_score_card_score]    Script Date: 2/28/2023 8:57:50 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER     procedure [dbo].[sp_monthly_score_card_score]
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
		@Branchcode NVARCHAR(50)



/** Directorate Report **/
IF @pDirectorateCode = 'ALL'
			
	BEGIN

	
		SET @sql = '
			SELECT ''Name'', NULL, ''Wema Bank'' 
			UNION
			(SELECT ''Score'', SUM(performance)/3,  CASE WHEN SUM(performance)/4 BETWEEN 00 AND 54.9 THEN ''F''
								WHEN SUM(performance)/4 BETWEEN 55 AND 64.9 THEN ''C''
								WHEN SUM(performance)/4 BETWEEN 65 AND 79.9 THEN ''B''
								WHEN SUM(performance)/4 BETWEEN 80 AND 95.9 THEN ''A''
								WHEN SUM(performance)/4 BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+' 
					AND perf_measure_code BETWEEN 01 AND 24) '

		
	EXECUTE SP_EXECUTESQL @sql
	

	END		



ELSE IF @pDirectorateCode IS NOT NULL
			
	BEGIN

	
		SET @sql = '
			SELECT ''Name''AS ''-'', NULL, directorate_name AS''-'' from vw_base_structure
				WHERE directorate_code = '''+@pDirectorateCode+''' AND MONTH(structure_date) = '+@pMonth+' and YEAR(structure_date) = '+@pYear+'
			UNION
			(SELECT ''Score'', SUM(performance),  CASE WHEN SUM(performance) BETWEEN 00 AND 54.9 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64.9 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79.9 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95.9 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_directorate
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND directorate_code = '''+@pDirectorateCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24) '

		
	EXECUTE SP_EXECUTESQL @sql
	

	END		


/** Region Report **/

IF @pRegionCode IS NOT NULL
			
	BEGIN

	
		SET @sql = '
			SELECT ''Name''AS ''-'', NULL, region_name AS''-'' from vw_base_structure
				WHERE region_code = '''+@pRegionCode+''' AND MONTH(structure_date) = '+@pMonth+' and YEAR(structure_date) = '+@pYear+'
			UNION
			(SELECT ''Score'', SUM(performance),  CASE WHEN SUM(performance) BETWEEN 00 AND 54.9 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64.9 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79.9 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95.9 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_region
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND region_code = '''+@pRegionCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24) '


		
	EXECUTE SP_EXECUTESQL @sql
	

	END		




/** Zone Report **/

IF @pZoneCode IS NOT NULL
			
	BEGIN

	
		SET @sql = '
			SELECT ''Name''AS ''-'', NULL, zone_name AS''-'' from vw_base_structure
				WHERE zone_code = '''+@pZoneCode+''' AND MONTH(structure_date) = '+@pMonth+' and YEAR(structure_date) = '+@pYear+'
			UNION
			(SELECT ''Score'', SUM(performance),  CASE WHEN SUM(performance) BETWEEN 00 AND 54.9 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64.9 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79.9 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95.9 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_zone
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND zone_code = '''+@pZoneCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24) '
			


		
	EXECUTE SP_EXECUTESQL @sql
	

	END		

	


	
	/** Branches Report **/

IF @pBranchCode IS NOT NULL
		
	BEGIN
					
		
			SET @sql = '
			SELECT ''Name''AS ''-'', NULL, branch_name AS''-'' from vw_base_structure
				WHERE branch_code = '''+@pBranchCode+''' AND MONTH(structure_date) = '+@pMonth+' and YEAR(structure_date) = '+@pYear+'
			UNION
			(SELECT ''Score'', SUM(performance), CASE WHEN SUM(performance)BETWEEN 00 AND 54.9 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64.9 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79.9 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95.9 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_branch
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND branch_code = '''+@pBranchCode+''' 
					AND perf_measure_code BETWEEN 01 AND 24) '

	
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
					
			SET @sql = '
			SELECT ''Name''AS ''-'', NULL,  staff_name AS''-'' from account_officers
				WHERE staff_id = '''+@pAccountOfficer+''' AND MONTH(structure_date) = '+@pMonth+' and YEAR(structure_date) = '+@pYear+'
			UNION
			(SELECT ''Score'', SUM(performance), CASE WHEN SUM(performance)BETWEEN 00 AND 54.9 THEN ''F''
								WHEN SUM(performance) BETWEEN 55 AND 64.9 THEN ''C''
								WHEN SUM(performance) BETWEEN 65 AND 79.9 THEN ''B''
								WHEN SUM(performance) BETWEEN 80 AND 95.9 THEN ''A''
								WHEN SUM(performance) BETWEEN 96 AND 100 THEN ''A+''
								END
				FROM monthly_score_card_account_officers
				WHERE month = '+@pMonth+' and year = '+@pYear+' AND staff_id = '''+@pAccountOfficer+''' 
					AND perf_measure_code BETWEEN 01 AND 24) '
		
			END

		

	EXECUTE SP_EXECUTESQL @sql
			
	END

	
	

