USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_loans_retail_accounts]    Script Date: 2/28/2023 8:52:26 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_loans_retail_accounts]
    @pAccountOfficer nvarchar(50),
	@pStaffID nvarchar(50),
	@pRunDate nvarchar(50)
AS   

SET NOCOUNT ON;  

/* INSERT A LOG */
	insert into users_activities_log (staff_id, report_name, drilled_down_level, code, created_at)
	values (@pStaffID, 'LOANS_BY_CLUSTER', 'ACCOUNTS', @pAccountOfficer, GETDATE());

SELECT 
	a.foracid as 'Account Number', 
	a.acct_name as 'Account Name',
	a.product_code as 'Product Code',
	p.productname as 'Product Name',
	a.acct_crncy_code as 'Currency', 
	a.naira_value as 'Actual (N)', 
	a.average_deposit_dr as 'Average (N)',
	a.rate_dr as 'Rate',
	a.int_income as 'Int.Inc'
from loans_base_retail a
left join gl_map g on a.GL_SUB_HEAD_CODE = g.sh
left join products p on a.product_code = p.productcode
inner join retail_gl_sub_heads_loans r on a.gl_sub_head_code = r.gl_sub_head
left join retail_loans_backout d on a.foracid=d.foracid
where a.acct_mgr_user_id = @pAccountOfficer
and d.foracid is null
and g.MainCaption = '14'
and a.eod_date = @pRunDate