/**
1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the 
APAC region. 
**/
select distinct market from dim_customer
where customer="Atliq Exclusive" and region="APAC";

/**
2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains 
these fields, unique_products_2020 unique_products_2021 percentage_chg
**/

select 
sum(CASE WHEN cost_year=2020 then 1 else null end ) as unique_products_2020,
sum(CASE WHEN cost_year=2021 then 1 else null end ) as unique_products_2021,
100*(sum(CASE WHEN cost_year=2021 then 1 else null end )-sum(CASE WHEN cost_year=2020 then 1 else null end ))/sum(CASE WHEN cost_year=2020 then 1 else null end ) as "percentage_chg"
from fact_manufacturing_cost
;

/**
3. Provide a report with all the unique product counts for each segment and 
sort them in descending order of product counts. The final output contains 2 fields, 
segment, product_count
**/ 
select * from dim_product;

select segment,count( distinct product) as product_count  from dim_product
group by 1
order by 2 desc;

/**
4. Which segment had the most increase in unique products in 2021 vs 2020? 
The final output contains these fields--> segment ,product_count_2020, product_count_2021, difference
**/
SELECT segment,
count(case when cost_year=2020 then 1 else null end) product_count_2020,
count(case when cost_year=2021 then 1 else null end) product_count_2021,
count(case when cost_year=2021 then 1 else null end) - count(case when cost_year=2020 then 1 else null end) as difference
from dim_product
inner join fact_manufacturing_cost
 using(product_code)
 group by 1
 order by difference desc;
 
 /**
 5. Get the products that have the highest and lowest manufacturing costs. 
 The final output should contain these fields
 product_code, product, manufacturing_cost
 **/
select product_code,product,manufacturing_cost 
from fact_manufacturing_cost
join dim_product
using(product_code)
where manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) 
or manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
; 

/**
Generate a report which contains the top 5 customers who received an average high 
pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
The final output contains these fields---> customer_code, customer, average_discount_percentage

**/
select * from dim_customer;
select * from fact_pre_invoice_deductions;

select customer_code,customer,round(100*avg(pre_invoice_discount_pct),2) as average_discount_percentage
from dim_customer
join fact_pre_invoice_deductions
using(customer_code)
group by 1,2
order by 3 desc
limit 5;

/**
7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month, Year, Gross sales Amount
**/

select monthname(date) as month_,year(date) as year,
sum(gross_price*sold_quantity) as gross_sales_amount 
from fact_sales_monthly
join dim_customer
using(customer_code)
join fact_gross_price
using(product_code)
where customer="Atliq Exclusive"
group by 1,2;

/**
8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields 
sorted by the total_sold_quantity Quarter amd total_sold_quantity
**/
select quarter(date) as quarter_2020, sum(sold_quantity) as  total_sold_quantity
from fact_sales_monthly
where year(date) = 2020
group by 1
order by 1 desc;

/**
9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of 
contribution? The final output contains these fields---> channel, gross_sales_mln, percentage 
**/

with table1 as(
SELECT channel,
round(sum(sold_quantity*gross_price)/1000000,2) as gross_sales_mln
 from fact_sales_monthly
join fact_gross_price
using(product_code)
join dim_customer
using(customer_code)
where fact_sales_monthly.fiscal_year=2021
group by 1
)

select channel,gross_sales_mln,round(100*gross_sales_mln/total_sales,2) as percentage  from table1
CROSS JOIN
(select sum(gross_sales_mln) as total_sales from table1) as t
order by 2 desc;

/**
Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields --->
division, product_code, product, total_sold_quantity, rank_order 
**/ 

with cte as(
select division,product_code,product,
sum(sold_quantity) as total_sold_quantity
from dim_product
join fact_sales_monthly
using(product_code)
group by 1,2,3
)
select * from(
select *,
ROW_NUMBER() over(partition by division  order by total_sold_quantity desc ) as rank_order
from cte)b
where rank_order<=3;