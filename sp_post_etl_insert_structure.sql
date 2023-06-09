USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_insert_structure]    Script Date: 2/28/2023 9:16:28 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_post_etl_insert_structure]
@v_date date
as

declare @prev_structure date
select @prev_structure = max(structure_date) from branches 

 
if (@v_date > @prev_structure) --and @v_date = EOMONTH(@v_date)
BEGIN


delete from branches where structure_date > @prev_structure
insert into branches
select distinct branch_code,branch_name,zone_code,cluster_code,bdm_staff_id,state,status,type,eomonth(@v_date)
from branches where structure_date = @prev_structure


delete from zones where structure_date > @prev_structure
insert into zones --(zone_code,zone_name,region_code,zone_head_staff_id,status,structure_date)
select distinct zone_code,zone_name,region_code,zone_head_staff_id,status,eomonth(@v_date)
from zones where structure_date = @prev_structure


delete from regions where structure_date > @prev_structure
insert into regions
select distinct region_code,region_name,directorate_code,region_head_staff_id,status,eomonth(@v_date)
from regions where structure_date = @prev_structure


delete from directorates where structure_date > @prev_structure
insert into directorates
select distinct directorate_code,directorate_name,directorate_head_staff_id,status,eomonth(@v_date)
from directorates where structure_date = @prev_structure


delete from branches_retail where structure_date > @prev_structure
insert into branches_retail
select distinct branch_code,branch_name,zone_code,cluster_code,bdm_staff_id,state,status,eomonth(@v_date)
from branches_retail where structure_date = @prev_structure


delete from clusters_retail where structure_date > @prev_structure
insert into clusters_retail
select distinct cluster_code,cluster_name,region_code,cluster_head_staff_id,status,eomonth(@v_date)
from clusters_retail where structure_date = @prev_structure


delete from regions_retail where structure_date > @prev_structure
insert into regions_retail
select distinct region_code,region_name,directorate_code,region_head_staff_id,status,eomonth(@v_date)
from regions_retail where structure_date =  @prev_structure


delete from directorates_retail where structure_date > @prev_structure
insert into directorates_retail
select distinct directorate_code,directorate_name,directorate_head_staff_id,status,eomonth(@v_date)
from directorates_retail where structure_date =  @prev_structure

delete from account_officers where structure_date > @prev_structure
insert into account_officers
select distinct staff_id,staff_name,branch_code,sbu_id,status,eomonth(@v_date)
from account_officers where structure_date =  @prev_structure

END
ELSE 
BEGIN
PRINT 'Structure Exists for the Month'
END

