
create view gold.dim_customer as 
select 
    row_number() over(order by cci.cst_id) as customer_key,
	cci.cst_id as customer_id,
	cci.cst_key as customer_number ,
	cci.cst_firstname as first_name,
	cci.cst_lastname as last_name ,
	ela.cntry as country,
	cci.cst_marital_status as marital_status,
	case
		when cci.cst_gndr = 'Female' then 'Female'
	    when cci.cst_gndr = 'Male' then 'Male'
	    when cci.cst_gndr = 'n/a' then coalesce(eca.gen, 'n/a')   
	end as gender ,
	eca.bdate as birth_date,
	cci.cst_create_date as create_date  		
from silver.crm_cust_info cci left join silver.erp_cust_az12 eca 
on cci.cst_key = eca.cid 
left join silver.erp_loc_a101 ela
on eca.cid = ela.cid 


create view gold.dim_products as
select
   row_number() over(order by cpi.prd_start_dt ,cpi.prd_key) as product_key,
   cpi.prd_id  as product_id,
   cpi.prd_key as product_number,
   cpi.prd_nm as product_name,
   cpi.cat_id as category_id ,
   epcgv.cat as category,
   epcgv.subcat as subcategory,
   cpi.prd_cost as product_cost,
   cpi.prd_line as product_line,
   cpi.prd_start_dt as start_date,
   cpi.prd_end_dt as end_date,
   epcgv.maintenance 
from silver.crm_prd_info cpi left join silver.erp_px_cat_g1v2 epcgv  on cpi.cat_id = epcgv.id 
where cpi.prd_end_dt is null --filter our historical data

create view gold.fact_sales as 
select 
	csd.sls_ord_num as order_number,
	dp.product_key ,
	dc.customer_key,
	csd.sls_order_dt as order_date ,
	csd.sls_ship_dt  as ship_date,
	csd.sls_due_dt as due_date ,
	csd.sls_sales as sales_amount,
	csd.sls_quantity as quantity ,
	csd.sls_price  as price
from silver.crm_sales_details csd 
left join gold.dim_products dp on csd.sls_prd_key = dp.product_number
left join gold.dim_customer dc on csd.sls_cust_id = dc.customer_id 
