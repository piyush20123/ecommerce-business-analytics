USE e_commerce_analytics;

-- Executive Business KPIs

-- 1. Find the total number of orders in the company.
SELECT COUNT(*) FROM orders;

-- 2. Calculate the total revenue from all order items.
SELECT order_item_id,
    quantity,
    unit_price,
    discount,
    ROUND(quantity * unit_price * (1 - discount / 100), 2) AS total_revenue
FROM order_items;

-- 3. Calculate the total number of units sold across all order items.
SELECT SUM(quantity) AS total_units_sold
FROM order_items;

-- 4. Calculate the average value of an order.
WITH order_value AS(
	SELECT SUM(quantity*unit_price*(1-discount/100)) AS sum_value
	FROM order_items
    GROUP BY order_id
    )
    SELECT ROUND(AVG(sum_value),2) AS avg_value
    FROM order_value;
    
-- 5. Calculate the total number of delivered orders.
SELECT SUM(CASE WHEN order_status='Delivered' THEN 1 ELSE 0 END) AS delivered_orders
FROM orders;

-- 6. Now calculate the total number of cancelled orders.
SELECT SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders
FROM orders;

-- 7. Calculate the total number of customers in the database.
SELECT COUNT(*) AS total_customers FROM customers;

-- 8. Calculate the total number of products in our database.
SELECT COUNT(*) AS total_products FROM products;

-- 9. Now let's calculate the actual total company revenue from all order items.
SELECT ROUND(SUM(quantity*unit_price*(1-discount/100)),2) AS total_revenue FROM order_items;

-- 10. Calculate the percentage of orders that were delivered.
WITH order_info AS(
	SELECT SUM(CASE WHEN order_status='Delivered' THEN 1 ELSE 0 END)AS delivered_orders,
	COUNT(*) AS total_orders
    FROM orders
    )
    SELECT ROUND((delivered_orders/total_orders)*100,2) AS delivery_percentage
FROM order_info;

