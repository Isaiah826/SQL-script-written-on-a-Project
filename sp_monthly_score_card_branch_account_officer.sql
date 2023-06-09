USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_monthly_score_card_branch_account_officer]    Script Date: 2/28/2023 8:57:40 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_monthly_score_card_branch_account_officer]
		@pMonth NVARCHAR(10), 
		@pYear NVARCHAR(10)


AS

--SET @pMonth = 07
--SET @pYear = 2022

BEGIN
	
	--SELECT a.branch_code, b.branch_name, a.staff_id, a.staff_name
	--FROM account_officers a
	--JOIN vw_base_structure b
	--ON a.branch_code = b.branch_code AND a.structure_date = b.structure_date
	--WHERE MONTH(a.structure_date) = @pMonth AND YEAR(a.structure_date) = @pYear

	SELECT DISTINCT A.score_card_id, A.staff_id, B.staff_name, C.branch_code, C.zone_code, C.region_code, C.directorate_code 
	FROM confirmation_score_card_report A
	JOIN account_officers B
	ON A.staff_id = B.staff_id OR  A.staff_id = SUBSTRING (B.staff_id,2,5)
	left JOIN vw_base_structure_account_officers C
	ON A.staff_id = C.staff_id OR  A.staff_id = SUBSTRING (C.staff_id,2,5)
	WHERE MONTH(B.structure_date) = @pMonth AND YEAR(B.structure_date) = @pYear
	

END