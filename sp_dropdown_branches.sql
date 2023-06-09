USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_dropdown_branches]    Script Date: 2/28/2023 8:35:40 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_dropdown_branches]
    @pZoneCode nvarchar(50),
	@pRunDate nvarchar(50)
AS   

SET NOCOUNT ON;  

select *
from 
(
    select 'ALL' as branch_code, 'ALL' as branch_name
    union
    select branch_code, branch_name 
	from branches 
	where zone_code = @pZoneCode
    and month(structure_date) = month(@pRunDate)
	and year(structure_date) = year(@pRunDate)
	and status ='Y'
) a 
order by CASE WHEN branch_name = 'ALL' THEN '' ELSE branch_name END