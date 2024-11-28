-- Creating Dataset ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE SCHEMA DannysDiner;

CREATE TABLE sales 
(
  customer_id VARCHAR(20),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- Case Study ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select * from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
where join_date > order_date
order by order_date;

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(price) from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select s.customer_id,count(order_date) from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
group by s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with first_order as
(
select m.customer_id, product_name,
row_number () over(partition by m.customer_id order by order_date) row_num
from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
) 
select * from first_order
where row_num = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, count(s.product_id) num_purchase from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
group by product_name
limit 1;

-- 5. Which item was the most popular for each customer?
select s.customer_id, product_name, count(s.product_id) num_purchase from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
group by product_name, s.customer_id
order by 3 desc;

-- 6. Which item was purchased first by the customer after they became a member?
with cte as
(
select m.customer_id, mn.product_name, s.order_date,
rank() over (partition by customer_id order by order_date) rnk
from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
where order_date>=join_date
)
select * from cte
where rnk = 1;

-- Q7:Which item was purchased just before the customer became a member?
with cte as
(
select m.customer_id, mn.product_name, s.order_date,
rank() over (partition by customer_id order by order_date) rnk
from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
where order_date<join_date
)
select * from cte
where rnk = 1;

-- Q8:What is the total items and amount spent for each member before they became a member?
select s.customer_id, sum(price)
from members m
join sales s on m.customer_id = s.customer_id
join menu mn on mn.product_id = s.product_id
where order_date<join_date
group by s.customer_id
order by customer_id;

-- Q9:If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select x.customer_id, sum(x.points)
from 
( select s.customer_id, 
	case 
	when product_name = 'sushi' then 20*price
    else 10*price
    end as points
from members m
join sales s on m.customer_id = s.customer_id
join menu mn on s.product_id = mn.product_id
) x
group by x.customer_id
order by x.customer_id;

-- Q10:In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
    x.customer_id, 
    x.month_name, 
    SUM(points) AS total_points
FROM 
    (
        SELECT 
            s.customer_id, 
            MONTHNAME(s.order_date) AS month_name,
            CASE
                WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 6 MONTH) 
                THEN 20 * m.price
                ELSE 10 * m.price
            END AS points
        FROM 
            sales s
        JOIN 
            menu m 
            ON s.product_id = m.product_id
        JOIN 
            members mb 
            ON s.customer_id = mb.customer_id
    ) AS x
WHERE 
    x.month_name = 'January'
GROUP BY 
    x.customer_id, 
    x.month_name
ORDER BY x.customer_id;