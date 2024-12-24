select * from production.brands 
select * from production.categories
select * from production.products
select * from production.stocks

select * from sales.customers
select * from sales.order_items
select * from sales.orders
select * from sales.stores
select * from sales.staffs

--STORES
--========== No of stores
select count(*) as Tota_Stores from sales.stores
--==========Distribution of stores by state
select store_name,state as Distribution_of_state from sales.stores

--STAFFS
--===========total_no_of_staffe
select APPROX_COUNT_DISTINCT(staff_id) as total_no_of_staffe 
from sales.staffs 
--===========Avg_no_of_staff_per_store  ليها رجعة
select avg(staff_count) as avg_staff
from (select store_id, count(*) as staff_count from sales.staffs
group by store_id)  as store_staff

--CATREGORIES
--==============total no of categories 
select count(*) as Total_Categories from production.categories

--BRANDS 
--==============total no of Brands
select count(*) as Total_Brands from production.brands

--PRODUCTS  ليها رجعه'
--==============totalno ofproducts
select APPROX_COUNT_DISTINCT(product_name) as Total_Products_names from production.products
select APPROX_COUNT_DISTINCT(product_id) as Total_Products  from production.products

-- CUSTOMERS
--============total no of customers
select COUNT(distinct(customer_id))  as total_no_of_customers from sales.customers

-- STOKES
--============total no of products in stoke
select sum(quantity) as total_stoke from production.stocks

--==BIKE SHARE ANALYSIS====
--========Sales and order analysis 
--========Total revenue======
select SUM(list_price *(1-discount) *quantity) as Revenue from sales.order_items
--========quantity sold======
select sum(quantity) from sales.order_items
--========Total revenue and quantity sold per years======
select DATENAME(year,order_date) as year, SUM(list_price *(1-discount) *quantity) as total_revenue ,
 sum(quantity) as quantity
from sales.order_items 
join sales.orders on sales.order_items.order_id = sales.orders.order_id
group by DATENAME(year,order_date)
order by DATENAME(year,order_date)
--========Total Monthly Revenue Aggregated over 3 year period======
select DATENAME(MONTH,order_date) as month, SUM(list_price *(1-discount) *quantity) as total_revenue 
from sales.order_items 
join sales.orders on sales.order_items.order_id = sales.orders.order_id
group by DATENAME (month,order_date)
order by total_revenue  desc

--==CUSTOMERANLYSIS
--======= Top 10 customersby total order value=====
select top 10 sales.customers .customer_id ,
concat(sales.customers.first_name ,' ', sales.customers.last_name) as customer_name , sales.customers.state as state
,sum(quantity) as Orders_count,
SUM(list_price *(1-discount) *quantity) as Total_Revenue
from sales.customers 
join 
sales.orders on sales.orders.customer_id = sales.customers.customer_id
join sales.order_items on sales.orders.order_id = sales.order_items.order_id
group by sales.customers.customer_id ,concat(sales.customers.first_name ,' ', sales.customers.last_name),state
order by  Total_Revenue desc
--========customer distribution and total sales by state===
select count(distinct c.customer_id) as customer_count , s.state,
SUM(list_price *(1-discount) *quantity) as Total_Sales
from sales.orders as o
join sales.customers as c on o.customer_id = c.customer_id
join sales.order_items on o.order_id = sales.order_items.order_id
join sales.stores  as s on o.store_id= s.store_id
group by s.state
order by Total_Sales desc

--====PRODUCT ANALYSIS
--===========top 10 products by total sales
select top 10 
      p.product_id,
	  p.product_name, 
      sum(oi.quantity) as total_quantity_sold,
      sum(oi.list_price *(1-oi.discount) *oi.quantity) as Total_Sales
from sales.order_items as oi
join production.products as p on oi.product_id = p.product_id
group by p.product_id, p.product_name
order by Total_Sales desc
--===========10 least profitable products
select top 10
      p.product_id,
	  p.product_name, 
      sum(oi.quantity) as total_quantity_sold,
      sum(oi.list_price *(1-oi.discount) *oi.quantity) as Total_Sales
from sales.order_items as oi
join production.products as p on oi.product_id = p.product_id
group by p.product_id, p.product_name
order by Total_Sales , total_quantity_sold asc

--BRANDS 
--==============total sales and avg sales price by brand
select b.brand_name,
round(sum(oi.list_price*(1-oi.discount)*oi.quantity),2) as Total_Sales , 
round(AVG(oi.list_price*(1-oi.discount)), 2) as AVG_sales_price
from production.brands as b
join production.products as p on b.brand_id = p.brand_id
join sales.order_items as oi on p.product_id = p.product_id
group by b.brand_name
order by Total_Sales desc

--CATEGORIES
--==============total sales and avg sales price by prouduct category
select ca.category_name,
sum(oi.list_price*(1-oi.discount)*oi.quantity) as Total_Sales , 
AVG(oi.list_price*(1-oi.discount)) as AVG_sales_price
from production.categories as ca
join production.products as p on ca.category_id = p.category_id
join sales.order_items as oi on p.product_id = p.product_id
group by ca.category_name
order by Total_Sales desc

--STORE ANALYSIS
--==============total sales by store
select s.store_id,store_name,s.city ,s.state ,
round(sum(oi.list_price*(1-oi.discount)*oi.quantity),2) as Total_Sales 
from sales.order_items as oi
join sales.orders as o on oi.order_id = o.order_id
join sales.stores as s  on s.store_id = o.store_id
group by s.store_id,store_name,s.city ,s.state 
order by Total_Sales desc
--==============most selling product for each store
with rankesProducts as (
select s.store_id,s.store_name,p.product_name ,
sum(oi.quantity) as units_sold,
RANK()over(partition by s.store_id order by sum(oi.quantity) desc) as Rank
from sales.order_items as oi
join sales.orders as o on oi.order_id = o.order_id
join sales.stores as s  on s.store_id = o.store_id
join production.products as p on oi.product_id = p.product_id
group by s.store_id,store_name,p.product_name
)
select store_id,store_name,product_name,units_sold
from rankesProducts
where rank=1

--STAFFS
--==============total no sofstaff per store
select stf.store_id,sto.store_name,count(*) as staff_count
from sales.staffs as stf
join sales.stores sto on stf.store_id = sto.store_id
group by stf.store_id , sto.store_name
--==============topp performance staff members by total sales and units sold
select top 10 concat(stf.first_name ,' ', stf.last_name) as staffe_name,
sum(oi.list_price*(1-oi.discount)*oi.quantity) as Total_Sales , 
sum(oi.quantity) as units_sold
from sales.staffs as stf
join sales.orders as o on stf.store_id = o.store_id
join sales.order_items as oi on oi.order_id =oi.order_id
group by stf.staff_id,stf.first_name,stf.last_name
order by Total_Sales desc
