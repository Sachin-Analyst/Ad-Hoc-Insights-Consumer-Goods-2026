# Request 01 
# Provide the list of markets in which customer "AtliQ Exclusive" operates its business in the APAC region 

	SELECT DISTINCT(market) FROM gdb023.dim_customer 
		WHERE customer LIKE "Atliq Exclusive"
		AND region LIKE "apac"
		ORDER BY market ASC;
 ------------------------------------------------------------------------------------------------------------      
 
# Request 02
# What is the percentage of unique product increase in 2021 vs. 2020? 
#(The final output contains these fields, unique_products_2020, unique_products_2021 percentage_chg)

	WITH product_count_20 AS 
	(SELECT COUNT(DISTINCT(p.product_code)) AS unique_product_2020 
    FROM dim_product p
	JOIN fact_sales_monthly s
		ON p.product_code = s.product_code 
		WHERE fiscal_year = 2020),
    
product_count_21 AS 
	(SELECT COUNT(DISTINCT(p.product_code)) AS unique_product_2021 
    FROM dim_product p
	JOIN fact_sales_monthly s
		ON p.product_code = s.product_code 
		WHERE fiscal_year = 2021)
    
SELECT  p20.unique_product_2020 , 
		p21.unique_product_2021  ,
		ROUND((p21.unique_product_2021-p20.unique_product_2020)/p20.unique_product_2020*100,2) pct_chg
        FROM product_count_20 p20
			CROSS JOIN product_count_21 p21;
------------------------------------------------------------------------------------------------------------       

# Request 03
# Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
#(The final output contains 2 fields, segment, product_count)

	SELECT 
		segment,
		COUNT(DISTINCT(product_code)) AS product_count
		FROM gdb023.dim_product
		GROUP BY segment
		ORDER BY product_count DESC;

------------------------------------------------------------------------------------------------------------       

# Request 04
# Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
#(The final output contains these fields, segment, product_count_2020, product_count_2021, difference)


WITH pct_2020 AS 
	(SELECT segment, 
			COUNT(DISTINCT(p.product_code)) AS product_count_2020
			FROM dim_product p
			JOIN fact_sales_monthly s
				ON p.product_code = s.product_code 
				WHERE fiscal_year = 2020
				GROUP BY segment),
    
pct_2021 AS 
	(SELECT segment, 
			COUNT(DISTINCT(p.product_code)) AS product_count_2021
			FROM dim_product p
			JOIN fact_sales_monthly s
				ON p.product_code = s.product_code 
				WHERE fiscal_year = 2021
				GROUP BY segment)
    
    SELECT p20.segment,
    p20.product_count_2020,
    p21.product_count_2021,
    (p21.product_count_2021-p20.product_count_2020) AS difference
    FROM pct_2020 AS p20
    JOIN pct_2021 AS p21
		ON p20.segment=p21.segment;
        
        
-------------------------------------------------------------------------------------------------------------

# Request 05
# Get the products that have the highest and lowest manufacturing costs 
#(The final output should contain these fields, product_code, product manufacturing_cost)

SELECT 
    m.product_code,
    p.product,
    p.segment , 
    m.manufacturing_cost
		FROM gdb023.fact_manufacturing_cost m
		JOIN dim_product p 
			ON p.product_code=m.product_code
    WHERE manufacturing_cost IN 
			(SELECT MAX(manufacturing_cost)
				FROM gdb023.fact_manufacturing_cost m
		UNION
			SELECT MIN(manufacturing_cost)
				FROM gdb023.fact_manufacturing_cost m )
					ORDER BY manufacturing_cost DESC;
                    
                    
-------------------------------------------------------------------------------------------------------------

# Request 06
# Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market, 
#(The final output contains these fields, customer_code, customer average_discount_percentage)

SELECT  
		d.customer_code,
		c.customer,
        ROUND(AVG(pre_invoice_discount_pct),2)*100 AS average_discount_percentage 
        FROM gdb023.fact_pre_invoice_deductions d
        JOIN dim_customer c 
			ON c.customer_code=d.customer_code
			WHERE fiscal_year=2021 AND market = "India"
			GROUP BY d.customer_code
			ORDER BY average_discount_percentage DESC
			LIMIT 5;
            
 -------------------------------------------------------------------------------------------------------------           
            
# Request 07
# Get the complete report of the Gross sales amount for the customer “AtliQ Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions
#(The final report contains these columns: Month, Year, Gross sales Amount)

SELECT 
	MONTH(s.date) AS month_num,
	LEFT(MONTHNAME(s.date),3) AS month,
	YEAR(s.date) AS year,
	ROUND(SUM(g.gross_price*s.sold_quantity)/1000000 ,2)AS gross_sales_amount_mln
	FROM gdb023.fact_sales_monthly s
	JOIN fact_gross_price g 
		ON s.product_code =g.product_code
	JOIN dim_customer c
		ON s.customer_code = c.customer_code 
			WHERE c.customer = "AtliQ Exclusive"
				GROUP BY s.date 
				ORDER BY s.date; 

 -------------------------------------------------------------------------------------------------------------  

# Request 08
# In which quarter of 2020, got the maximum total_sold_quantity 
#(The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity )

SELECT 
		QUARTER(DATE_ADD(s.date, INTERVAL 4 MONTH)) quarter,
        ROUND(SUM(s.sold_quantity)/1000000,2) total_sold_quantity
        FROM fact_sales_monthly s
        WHERE fiscal_year=2020
        GROUP BY quarter , fiscal_year
        ORDER BY fiscal_year ASC , quarter ASC;
        
        
 -------------------------------------------------------------------------------------------------------------  
 
# Request 09
# Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
# (The final output contains these fields, channel, gross_sales_mln, percentage)

WITH 
	channel_sales_2021 AS (SELECT 
			c.channel,
				ROUND(SUM(g.gross_price*s.sold_quantity)/1000000,2) gross_sales_mln
				FROM gdb023.fact_sales_monthly s
				JOIN fact_gross_price g
					ON s.product_code=g.product_code
				JOIN dim_customer c
					ON s.customer_code = c.customer_code
				WHERE s.fiscal_year=2021
				GROUP BY c.channel
				ORDER BY gross_sales_mln DESC )
    
				SELECT * ,
					ROUND(gross_sales_mln*100/ ( SELECT SUM(gross_sales_mln) FROM channel_sales_2021),2) percentage 
					FROM channel_sales_2021;
                    
                    
 -------------------------------------------------------------------------------------------------------------  
 
# Request 10
# Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021 
# (The final output contains these fields, division, product_code, product, total_sold_quantity, rank_order)

WITH 
	prod_sales_2021 AS (SELECT 
		p.division,
		s.product_code,
		p.product,
		SUM(s.sold_quantity) total_sold_quantity
		FROM gdb023.fact_sales_monthly s
		JOIN dim_product p
			ON s.product_code = p.product_code
			WHERE s.fiscal_year =2021
			GROUP BY s.product_code),
    
ranked_products AS (SELECT *,
		DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
		FROM prod_sales_2021)
    
		SELECT * FROM ranked_products
			WHERE rank_order BETWEEN 1 AND 3;
		

 ------------------------------------------------------------------------------------------------------------- 
 

