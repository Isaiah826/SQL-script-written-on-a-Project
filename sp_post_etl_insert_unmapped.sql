USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_insert_unmapped]    Script Date: 2/28/2023 9:16:56 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_post_etl_insert_unmapped]
@v_date date
as

declare @prev_structure date
select @prev_structure = max(structure_date) from account_officers where staff_name = 'UNMAPPED' 

if (@v_date > @prev_structure) --and @v_date = EOMONTH(@v_date)
BEGIN

delete from account_officers where structure_date = EOMONTH(@v_date)
and staff_name = 'UNMAPPED' 

insert into account_officers
select distinct staff_id,staff_name,branch_code,sbu_id,status,email,staff_type,staff_grade,eomonth(@v_date)
from account_officers where structure_date = @prev_structure 
and staff_name = 'UNMAPPED' 

END
ELSE 
BEGIN
PRINT 'UNMAPPED Exists for the Month'
END



