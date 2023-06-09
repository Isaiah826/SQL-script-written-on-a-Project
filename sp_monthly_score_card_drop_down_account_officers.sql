USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_monthly_score_card_drop_down_account_officers]    Script Date: 2/28/2023 8:57:45 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER     PROCEDURE [dbo].[sp_monthly_score_card_drop_down_account_officers]
		@pMonth NVARCHAR(10), 
		@pYear NVARCHAR(10)


AS

--SET @pMonth = 07
--SET @pYear = 2022

BEGIN
	
	SELECT a.branch_code, b.branch_name, a.staff_id, a.staff_name
	FROM account_officers a
	JOIN vw_base_structure b
	ON a.branch_code = b.branch_code AND a.structure_date = b.structure_date
	WHERE MONTH(a.structure_date) = @pMonth AND YEAR(a.structure_date) = @pYear



END
