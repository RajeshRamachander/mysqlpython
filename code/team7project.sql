USE SAKILA;

SHOW TABLES;

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


/* 
PYTHON SQL INTEGRATION Queries
*/


/*

1. Kirk Gopal is looking to meet the staff in each store, let him know the address to meet them
*/



SELECT 
	staff.first_name AS manager_first_name, 
    staff.last_name AS manager_last_name,
    address.address, 
    address.district, 
    city.city, 
    country.country

FROM store
	LEFT JOIN staff ON store.manager_staff_id = staff.staff_id
    LEFT JOIN address ON store.address_id = address.address_id
    LEFT JOIN city ON address.city_id = city.city_id
    LEFT JOIN country ON city.country_id = country.country_id
;


/*
Kirk want to understand the inventory is in terms of replacement cost. 
He wants to see the impact if a certain category of film became unpopular at a certain store. 
He would like to see the number of films, as well as the average replacement cost, and total replacement cost, sliced by store and film category.
*/

SELECT 
	store_id, 
    category.name AS category, 
	COUNT(inventory.inventory_id) AS films, 
    AVG(film.replacement_cost) AS avg_replacement_cost, 
    SUM(film.replacement_cost) AS total_replacement_cost
    
FROM inventory
	LEFT JOIN film
		ON inventory.film_id = film.film_id
	LEFT JOIN film_category
		ON film.film_id = film_category.film_id
	LEFT JOIN category
		ON category.category_id = film_category.category_id

GROUP BY 
	store_id, 
    category.name
    
ORDER BY 
	SUM(film.replacement_cost) DESC
;


/*

3. Kirk wants to the customer demographics. Please provide a list 
of all customer names, which store they go to, whether or not they 
are currently active, and their full addresses. 
*/


SELECT 
	customer.first_name, 
    customer.last_name, 
    customer.store_id,
    customer.active, 
    address.address, 
    city.city, 
    country.country

FROM customer
	LEFT JOIN address ON customer.address_id = address.address_id
    LEFT JOIN city ON address.city_id = city.city_id
    LEFT JOIN country ON city.country_id = country.country_id
;



/*

4. Kirk would like to understand how much customers are 
spending with you, and also to know who your most top paying 
customers are.

*/

SELECT 
	customer.first_name, 
    customer.last_name, 
    COUNT(rental.rental_id) AS total_rentals, 
    SUM(payment.amount) AS total_payment_amount

FROM customer
	LEFT JOIN rental ON customer.customer_id = rental.customer_id
    LEFT JOIN payment ON rental.rental_id = payment.rental_id

GROUP BY 
	customer.first_name,
    customer.last_name

ORDER BY 
	SUM(payment.amount) DESC
    ;
    

-- 5.How is the length of the movie related to the movie rating, rental duration and rental rate set by the store? TABLE(s): film
SELECT
	rating AS movie_rating,
	AVG(length) AS avg_movie_length,
    AVG(rental_duration) AS avg_rental_duration,
    AVG(rental_rate) AS avg_rental_rate
FROM film
GROUP BY 1
ORDER BY 2,3;
    
-- 6. Which category of movie is the longest and does this have any relationship with rental rate? TABLE(s) category, film, film category

SELECT
	c.name AS category,
	AVG(f.length) AS avg_length,
    AVG(f.rental_rate) AS avg_rental_rate
FROM film AS f
	LEFT JOIN film_category AS fc
		ON f.film_id = fc.film_id
	LEFT JOIN category AS c
		ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY 2 DESC,3 DESC;

-- 7. Which actor has best average rental rate for his/ her movie? -- TABLE(s) film_actor, films
SELECT
	a.actor_id AS actor_id,
    CONCAT(a.first_name,' ',a.last_name) As actor_name,
    AVG(f.rental_rate) AS avg_rental_rate
    
FROM film AS f
	LEFT JOIN film_actor AS fa
		ON fa.film_id = f.film_id
	LEFT JOIN actor AS a
		ON a.actor_id = fa.actor_id
GROUP BY 1
ORDER BY 3 DESC
LIMIT 1;


-- 8. Which category (genre or rating) of film has the most rentals, and does this have to do anything with the length of the film? TABLE(s): category, film, inventory,rental

SELECT
	f.rating AS rating,
	COUNT(DISTINCT r.rental_id) AS number_of_rentals,
    f.length AS film_length
FROM rental AS r
	LEFT JOIN inventory AS i
		ON i.inventory_id = r.inventory_id
	LEFT JOIN film AS f
		ON f.film_id = i.film_id
GROUP BY 
	f.rating,
    f.length
ORDER BY 2 DESC, 3 DESC;



-- 9. What are the top 5 earning genre or rating of films rented by the customers per store - count and revenue? TABLES: category, payment, film

SELECT
	s.store_id AS store_id,
	c.name AS genre,
    COUNT(DISTINCT r.rental_id) AS rentals,
	SUM(p.amount) AS revenue
FROM store AS s
	LEFT JOIN inventory AS i
		ON i.store_id = s.store_id
	LEFT JOIN film AS f
		ON f.film_id = i.film_id
	LEFT JOIN film_category AS fc
		ON f.film_id = fc.film_id
	LEFT JOIN category As c
		ON fc.category_id = c.category_id
	LEFT JOIN rental AS r
		ON i.inventory_id = r.inventory_id
	LEFT JOIN payment AS p
		ON p.rental_id = r.rental_id
GROUP BY
	s.store_id,
    c.name
ORDER BY 1, 3 DESC,4 DESC;



    
    
