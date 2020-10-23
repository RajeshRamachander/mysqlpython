Use sakila;

--  Last_value():
#Question 1 --What is the genre of the last movie rented in a day? 
-- Used 4 Table join on rental , inventory , film_category,category tables
create temporary table combined_table2 as
select rental.rental_id,
convert(rental.rental_date, date) as only_date,
convert (rental.rental_date, time) as only_time ,
rental.inventory_id,inventory.film_id,
film_category.category_id,category.name 
from rental left join inventory 
on rental.inventory_id=inventory.inventory_id
left join film_category
on inventory.film_id=film_category.film_id
left join category
on film_category.category_id=category.category_id;

select distinct only_date,
last_value (name) 
over(partition by only_date 
order by only_time 
range between unbounded preceding and unbounded following) last_movie_rented_in_a_day
from combined_table2 ;

#Question 2-What is the last/ latest payment of customer from the given data (name of the customer also to be queried)?
-- Joined payment table and customer table
create temporary table last_payment as
select payment.customer_id,
customer.first_name,
customer.last_name,payment.amount,
payment.payment_date
from payment left join customer
on payment.customer_id=customer.customer_id;

select distinct first_name,last_name,
last_value(amount)
over(partition by customer_id 
order by payment_date 
range between unbounded preceding and unbounded following) latest_payment
from last_payment;
