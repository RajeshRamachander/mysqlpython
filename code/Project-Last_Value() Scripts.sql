

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





