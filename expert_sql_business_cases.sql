-- expert_sql_business_cases
USE e_commerce_analytics;

-- 31. Business Problem: For each customer, calculate their total spending and compare it with 
-- the previous customer's spending when customers are ordered by total spending descending.
WITH spending AS(
	SELECT c.customer_id,c.name,
    ROUND( 
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_spending
	FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    GROUP BY c.customer_id,c.name
),previous_spending AS(
	SELECT *,
	LAG(total_spending) OVER(
		ORDER BY total_spending DESC
        ) AS previous_customer_spending
	FROM spending
) SELECT *,
(total_spending-previous_customer_spending)AS spending_diff
FROM previous_spending
ORDER BY total_spending DESC;

-- 32. Business Problem: For each product, identify its revenue rank within its category.
WITH revenue AS(
	SELECT p.product_id,p.product_name,p.category,
    ROUND( 
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_revenue
	FROM products p
    JOIN order_items oi
    ON p.product_id=oi.product_id
    GROUP BY p.product_id,p.product_name,p.category
),cat_rank AS(
	SELECT *,
    RANK() OVER(
		PARTITION BY category
        ORDER BY total_revenue DESC
        ) AS category_rank
	FROM revenue
)SELECT *FROM cat_rank;

-- 33. Business Problem: For each customer, find their first order date and most recent order date, 
-- along with the number of days between them.
WITH order_info AS(
	SELECT c.customer_id,c.name,o.order_date,COUNT(o.order_id) OVER(
    PARTITION BY c.customer_id) AS order_count,
    MIN(o.order_date) OVER(
		PARTITION BY c.customer_id 
        )AS first_order_date,
    MAX(o.order_date) OVER(
		PARTITION BY c.customer_id
        )AS last_order_date
    FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
)SELECT customer_id,name,
first_order_date,last_order_date,
DATEDIFF(last_order_date,first_order_date) AS days_between_orders
FROM order_info
WHERE order_count>=2;

-- 34. Business Problem: For each customer, calculate their running total of spending over time.
WITH spending AS(
	SELECT c.customer_id,c.name,o.order_date,o.order_id,
    SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)) AS total_spending
    FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    GROUP BY c.customer_id,c.name,o.order_date,o.order_id
)SELECT customer_id,name,order_date,
SUM(total_spending) OVER(
	PARTITION BY customer_id
	ORDER BY order_date ,order_id
    )AS running_total_spending
    FROM spending;
    
-- 35. For each customer, identify their highest-value order.
WITH spending AS(
	SELECT c.customer_id,c.name,o.order_date,o.order_id,
    SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)) AS total_spending
    FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    GROUP BY c.customer_id,c.name,o.order_date,o.order_id
),hvg AS(
	SELECT *,
    RANK() OVER(
    PARTITION BY customer_id
    ORDER BY total_spending DESC
    ) highest_value_order
FROM spending
)SELECT *FROM hvg
WHERE highest_value_order=1;


-- Customer & Product Analytics

-- 36. Business Problem: Find customers whose total spending on a single product is greater 
-- than the average spending on that product across all customers.
WITH spending AS(
	SELECT c.customer_id,c.name,p.product_id,p.product_name,
    SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)) AS customer_product_spending
    FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    JOIN products p
    ON oi.product_id=p.product_id
    GROUP BY c.customer_id,c.name,p.product_id,p.product_name
), avg_spending AS(
	SELECT *,
    AVG(customer_product_spending) OVER(
		PARTITION BY product_id
        ) AS average_product_spending
	FROM spending
)SELECT *FROM avg_spending
WHERE customer_product_spending>average_product_spending;

-- 37. Business Problem: Find the top 3 products by total revenue for each customer segment.
WITH spending AS(
	SELECT c.customer_segment,p.product_id,p.product_name,
    SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)) AS customer_total_revenue
    FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    JOIN products p
    ON oi.product_id=p.product_id
    GROUP BY c.customer_segment,p.product_id,p.product_name
), customer_segment AS(
	SELECT *,
	RANK() OVER(
		PARTITION BY customer_segment
        ORDER BY customer_total_revenue DESC
        ) AS product_rank
	FROM spending
)SELECT *FROM customer_segment
WHERE product_rank <=3;

-- 38. Business Problem: Identify customers who have purchased the same product more than once across different orders.
SELECT c.customer_id,c.name,p.product_id,p.product_name,
COUNT(DISTINCT o.order_id) AS total_products,
SUM(oi.quantity) AS total_quantity
FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    JOIN products p
    ON oi.product_id=p.product_id
    GROUP BY c.customer_id,c.name,p.product_id,p.product_name
    HAVING COUNT(DISTINCT o.order_id)>=2;
    
-- 39. Business Problem: Find the most frequently purchased product for each customer segment, based on total quantity sold.
WITH quantity AS(
	SELECT c.customer_segment,p.product_id,p.product_name,
	SUM(oi.quantity) AS total_quantity
	FROM customers c
		JOIN orders o
		ON c.customer_id=o.customer_id
		JOIN order_items oi
		ON o.order_id=oi.order_id
		JOIN products p
		ON oi.product_id=p.product_id
		GROUP BY c.customer_segment,p.product_id,p.product_name
),product_frequency AS(
	SELECT *,
    RANK() OVER(
		PARTITION BY customer_segment
        ORDER BY total_quantity DESC
	) AS most_frequent_product
FROM quantity
)SELECT *FROM product_frequency
WHERE most_frequent_product=1;

-- 40. Business Problem: Find products that have both:
-- 1)Total revenue above the average product revenue, and
-- 2)An average customer rating of at least 4.
WITH revenue AS (
    SELECT p.product_id,p.product_name,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount / 100)
        ) AS total_revenue
    FROM products p
    JOIN order_items oi
	ON p.product_id = oi.product_id
    GROUP BY p.product_id,p.product_name
),ratings AS (
    SELECT product_id,
	AVG(rating) AS average_rating
    FROM reviews
    GROUP BY product_id
),product_metrics AS (
    SELECT r.product_id,r.product_name,
	r.total_revenue,
	rt.average_rating
    FROM revenue r
    JOIN ratings rt
	ON r.product_id = rt.product_id
),final_metrics AS (
SELECT *,
	AVG(total_revenue) OVER () AS average_product_revenue
    FROM product_metrics
)SELECT product_id, product_name,
ROUND(total_revenue, 2) AS total_revenue,
ROUND(average_rating, 2) AS average_rating
FROM final_metrics
WHERE average_rating >= 4
AND total_revenue > average_product_revenue
ORDER BY total_revenue DESC;

USE e_commerce_analytics;

-- 41. Calculate monthly total revenue and the month-over-month (MoM) revenue growth percentage.
WITH monthly_revenue AS(
	SELECT YEAR(o.order_date)AS year,MONTH(o.order_date) AS month_number,
	MONTHNAME(o.order_date) AS month_name,
	ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
		2) AS monthly_revenue
	FROM orders o
	JOIN order_items oi
	ON o.order_id=oi.order_id
	GROUP BY MONTH(o.order_date),MONTHNAME(o.order_date),YEAR(o.order_date)
),previous_revenue AS(
	SELECT *,
    LAG(monthly_revenue) OVER(
    ORDER BY year,month_number
    ) AS previous_month_revenue
    FROM monthly_revenue
)SELECT *,
	ROUND(((monthly_revenue-previous_month_revenue)/previous_month_revenue)*100 ,2)AS MoM_growth_percentage
    FROM previous_revenue
    ORDER BY year,month_number;
    
-- 42. Using orders and order_items, calculate monthly revenue for each sales channel and the MoM revenue growth percentage within each sales channel.
WITH revenue AS(
	SELECT o.sales_channel,MONTH(o.order_date) AS month_number,
    MONTHNAME(o.order_date) AS month_name,
    YEAR(o.order_date) AS year,
	ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),2) AS monthly_revenue
	FROM orders o
	JOIN order_items oi
	ON o.order_id=oi.order_id
	GROUP BY o.sales_channel,MONTH(o.order_date),MONTHNAME(o.order_date),YEAR(o.order_date)
), previous_revenue AS(
	SELECT *,
    LAG(monthly_revenue) OVER(
		PARTITION BY sales_channel
        ORDER BY year,month_number)AS previous_month_revenue
	FROM revenue
    )SELECT *,
    ROUND(((monthly_revenue-previous_month_revenue)/previous_month_revenue)*100 ,2)AS MoM_growth_percentage 
    FROM previous_revenue
    ORDER BY year,month_number;
    


		