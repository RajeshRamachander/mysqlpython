USE sakila;

SHOW tables;

-- Which genres are most promising to invest based on current revenue?
 /* 
	1. Sports
	2. Sci-Fi
    3. Animation
    4. Drama
*/

WITH CTE
AS
(
SELECT 
	c.name AS category_name,
    COUNT(r.rental_id) AS rental_count,
    SUM(p.amount) AS earnings
FROM
	film AS f
    LEFT OUTER JOIN film_category AS fc ON f.film_id = fc.film_id
    LEFT OUTER JOIN category AS c ON fc.category_id = c.category_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
    LEFT OUTER JOIN payment AS p ON r.rental_id = p.rental_id
GROUP BY
	c.name
)
SELECT
	category_name,
    earnings,
    NTILE(4) OVER(ORDER BY earnings DESC) AS bucket
FROM
	CTE;

-- Classify actors into buckets of most rented (demand)?

WITH CTE
AS
(
SELECT 
	CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
    COUNT(r.rental_id) AS rental_count
FROM
	actor AS a
    LEFT OUTER JOIN film_actor AS fa ON a.actor_id = fa.film_id
    LEFT OUTER JOIN film AS f ON fa.film_id = f.film_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
GROUP BY
	CONCAT(a.first_name, ' ', a.last_name)
)
SELECT
	actor_name,
    rental_count,
    NTILE(5) OVER(ORDER BY rental_count DESC) AS bucket
FROM
	CTE;

-- Which actors are most promising to invest based on current earnings?
/*
Most promising Actor List - Top list and their earnings in terms of rental amount
'GROUCHO WILLIAMS','1230.75','1'
'RUSSELL BACALL','1134.32','1'
'FRANCES DAY-LEWIS','1111.67','1'
*/

WITH CTE
AS
(
SELECT 
	CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
    SUM(p.amount) AS earnings
FROM
	actor AS a
    LEFT OUTER JOIN film_actor AS fa ON a.actor_id = fa.film_id
    LEFT OUTER JOIN film AS f ON fa.film_id = f.film_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
    LEFT OUTER JOIN payment AS p ON r.rental_id = p.rental_id
GROUP BY
	CONCAT(a.first_name, ' ', a.last_name)
)
SELECT
	actor_name,
    earnings,
    NTILE(5) OVER(ORDER BY earnings DESC) AS bucket
FROM
	CTE;

-- Bucket list of movies based on ratings and best earnings?

WITH CTE
AS
(
SELECT
	f.rating,
	f.title AS film_name,
    SUM(p.amount) AS earnings
FROM
	actor AS a
    LEFT OUTER JOIN film_actor AS fa ON a.actor_id = fa.film_id
    LEFT OUTER JOIN film AS f ON fa.film_id = f.film_id
    LEFT OUTER JOIN inventory AS i ON f.film_id = i.film_id
    LEFT OUTER JOIN rental AS r ON i.inventory_id = r.inventory_id
    LEFT OUTER JOIN payment AS p ON r.rental_id = p.rental_id
GROUP BY
	f.rating,
	f.title
)
SELECT
	rating,
    film_name,
    earnings,
    NTILE(5) OVER(PARTITION BY rating ORDER BY earnings DESC) AS bucket
FROM
	CTE;



-- What is the proportion of customers that generally hold more than 1 rental at a time (generally rents a second title before the end of rental of the first)?      
    
WITH rental_enriched
AS
(
SELECT
	r.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    ROUND((TIMESTAMPDIFF(HOUR, (LAG (r.rental_date) OVER (PARTITION BY r.customer_id ORDER BY r.rental_date)), 
r.rental_date))/24, 2) AS days_between_rentals,
    ROUND((TIMESTAMPDIFF(HOUR, r.rental_date, r.return_date))/24, 2) AS rental_period
 
FROM
	rental r
    INNER JOIN customer c ON r.customer_id = c.customer_id
),
rental_summary AS
(
SELECT
	customer_id,
    customer_name,
    email,
    AVG(days_between_rentals) AS avg_days_between_rentals,
    AVG(rental_period) AS avg_days_rental_period,
    COUNT(customer_id) AS no_of_rentals
FROM
	rental_enriched
GROUP BY
	customer_id
)
SELECT
customer_id,
customer_name,
email,
avg_days_between_rentals,
avg_days_rental_period,
(CASE WHEN avg_days_between_rentals < avg_days_rental_period THEN 'Multi rentals' ELSE 'Non-Multi rentals' END) AS customer_rental_type
FROM rental_summary
GROUP BY
customer_id;




--  Last_value():
#Question 1 --What is the genre of the last movie rented in a day? 
-- Used 4 Table join on rental , inventory , film_category,category tables
USE sakila;
CREATE TEMPORARY TABLE combined_table2 AS

	SELECT 
		rental.rental_id,CONVERT(rental.rental_date, date) AS only_date,
		CONVERT (rental.rental_date, time) 
		AS only_time ,rental.inventory_id,inventory.film_id,film_category.category_id,category.name 
	FROM 
		rental LEFT JOIN inventory 
		ON rental.inventory_id=inventory.inventory_id
			LEFT JOIN film_category
		ON inventory.film_id=film_category.film_id
			LEFT JOIN category
		ON film_category.category_id=category.category_id;

SELECT 
	DISTINCT only_date,LAST_VALUE (name) 
OVER 
	(
		PARTITION BY only_date 
		ORDER BY only_time 
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS last_movie_rented_in_a_day
FROM 
	combined_table2 ;






#Question 2-What is the last/ latest payment of customer from the given data (name of the customer also to be queried)?
-- Joined payment table and customer table
CREATE TEMPORARY TABLE last_payment AS

	SELECT 
		payment.customer_id,customer.first_name,customer.last_name,payment.amount,payment.payment_date
	FROM 
		payment LEFT JOIN customer
	ON payment.customer_id=customer.customer_id;

	SELECT 
		DISTINCT first_name,last_name,LAST_VALUE(amount)
	OVER
		(
        PARTITION BY customer_id 
		ORDER BY payment_date 
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS latest_payment
	FROM 
		last_payment;






    
    
