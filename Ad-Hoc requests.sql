/*1. Provide a list of products with a base price greater than 500 and that are 
featured in promo type of 'BOGOF' (Buy One Get One Free). */

SELECT DISTINCT P.product_name FROM fact_events E
INNER JOIN dim_products P
ON E.product_code=P.product_code
WHERE E.promo_type="BOGOF" 
AND
E.base_price>500;

/*2. Generate a report that provides an overview of the number of stores in each city.
The result should be sorted in descending order of store counts, alloing us to 
identify the cities with highest score presence. The report includes two
essential fields:city and count
*/
SELECT city, count(*) AS 'Count'
FROM dim_stores
GROUP BY city
ORDER BY COUNT DESC;

/*3. Generate a report that displays each campaign along with the total revenue
generated before and after the campaign. The report should include three key fields 
campaign_name,total_revenue(before promotion),total_revenue(after promotion)
Display the value in millions*/

WITH CTE AS (
SELECT C.campaign_name,E.base_price*E.quantity_sold_before AS 'sales_before',
CASE 
WHEN E.promo_type='BOGOF' THEN quantity_sold_after*2 
ELSE quantity_sold_after
END AS 'adjusted_quantity',
CASE 
WHEN E.promo_type='BOGOF' THEN base_price/2
WHEN E.promo_type='500 Cashback' THEN base_price-500
WHEN E.promo_type='50% OFF' THEN base_price*0.5
WHEN E.promo_type='33% OFF' THEN base_price*0.67
WHEN E.promo_type='25% OFF' THEN base_price*0.75
END AS 'Adjusted_baseprice'   
FROM fact_events E 
INNER JOIN dim_campaigns C
ON E.campaign_id=C.campaign_id)
SELECT campaign_name,ROUND(SUM(sales_before)/1000000,1) AS 'Revenue Before in Millions',
ROUND(SUM(adjusted_quantity*Adjusted_baseprice)/1000000,1) AS 'Sales After in Millions'
FROM CTE
GROUP BY campaign_name

/*
4. Produce a report that calculates the Incremental Sold quanity (ISU%) for each 
category durung the Diwali campaign. Additionally provide ranking for the categories 
based on their ISU%. 
The report will include three key fields: category,ISU% and rank order*/

WITH CTE AS (
SELECT P.category,SUM(E.quantity_sold_before) AS 'Quantity_Before',
SUM(CASE 
WHEN E.promo_type='BOGOF' THEN E.quantity_sold_after*2 ELSE E.quantity_sold_after
END) AS 'Adjusted_quantity'
FROM fact_events E 
INNER JOIN dim_products P 
ON P.product_code=E.product_code
INNER JOIN dim_campaigns C
ON C.campaign_id=E.campaign_id
WHERE C.campaign_name="Diwali"
GROUP BY category)
SELECT category,
(Adjusted_quantity-Quantity_Before)/Quantity_Before*100 AS 'ISU%',
RANK() OVER(ORDER BY (Adjusted_quantity-Quantity_Before)/Quantity_Before*100 DESC) AS 'Rank'
FROM CTE;

/*
5. Create a report featuring the Top 5 product, ranked by Incremental Revenue Percentage
(IR%) across all the campaigns. 
The report will provide essential information regarding : Product name, category,IR%
*/
WITH CTE AS (
SELECT P.product_name,P.category,
E.base_price*E.quantity_sold_before AS 'sales_before',
CASE 
WHEN E.promo_type='BOGOF' THEN quantity_sold_after*2 
ELSE quantity_sold_after
END AS 'adjusted_quantity',
CASE 
WHEN E.promo_type='BOGOF' THEN base_price/2
WHEN E.promo_type='500 Cashback' THEN base_price-500
WHEN E.promo_type='50% OFF' THEN base_price*0.5
WHEN E.promo_type='33% OFF' THEN base_price*0.67
WHEN E.promo_type='25% OFF' THEN base_price*0.75
END AS 'Adjusted_baseprice'   
FROM fact_events E 
INNER JOIN dim_products P
ON P.product_code=E.product_code),
CTE2 AS (
SELECT product_name, category,
sales_before,
adjusted_quantity*Adjusted_baseprice AS 'Sales_After' FROM CTE)
SELECT product_name,category,ROUND((SUM(Sales_After)-SUM(sales_before))/SUM(sales_before)*100,2) AS 'IR%'
FROM CTE2
GROUP BY product_name,category
ORDER BY (SUM(Sales_After)-SUM(sales_before))/SUM(sales_before) DESC
LIMIT 5