USE [wema_analytics]
GO
/****** Object:  StoredProcedure [dbo].[sp_post_etl_load_deposits_base_retail]    Script Date: 2/28/2023 9:19:18 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_post_etl_load_deposits_base_retail]
    @v_date date
AS   

SET NOCOUNT ON; 

delete
from deposits_base_retail
where eod_date = @v_date; 

insert into deposits_base_retail (
	foracid, acct_name, acct_mgr_user_id, free_code_4, product_code,
	gl_sub_head_code, acct_opn_date, sol_id, rate, rate_dr, sol_desc,
	acct_crncy_code, naira_value, average_deposit,
	int_expense, int_income, eod_date
)
/* accounts not in double-counted, shared or negative deposits */
select x.foracid, x.acct_name, x.acct_mgr_user_id_3, x.free_code_4, x.product_code,
x.gl_sub_head_code, x.acct_opn_date, x.sol_id, x.rate, x.rate_dr, x.sol_desc,
x.acct_crncy_code, 
(case when x.naira_value > 0 then x.naira_value else 0 end) as naira_value, 
(case when x.average_deposit > 0 then x.average_deposit else 0 end) as average_deposit, 
x.int_expense, 0, x.eod_date
FROM balances_base x 
inner join gl_map z
on x.gl_sub_head_code = z.sh
inner JOIN account_officers y 
on x.acct_mgr_user_id_3 = y.staff_id
inner join retail_gl_sub_heads_deposits r
on x.gl_sub_head_code=r.gl_sub_head
left join accounts_exempted_retail_deposits_by_cluster a
on x.foracid = a.account_number
left join retail_deposits_backout f
on x.foracid=f.foracid
where z.MainCaption = '9'
and x.eod_date = @v_date
and ((x.naira_value > 0) or (x.average_deposit > 0)) 
and x.foracid not in (select foracid from negative_deposits)
and month(x.eod_date) = month(y.structure_date)
and year(x.eod_date) = year(y.structure_date)
and a.account_number is null
and f.foracid is null

union

/* accounts in negative deposits */
select x.foracid, acct_name, acct_mgr_user_id_3, free_code_4, product_code,
gl_sub_head_code, acct_opn_date, x.sol_id, rate, rate_dr, sol_desc,
acct_crncy_code, naira_value, average_deposit_dr, 
int_expense, int_income, eod_date
FROM balances_base x 
inner join gl_map z
on x.gl_sub_head_code = z.sh
inner JOIN account_officers y 
on x.acct_mgr_user_id_3 = y.staff_id
inner join retail_gl_sub_heads_deposits r
on x.gl_sub_head_code=r.gl_sub_head
left join accounts_exempted_retail_deposits_by_cluster a
on x.foracid = a.account_number
left join retail_deposits_backout f
on x.foracid=f.foracid
where z.MainCaption = '9'
and x.eod_date = @v_date
and x.foracid in (select foracid from negative_deposits)
and month(x.eod_date) = month(y.structure_date)
and year(x.eod_date) = year(y.structure_date)
and a.account_number is null
and f.foracid is null

union

-- deposits with negative balances and no loan leg
select x.foracid, acct_name, acct_mgr_user_id_3, free_code_4, product_code,
gl_sub_head_code, acct_opn_date, x.sol_id, rate, rate_dr, sol_desc,
acct_crncy_code, naira_value, average_deposit_dr, 
int_expense, int_income, eod_date
FROM balances_base x 
inner join gl_map z
on x.gl_sub_head_code = z.sh
inner JOIN account_officers y 
on x.acct_mgr_user_id_3 = y.staff_id
inner join retail_gl_sub_heads_deposits r
on x.gl_sub_head_code=r.gl_sub_head
left join accounts_exempted_retail_deposits_by_cluster a
on x.foracid = a.account_number
left join retail_deposits_backout f
on x.foracid=f.foracid
where z.MainCaption = '9'
and x.eod_date = @v_date
and gl_sub_head_code not in (select sh from gl_map where MainCaption = '14')
and ((x.naira_value <= 0) and (x.average_deposit_dr < 0)) 
and x.foracid not in (select foracid from negative_deposits)
and month(x.eod_date) = month(y.structure_date)
and year(x.eod_date) = year(y.structure_date)
and a.account_number is null
and f.foracid is null

-- set negative interest rates for deposits to zero
update deposits_base_retail
set rate = 0,
int_expense = 0
where eod_date = @v_date
and  rate < 0;