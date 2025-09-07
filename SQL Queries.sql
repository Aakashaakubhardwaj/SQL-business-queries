-- create database inlign; -- creation of database
-- use inlign;

-- Easy Level Queries:
 
-- Q1: Find the most senior employee based on job title.
select * from employee order by levels desc ;

-- Q2: Determine which countries have the most invoices.
select billing_country,count(billing_country)  from invoice group by billing_country ;

-- Q3: Identify the top 3 invoice totals.
select invoice_id,customer_id,total from invoice order by total desc limit 3;  ;

-- Q4: Find the city with the highest total invoice amount to determine the best location for a promotional event.
SELECT c.city,sum(i.total) as total_invoice_amount from customer c
join invoice i on c.customer_id = i.customer_id
group by c.city order by total_invoice_amount desc limit 1;

-- Q5: Identify the customer who has spent the most money.
select c.customer_id,c.first_name,c.last_name,sum(i.total) as total_spent from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, c.first_name, c.last_name order by total_spent desc limit 1;

-- Moderate Level Queries:

-- Q1: Find the email, first name, and last name of customers who listen to Rock music.
select c.email,c.first_name,c.last_name from customer c join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where g.name = 'Rock';

-- Q2: Identify the top 10 rock artists based on track count.
select a.name ,count(t.track_id) as rock_track_count from artist a join album2 al on a.artist_id = al.artist_id 
join track t on t.album_id = al.album_id 
join genre g on g.genre_id = t.genre_id 
where g.name = 'Rock' group by a.artist_id, a.name 
order by rock_track_count desc limit 10;

-- Q3: Find all track names that are longer than the average track length.
select t.name ,t.milliseconds from track t where t.milliseconds > (select avg(t.milliseconds) from track t);

--  Advanced Level Queries:

-- Q1: Calculate how much each customer has spent on each artist.
with artist_sales as 
(select ar.artist_id,
        ar.name as artist_name,
        il.invoice_id,
        il.unit_price * il.quantity as amount
    from invoice_line il
    join track t on il.track_id = t.track_id
    join album2 al on t.album_id = al.album_id
    join artist ar on al.artist_id = ar.artist_id) 
                                        -- This query calculates the total amount earned per invoice line for each artist.
select c.customer_id,
       c.first_name,
       c.last_name,
       asales.artist_name,
       sum(asales.amount) as total_spent
from artist_sales asales
join invoice i on asales.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id     -- main query joins the customer table with invoice tables.
group by c.customer_id, c.first_name, c.last_name, asales.artist_name  -- Groups by customer and artist to get the right totals.
order by c.customer_id, total_spent desc;     -- Organizes the results by customer and amount spent (highest first)

-- Q2: Determine the most popular music genre for each country based on purchases.
with genre_purchases as (
    select c.country,g.name as genre_name,count(il.invoice_line_id) as purchase_count
    from customer c
    join invoice i on c.customer_id = i.customer_id
    join invoice_line il on i.invoice_id = il.invoice_id
    join track t on il.track_id = t.track_id
    join genre g on t.genre_id = g.genre_id
    group by c.country, g.genre_id, g.name),     -- genre_purchases: Aggregates purchase counts per genre per country.
ranked_genres as 
( select *,row_number() over (partition by country order by purchase_count desc) as row_num from genre_purchases)
                                                 -- ROW_NUMBER(): Ranks genres by number of purchases within each country.
select country,genre_name,purchase_count
from ranked_genres
where row_num = 1
order by country;                                -- Final SELECT: Filters to show only the #1 genre per country.

-- Q3: Identify the top-spending customer for each country.
with customer_spending as (
    select c.customer_id,c.first_name,c.last_name,c.country,sum(i.total) as total_spent from customer c
    join invoice i on c.customer_id = i.customer_id
    group by c.customer_id, c.first_name, c.last_name, c.country),
									-- customer_spending CTE: Computes total amount spent by each customer, along with their country.
ranked_customers as 
( select *,row_number() over (partition by country order by total_spent desc) as row_num
    from customer_spending)         
									-- ranked_customers CTE: Assigns a rank to each customer within their country based on total spent.    
select customer_id,first_name,last_name,country,total_spent from ranked_customers
where row_num = 1 order by country;
									-- Final SELECT: Filters to include only the top-ranked customer (rank = 1) for each country.



