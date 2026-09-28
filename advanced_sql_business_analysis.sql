USE e_commerce_analytics;

-- 21. The management wants to identify high-value customers who are generating more revenue than the typical customer.
-- Task
-- Find all customers whose total spending is greater than the average total spending of all customers.
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
)
SELECT *FROM spending
WHERE total_spending>(SELECT AVG(total_spending)
FROM spending)
ORDER BY total_spending DESC;

-- 22.Business Problem:
-- Management wants to identify products that generate above-average revenue within their own category.
-- Task : Find all products whose total revenue is greater than the average product revenue of their category.

WITH revenue AS(
	SELECT p.category,p.product_id,p.product_name,
    ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_revenue
	FROM products p
    JOIN order_items oi
    ON p.product_id=oi.product_id
    GROUP BY p.product_id,p.product_name,p.category
    ),avg_revenue AS(
    SELECT *,
    AVG(total_revenue) OVER(
		PARTITION BY category
        )AS category_avg_revenue
         FROM revenue
	) SELECT * FROM avg_revenue
    WHERE total_revenue>category_avg_revenue;

-- 23. Business Problem: The business team wants to identify repeat customers who are generating high revenue.
-- Task: Find customers who: Have placed at least 3 orders , Have total spending greater than ₹50,000
WITH spending AS(
	SELECT c.customer_id,c.name,COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_spending
	FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    GROUP BY c.customer_id,c.name
    )
    SELECT * FROM spending
    WHERE total_orders>=3 AND 
    total_spending>50000;

-- 24. Business Problem: Find all customers who have never purchased any product from the Electronics category.
SELECT c.customer_id,c.name
FROM customers c
WHERE NOT EXISTS(SELECT 1
	FROM products p2
    JOIN order_items oi
    ON p2.product_id=oi.product_id
	JOIN orders o
    ON o.order_id=oi.order_id
    WHERE p2.category='Electronics' 
    AND  o.customer_id=c.customer_id);
    
-- 25. Business Problem: Find the top 3 customers in each customer segment based on total spending.
WITH spending AS(
	SELECT c.customer_id,c.name,c.customer_segment,
    ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_spending
	FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    GROUP BY c.customer_id,c.name,c.customer_segment
),segment AS(
	SELECT *,
		RANK() OVER(
			PARTITION BY customer_segment
            ORDER BY total_spending DESC
            ) top_customers
		FROM spending
	)SELECT *FROM segment
    WHERE top_customers <=3;
    
-- 26. Business Problem: Identify customers who have purchased products from at least 3 different categories.
WITH spending AS(
	SELECT c.customer_id,c.name,COUNT(DISTINCT p.category) AS category_count,
    ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_spending
	FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    JOIN products p 
    ON oi.product_id=p.product_id
    GROUP BY c.customer_id,c.name
    ) SELECT * FROM spending
    WHERE category_count>=3
    ORDER BY category_count DESC,total_spending DESC;
    
-- 27. Business Problem: Find the customers who have placed orders in more than one sales channel.
SELECT c.customer_id,c.name,COUNT(DISTINCT o.order_id) AS total_orders,
COUNT(DISTINCT o.sales_channel) AS channel_count
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
GROUP BY c.customer_id,c.name
HAVING channel_count>1
ORDER BY channel_count DESC;

-- 28. Find customers whose average order value (AOV) is higher than the overall average order value of all customers.
WITH spending AS(
	SELECT c.customer_id,c.name,COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_spending
	FROM customers c
    JOIN orders o
    ON c.customer_id=o.customer_id
    JOIN order_items oi
    ON o.order_id=oi.order_id
    GROUP BY c.customer_id,c.name
    ), AOV AS(
    SELECT *,
    ROUND(total_spending/total_orders,2) AS average_order_value
    FROM spending
    ), over_aov AS(
    SELECT *,
    AVG(average_order_value) OVER() AS overall_aov 
    FROM AOV
    )SELECT *FROM over_aov
    WHERE average_order_value>overall_aov 
    ORDER BY  average_order_value DESC;
	
-- 29.Find customers who have purchased every product category available in the database.
WITH ctg_count AS(
	SELECT c.customer_id,c.name,
	COUNT(DISTINCT p.category) AS category_count
	FROM customers c
	JOIN orders o
	ON o.customer_id=c.customer_id
	JOIN order_items oi
	ON o.order_id=oi.order_id
	JOIN products p
	ON p.product_id=oi.product_id
	GROUP BY c.customer_id,c.name
    )SELECT *FROM ctg_count 
    WHERE category_count=(SELECT 
    COUNT(DISTINCT category) FROM products)
    ORDER BY customer_id;
    
-- 30. Find the product category with the highest revenue in each sales channel.
WITH revenue AS(
	SELECT o.sales_channel,p.category,
    ROUND(
		SUM(oi.quantity*oi.unit_price*(1-oi.discount/100)),
        2) AS total_revenue
	FROM products p
    JOIN order_items oi
    ON p.product_id=oi.product_id
    JOIN orders o 
    ON oi.order_id=o.order_id
    GROUP BY p.category,o.sales_channel
    ),highest AS(
		SELECT *,
        RANK() OVER(
			PARTITION BY sales_channel
            ORDER BY total_revenue DESC
            ) AS rank_in_channel
		FROM revenue
	)SELECT *FROM highest
    WHERE rank_in_channel =1;
	