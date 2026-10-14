use ecom;
select * from customers;
select * from products;
select * from sales;  

	#KPI's
# 1.Total Revenue in Millions
SELECT ROUND(SUM(s.Quantity * p.Selling_Price) / 1000000) as Total_Revenue
FROM sales s
JOIN products p on s.Product_ID = p.Product_ID;

# 2. Average Order Value (AOV)
SELECT ROUND(AVG(s.Quantity * p.Selling_Price)) AS Average_Order_Value
FROM sales s
JOIN products p on s.Product_ID = p.Product_ID;

# 3. Fulfilment _Rate
SELECT ROUND((SUM(Order_Status="Delivered") * 100.0) / COUNT(*),2) AS Fulfilment_Rate
FROM sales;

# 4. Average Processing Time (Days)
SELECT ROUND(AVG(DATEDIFF(Delivery_Date, Order_Date)), 1) AS Avg_Days_To_Ship
FROM sales
WHERE Delivery_Date IS NOT NULL AND Order_Date IS NOT NULL;

# 5. Retension Rate % 
SELECT  COUNT(*) AS Total_Customers,
SUM(order_count > 1) AS Repeat_Customers,
ROUND((SUM(order_count > 1) * 100.0) / COUNT(*), 2) AS 'Retension_Rate%'
FROM (SELECT Customer_ID, COUNT(Order_ID) AS order_count
FROM sales
GROUP BY Customer_ID) customer_orders;

# Customer Segmentation & RFM Analysis

# 6. Who are our highest-spending customers based on total monetary value and order frequency?
SELECT s.Customer_ID,c.Customer_name,
COUNT(s.Order_ID) AS Total_Orders,
ROUND(SUM(s.Quantity * p.Selling_Price)) AS Total_Monetary_Spent
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY s.Customer_ID,c.Customer_Name
ORDER BY Total_Monetary_Spent DESC
LIMIT 10;

# 7. Which states or cities yield the highest average customer spend and highest concentration of active buyers?
SELECT c.State,
COUNT(DISTINCT c.Customer_ID) AS Total_Customers,
COUNT(s.Order_ID) AS Total_Orders,
ROUND(SUM(s.Quantity * p.Selling_Price), 2) AS Total_State_Revenue,
ROUND(SUM(s.Quantity * p.Selling_Price) / COUNT(DISTINCT c.Customer_ID), 2) AS Avg_Revenue_Per_Customer
FROM sales s
JOIN customers c ON s.Customer_ID = c.Customer_ID
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY c.State
ORDER BY Total_State_Revenue DESC;

# 8. What is the total revenue distribution and customer count across different spending tiers (Low, Mid, VIP)	?
SELECT Spending_Tier,
COUNT(Customer_ID) AS Customer_Count,
ROUND(SUM(Total_Spent), 2) AS Tier_Total_Revenue
FROM (SELECT s.Customer_ID,
SUM(s.Quantity * p.Selling_Price) AS Total_Spent,
IF( SUM(s.Quantity * p.Selling_Price) > 50000, 
'VIP (High Spender)',
IF(
SUM(s.Quantity * p.Selling_Price) >= 20000, 
'Mid Spender',
'Low Spender')) AS Spending_Tier
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY s.Customer_ID) customer_tiers
GROUP BY Spending_Tier
ORDER BY Tier_Total_Revenue DESC; 

# Product & Category Performance.

# 9. What is the total unit volume and total revenue generated across each product category?
SELECT p.Category,
SUM(s.Quantity) AS Total_Units_Sold,
ROUND(SUM(s.Quantity * p.Selling_Price), 2) AS Total_Category_Revenue
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY Total_Category_Revenue DESC;

# 10. What are the top 5 best-selling individual products?
SELECT p.Product_ID,p.Product_Name,p.Category,
SUM(s.Quantity) AS Total_Units_Sold,
ROUND(SUM(s.Quantity * p.Selling_Price), 2) AS Total_Product_Revenue
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY Total_Units_Sold DESC
LIMIT 5;

# 11. What is the distribution of product performance tiers? 
SELECT Performance_Tier,
COUNT(Product_ID) AS Product_Count,
ROUND(SUM(Total_Revenue), 2) AS Tier_Revenue
FROM (SELECT p.Product_ID,
SUM(s.Quantity * p.Selling_Price) AS Total_Revenue,
IF(SUM(s.Quantity * p.Selling_Price) > 50000, 
'Top Performer',
IF(
SUM(s.Quantity * p.Selling_Price) >= 20000, 
'Moderate Performer', 
'Underperformer')) AS Performance_Tier
FROM products p
LEFT JOIN sales s ON p.Product_ID = s.Product_ID
GROUP BY p.Product_ID) product_performance
GROUP BY Performance_Tier
ORDER BY Tier_Revenue DESC;

# Promotion & Discount Impact Analysis.

# 12. What is the average quantity sold and total order count broken down by discount percentage?
SELECT Discount_Bracket,
COUNT(Order_ID) AS Total_Orders,
SUM(Quantity) AS Total_Units_Sold,
ROUND(AVG(Quantity), 2) AS Avg_Units_Per_Order
FROM (SELECT s.Order_ID,s.Quantity,
IF(p.Discount_Percent >= 50, 'High Discount (50%+)',
IF(p.Discount_Percent >= 30, 'Moderate Discount (30-49%)', 
'Low / No Discount (<30%)')) AS Discount_Bracket
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID) discount_analysis
GROUP BY Discount_Bracket
ORDER BY Total_Units_Sold DESC;

# 13. What is the aggregate gross sales value versus total monetary discounts given away across all product sales?
SELECT COUNT(s.Order_ID) AS Total_Transactions,
ROUND(SUM(s.Quantity * p.Selling_Price), 2) AS Total_Gross_Revenue,
ROUND(SUM(s.Quantity * p.Selling_Price * (p.Discount_Percent / 100.0)), 2) AS Total_Discount_Amount_Given,
ROUND(SUM((s.Quantity * p.Selling_Price) * (1 - (p.Discount_Percent / 100.0))), 2) AS Total_Net_Revenue
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID;

# 14. Which product categories have the highest average discount percentage and total monetary discount value?
SELECT p.Category,
COUNT(s.Order_ID) AS Total_Items_Sold,
ROUND(AVG(p.Discount_Percent), 2) AS Avg_Discount_Percentage,
ROUND(SUM(s.Quantity * p.Selling_Price * (p.Discount_Percent / 100.0)), 2) AS Total_Category_Discounts
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY Total_Category_Discounts DESC;

# 15. What proportion of our orders are Single-Item purchases vs. Small/Large multi-item baskets, and how much revenue do they contribute?
SELECT Basket_Size_Category,
COUNT(Order_ID) AS Total_Orders,
SUM(Total_Items) AS Total_Units_Sold,
ROUND(SUM(Order_Revenue), 2) AS Gross_Revenue,
ROUND(AVG(Order_Revenue), 2) AS Avg_Order_Value
FROM (SELECT s.Order_ID,SUM(s.Quantity) AS Total_Items,SUM(s.Quantity * p.Selling_Price) AS Order_Revenue,
IF(SUM(s.Quantity) >= 5, 'Bulk / Large Basket (5+ items)',
IF(SUM(s.Quantity) >= 2, 'Multi-Item Basket (2-4 items)', 
'Single Item Basket (1 item)')) AS Basket_Size_Category
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY s.Order_ID) order_baskets
GROUP BY Basket_Size_Category
ORDER BY Gross_Revenue DESC;
