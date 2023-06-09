USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_delete_wrong_date]    Script Date: 2/28/2023 9:11:11 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_post_etl_delete_wrong_date]
AS   

SET NOCOUNT ON;  
DECLARE @v_date varchar(100);
DECLARE @v_last_day_of_month varchar(100);
DECLARE @v_last_wrk_day varchar(100);
--set @v_date = CONVERT(VARCHAR(10),DATEADD(DD, DATEDIFF(DD, 0, GETDATE()), -1),120);
set @v_date = '2021-02-20';
--set @v_last_day_of_month = EOMONTH(@v_date);
--set @v_last_wrk_day = dbo.fn_get_last_wrk_day(@v_date);

delete
from balances_base_raw
where eod_date = @v_date

delete
from account_activity_base_raw
where eod_date = @v_date

delete
from accounts_open_monthly_base_raw
where eod_date = @v_date

delete
from accounts_closed_monthly_base_raw
where eod_date = @v_date

delete
from accounts_dormant_monthly_base_raw
where eod_date = @v_date

delete
from accounts_reactivated_monthly_base_raw
where eod_date = @v_date

delete
from account_maintenance_base_raw
where eod_date = @v_date

delete
from balances_base
where eod_date = @v_date

delete
from account_activity_base
where eod_date = @v_date

delete
from accounts_open_monthly_base
where eod_date = @v_date

delete
from accounts_closed_monthly_base
where eod_date = @v_date

delete
from accounts_dormant_monthly_base
where eod_date = @v_date

delete
from accounts_reactivated_monthly_base
where eod_date = @v_date

delete
from account_maintenance_base
where eod_date = @v_date

delete
from deposits_base
where eod_date = @v_date

delete
from loans_base
where eod_date = @v_date

delete
from deposits_aggr
where eod_date = @v_date

delete
from loans_aggr
where eod_date = @v_date

delete
from account_activity_aggr
where eod_date = @v_date

delete
from accounts_open_monthly_aggr
where eod_date = @v_date

delete
from accounts_closed_monthly_aggr
where eod_date = @v_date

delete
from accounts_dormant_monthly_aggr
where eod_date = @v_date

delete
from accounts_reactivated_monthly_aggr
where eod_date = @v_date

delete
from account_maintenance_aggregation
where eod_date = @v_date

delete
from alco_deposit_aggregation
where eod_date = @v_date

delete
from alco_loan_aggregation
where eod_date = @v_date

delete
from balancesheet_aggregation
where eod_date = @v_date