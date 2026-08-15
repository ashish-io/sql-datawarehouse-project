create or replace procedure load_silver()
language plpgsql
as $$
begin

	--load crm_cust_info table
	truncate table silver.crm_cust_info;
	insert  into silver.crm_cust_info (
	   cst_id,
	   cst_key,
	   cst_firstname,
	   cst_lastname,
	   cst_marital_status,
	   cst_gndr,
	   cst_create_date
	   
	   )
	
	select 
	 cst_id,
	 cst_key,
	 --cleanup unwanted space 
	 trim(cst_firstname) as cst_firstname,
	 trim(cst_lastname) as cst_lastname,
	 
	 --normalize gender and marital status value to readable format
	 case when upper(cst_marital_status) = 'M' then 'Married'
	      when upper(cst_marital_status) = 'S' then 'Single'
	      else 'n/a'
	 end,
	 
	 
	 case when upper(cst_gndr) = 'F' then 'Female'
	      when upper(cst_gndr) = 'M' then 'Male'
	      else 'n/a'
	  end,
	 cst_create_date
	from 
	
		(
		select * from(
		select * ,
		row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
		from bronze.crm_cust_info cci 
		where cci.cst_id is not null
		) as t
		where flag_last = 1); --select the latest record per customer
	 
		
	
		
		--load crm_prd_info table
		truncate table silver.crm_prd_info;
		insert into silver.crm_prd_info (
		 prd_id,
		 cat_id,
		 prd_key,
		 prd_nm,
		 prd_cost,
		 prd_line,
		 prd_start_dt,
		 prd_end_dt
		 
		) 
		select 
		  cpi.prd_id,
		  replace(substring(prd_key, 1, 5), '-', '_') as cat_id, --extract category id
		  substring(prd_key, 7, length(prd_key)) as prd_key,     --extract product id
		  prd_nm,
		  coalesce(prd_cost, 0) as prd_cost,
		  case 
		  	when upper(trim(prd_line)) = 'R' then 'Road'
		  	when upper(trim(prd_line)) = 'M' then 'Mountain'
		  	when upper(trim(prd_line)) = 'S' then 'Other Sales'
		  	when upper(trim(prd_line)) = 'T' then 'Touring'
		  	else 'n/a'
		  end as prd_line,
		  prd_start_dt,
		  lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) -1 as prd_end_dt --calculate end date as a day before start date for 
		   
		from bronze.crm_prd_info cpi ;
		
		--load crm sales detail
		truncate table silver.crm_sales_details;
		insert into silver.crm_sales_details (
		  sls_ord_num,
		  sls_prd_key,
		  sls_cust_id,
		  sls_order_dt,
		  sls_ship_dt,
		  sls_due_dt,
		  sls_sales,
		  sls_quantity,
		  sls_price
		)
		select  
		  sls_ord_num,
		  sls_prd_key,
		  sls_cust_id,
		  case 
		  	when sls_order_dt = 0 or length(sls_order_dt::text) != 8 then null 
		  	else sls_order_dt:: text :: date
		  end as sls_order_dt,
		  
		   case 
		  	when sls_ship_dt = 0 or length(sls_ship_dt::text) != 8 then null 
		  	else sls_ship_dt:: text :: date --converting from interger to string then in date datatype
		  end as sls_ship_dt,
		  
		   case 
		  	when sls_due_dt = 0 or length(sls_due_dt::text) != 8 then null 
		  	else sls_due_dt:: text :: date  --converting from interger to srting then in date datatype
		  end as sls_due_dt,
		  
		  case
		
			when csd.sls_sales <= 0 or csd.sls_sales is null or csd.sls_sales  != abs(csd.sls_price)  * csd.sls_quantity then abs(csd.sls_price)  * csd.sls_quantity
		    else csd.sls_sales
	      end as  sls_sales, --recalculate sales if original value is wrong or missing
	      sls_quantity,
	      case
		   when csd.sls_price is null or csd.sls_price <= 0 then csd.sls_sales/nullif(csd.sls_quantity, 0)
		   else csd.sls_price
	      end as  sls_price --derive sales from quantity and sales if value if missing or wrong
		  
		from bronze.crm_sales_details csd ;
		  
		  
		--load into erp customer az12 table
		truncate table silver.erp_cust_az12;
		insert into silver.erp_cust_az12 (
		  cid,
		  bdate,
		  gen
		)
		select 
		  case
		  	when eca.cid like 'NAS%' then substring(eca.cid,4,length(cid))
		  end as cid,
		  
		  case
		  	when eca.bdate > current_date then null
		  	else eca.bdate
		  end as bdate,
		  
		  case
		  	when trim(eca.gen) = 'F' then 'Female'
		  	when trim(eca.gen) = 'M' then 'Male'
		  	when eca.gen is null then 'n/a'
		  	when trim(eca.gen) = '' then 'n\a'
		  	else eca.gen
		  end as gen
		  
		from bronze.erp_cust_az12 eca  ;
			
		
		
	-- load erp customer location table
	truncate table silver.erp_loc_a101;	
	insert into silver.erp_loc_a101 (
	  cid,
	  cntry
	)
	select 
	  replace(cid, '-','') as cid,
	  case 
	  	when cntry is null or trim(cntry) = '' then  'n/a'
	  	when upper(trim(cntry)) = 'DE' then 'Germany'
	  	when upper(trim(cntry)) = 'US' or upper(trim(cntry)) = 'USA' then 'United States'
	  	else cntry
	  end as cntry
	  
		    
	from bronze.erp_loc_a101;
	
	
	-- insert into erp product category table
	
	truncate table silver.erp_px_cat_g1v2;
	insert into silver.erp_px_cat_g1v2 (
	  id,
	  cat,
	  subcat,
	  maintenance 
	 )
	select 
	  epcgv.id ,
	  epcgv.cat ,
	  epcgv.subcat ,
	  epcgv.maintenance 
	from bronze.erp_px_cat_g1v2 epcgv ;

end;
$$;









