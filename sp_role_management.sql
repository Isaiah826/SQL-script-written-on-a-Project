USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_role_management]    Script Date: 2/28/2023 8:31:07 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_role_management]--'S07444'

@user_id varchar (20)

as 
declare @sql nvarchar(4000)
declare @max_date  date
--select @user_id = staff_id from account_officers union select staff_id from account_officers_sp
select @max_date = MAX(structure_date) from account_officers

--if @user_id in (select staff_id from account_officers where structure_date = @max_date 
--	union select staff_id from account_officers_sp)


begin
set @sql ='
select a.user_id,directoratecode, 
regionCode,clustercode,zonecode,branchcode, report_id,sbucode, role_function_id, privileges, role_name,user_viewer,rpt_code,
CASE WHEN role_function_id = ''MA001'' THEN ''Account_Officer''
		WHEN role_function_id = ''CMRMO001'' THEN ''Account_Officer''
		WHEN role_function_id = ''CPRMO001'' THEN ''Account_Officer''
		WHEN role_function_id = ''TRMO001'' THEN ''Account_Officer''
		WHEN role_function_id = ''PSRMO001'' THEN ''AccountOfficer''
		WHEN role_function_id = ''RTRMO001'' THEN ''Account_Officer''
		WHEN role_function_id = ''PMSH001'' THEN ''ALL''
		WHEN role_function_id = ''DH001'' THEN ''Directorate''
		WHEN role_function_id = ''ZSM0001'' THEN ''Region''		
		WHEN role_function_id = ''RGM001'' THEN ''Region''
		WHEN role_function_id = ''DMD001'' THEN ''Region''
		WHEN role_function_id = ''MD001'' THEN ''ALL''
		WHEN role_function_id = ''TR001'' THEN ''Region''
		WHEN role_function_id = ''RCH001'' THEN ''Cluster''
		WHEN role_function_id = ''PMS001'' THEN ''ALL''
		WHEN role_function_id = ''CFO001'' THEN ''Region''
		WHEN role_function_id = ''PMO001'' THEN ''Account_Officer''
		WHEN role_function_id = ''DPH001'' THEN ''Region''
		WHEN role_function_id = ''OBO001'' THEN ''Account_Officer''
		WHEN role_function_id = ''RSM001'' THEN ''Account_Officer''
		WHEN role_function_id = ''FINH001'' THEN ''ALL''
		WHEN role_function_id = ''BSM001'' THEN ''Zone''
		WHEN role_function_id = ''ADO001'' THEN ''Zone''
		WHEN role_function_id = ''CCC001'' THEN ''Zone''
		WHEN role_function_id = ''CHRO001'' THEN ''Zone''
		WHEN role_function_id = ''CIOO001'' THEN ''Zone''
		WHEN role_function_id = ''CISO001'' THEN ''Zone''
		WHEN role_function_id = ''CRO001'' THEN ''Zone''
		WHEN role_function_id = ''CTO001'' THEN ''Zone''
		WHEN role_function_id = ''RM001'' THEN ''Region''		
		WHEN role_function_id = ''DHRS001'' THEN ''Zone''
		WHEN role_function_id = ''ERBI0001'' THEN ''ALL''
		WHEN role_function_id = ''HDB0001'' THEN ''ALL''
		WHEN role_function_id = ''HGAS0001'' THEN ''ALL''
		WHEN role_function_id = ''ZSM001'' THEN ''Account_Officer''
		WHEN role_function_id = ''PM001'' THEN ''ALL''
		WHEN role_function_id = ''PMSH001'' THEN ''ALL''
		WHEN role_function_id = ''HCT001'' THEN ''ALL''
		WHEN role_function_id = ''ZM001'' THEN ''Zone''
		WHEN role_function_id = ''BDM001'' THEN ''Branch''
		WHEN role_function_id = ''BOS001'' THEN ''Account_Officer''
		ELSE ''ALL'' END AS drill_start
from wa_user a -- we have user_id
join user_role_report_function_map c --we have user_id
on a.user_id =c.user_id 
join  wa_roles_function_map d --we have user_id, report_id and function id
on c.role_function_id =d.role_id
LEFT join   head_office_espense_user z
on a.user_id = z.staff_id
where a.user_id = '''+@user_id+''';'
--join wa_functions e
--on c.role_function_id = e.function_id;
end

print @sql
execute sp_executesql @sql;
--SELECT * FROM head_office_espense_user