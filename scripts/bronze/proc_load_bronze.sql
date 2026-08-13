create or replace procedure load_bronze()
language plpgsql
as $$
begin

raise notice '========================================';
raise notice ' loading bronze layer';
raise notice '========================================';

raise notice '----------------------------------------';
raise notice 'lading crm table';
raise notice '----------------------------------------';

truncate table bronze.crm_cust_info;
copy bronze.crm_cust_info
from '/var/lib/postgresql/import/source_crm/cust_info.csv'
with (
format csv ,
header true,
delimiter ','
);

truncate table bronze.crm_prd_info;
copy bronze.crm_prd_info
from '/var/lib/postgresql/import/source_crm/prd_info.csv'
with (
format csv ,
header true,
delimiter ','
);


truncate table bronze.crm_sales_details;
copy bronze.crm_sales_details
from '/var/lib/postgresql/import/source_crm/sales_details.csv'
with (
format csv ,
header true,
delimiter ','
);

raise notice '----------------------------------------';
raise notice 'lading erp table';
raise notice '----------------------------------------';

truncate table bronze.erp_cust_az12;
copy bronze.erp_cust_az12
from '/var/lib/postgresql/import/source_erp/CUST_AZ12.csv'
with (
format csv ,
header true,
delimiter ','
);

truncate table bronze.erp_loc_a101;
copy bronze.erp_loc_a101
from '/var/lib/postgresql/import/source_erp/LOC_A101.csv'
with (
format csv ,
header true,
delimiter ','
);

truncate table bronze.erp_px_cat_g1v2;
copy bronze.erp_px_cat_g1v2
from '/var/lib/postgresql/import/source_erp/PX_CAT_G1V2.csv'
with (
format csv ,
header true,
delimiter ','
);

end;
$$
