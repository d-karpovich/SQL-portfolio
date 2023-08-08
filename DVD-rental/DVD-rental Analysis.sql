-- List branches with the city, staff information and the number of customers, 
-- where this number is 300 and more. 
select c.store_id, count(customer_id) as "Number of customers", 
	ci.city, concat_ws(' ', st.last_name, st.first_name) as "Staff name"  
from customer c
join store s on c.store_id=s.store_id 
join address a on s.address_id=a.address_id 
join city ci on a.city_id = ci.city_id
join staff st on s.store_id = st.store_id 
group by c.store_id, ci.city_id, st.staff_id 
having count(customer_id) > 300


-- Find the Top-5 customers with the most rented DVDs
select concat_ws(' ', c.last_name, c.first_name) as "Customer name", count(r.rental_id) 
from rental r 
join customer c on r.customer_id = c.customer_id 
group by c.customer_id 
order by count(r.rental_id) desc
limit 5


-- Calculate for each customer:
-- 1. The number of rented films
-- 2. The total amount rounded to integer
-- 3. The minimal amount paid for the rent
-- 4. The maximum amount paid for the rent
-- 5. The average time each customer returns films
select concat_ws(' ', c.last_name, c.first_name), 
	count(*), round(sum(p.amount)), min(p.amount), max(p.amount), 
	round(avg(return_date::date - rental_date::date), 2) as rent_time
from customer c 
join rental r on c.customer_id = r.customer_id 
join payment p on r.rental_id = p.rental_id 
group by c.customer_id
order by c.customer_id 


-- Create a table with city pairs except for the duplicate cities.
 select c1.city, c2.city
 from city c1
 cross join city c2
 where c1.city < c2.city

	
-- How many times each film was rent? How much money did it bring?
select f.title, f.rating, c.name "category", l.name "language", count(r.rental_id), sum(p.amount)
from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id 
join payment p on p.rental_id = r.rental_id 
join film_category fc on fc.film_id = f.film_id 
join category c on fc.category_id = c.category_id 
join "language" l on l.language_id = f.language_id 
group by  f.film_id, c.name, l.name
order by 1


-- List films that have never been rented
select f.title, f.rating, c.name "category", l.name "language", count(r.rental_id), sum(p.amount)
from film f
left join inventory i on i.film_id = f.film_id
left join rental r on r.inventory_id = i.inventory_id 
left join payment p on p.rental_id = r.rental_id 
join film_category fc on fc.film_id = f.film_id 
join category c on fc.category_id = c.category_id 
join "language" l on l.language_id = f.language_id 
group by  f.film_id, c.name, l.name
having count(r.rental_id) = 0
order by 1


-- Calculate sales made by sellers. Mark yes in graph Bonus for rows where the result is more than 7300
select s.staff_id, count(p.payment_id),
	case 
		when count(p.payment_id) > 7300 then 'Yes'
		else 'No'		
	end as "Bonus"
from staff s
join payment p on p.staff_id = s.staff_id
group by s.staff_id 

	
-- Query payment table and add columns:
-- 1. Numerate all payments by date
-- 2. Numerate payments by date grouped by customer
-- 3. Running totals for payments by customers sorted by date and ascending amount
-- 4. Numerate payments by customers descending (equal amounts should be with the same number) 	
select *, row_number() over(order by payment_date) as row_number,
	row_number() over(partition by customer_id order by payment_date) as customer_payment,
	sum(amount) over(partition by customer_id order by payment_date, amount) as cumulative_total,
	dense_rank () over (partition by customer_id order by amount desc) as payment_rank
from payment
order by customer_id


-- Count the difference between the current and next payment of each customer.
select p.customer_id,
	concat_ws(' ', c.last_name, c.first_name), 
	payment_id,
	payment_date, 
	amount,
	lead(amount, 1, 0.) over(partition by p.customer_id order by payment_date) as next_pay,
	(lead(amount, 1, 0.) over(partition by p.customer_id order by payment_date))-amount  as difference
from payment p
join customer c on p.customer_id = c.customer_id  
order by customer_id 


-- List the last payments for each customer using the window function.
-- 1) Using first_value function
--explain analyze --1786.55 / 18.843
select customer_id,
		payment_id,
		payment_date,
		amount
from 
	(select *,
		first_value(payment_id) over (partition by customer_id order by payment_date desc)
	from payment p) t
where payment_id = first_value 
order by customer_id

-- 2) Optimized query - using max function
--explain analyze --872.37 / 9.542
select customer_id,
		payment_id,
		payment_date,
		amount
from 
	(select customer_id,
		payment_id,
		payment_date,
		amount,
		max(payment_date) over (partition by customer_id)
	from payment p) t 
where payment_date = max 


-- For each employee, list the daily sales and running totals for sales in August 2005
select *,
	sum(sum) over (partition by staff_id order by payment_date)
from(
	select staff_id, payment_date::date, sum(amount)
	from payment 
	group by  staff_id, payment_date::date
	order by 1, 2) t
where date_trunc('month', payment_date) = '2005-08-01' 


-- On 20th of August 2005 in shops was a promo – each 100th customer got a discount. 
-- List all customers who received this discount.
select *
from (
	select payment_id, customer_id, payment_date, row_number () over (order by payment_date)
	from payment p 
	where payment_date::date = '2005-08-20'
	group by payment_id 
	order by payment_date) t
where row_number % 100 = 0


-- For each country, list the customers:
-- 1. Who has rented the most film number
-- 2. Who has spent the most amount in the shop
-- 3. Who was the last lessee
--explain analyse --7924.05/36
with cte as (
	select c3.country_id, c3.country, c.customer_id, concat_ws(' ', c.last_name, c.first_name) cast_name,  
		count(i.film_id), sum(p.amount), max(r.rental_date) last_rent
	from rental r 
	join inventory i on r.inventory_id = i.inventory_id
	join payment p on p.rental_id = r.rental_id 
	join customer c on r.customer_id = c.customer_id
	join address a on c.address_id = a.address_id 
	join city c2 on a.city_id = c2.city_id 
	join country c3 on c2.country_id = c3.country_id 
	group by c3.country_id, c.customer_id
	),
cte2 as (
	select
		cte.country_id,
		first_value(cte.cast_name) over (partition by cte.country_id order by cte.count desc) cust_count,
		first_value (cte.cast_name) over (partition by cte.country_id order by cte.sum desc)  cust_amount,
		first_value (cte.cast_name) over (partition by cte.country_id order by cte.last_rent desc) cust_last_rent
	from cte
	)
select distinct co.country_id, co.country, cte2.cust_count, cte2.cust_amount, cte2.cust_last_rent
from cte2
right join country co on co.country_id = cte2.country_id
order by 1


--Count how many times each customer took the films with the attribute “Behind the Scenes”
select r.customer_id, count(i.film_id)
from rental r
join inventory i on r.inventory_id = i.inventory_id 
where i.film_id in 
	(SELECT f.film_id
	FROM film f
	where special_features @> array ['Behind the Scenes'])	
group by r.customer_id
order by 1


-- For each store, define and display the following analytics in one SQL query:
-- 1. the day on which the most films were rented (day in year-month-day format)
-- 2. number of films rented that day
-- 3. the day on which the films for the smallest amount were sold (day in the format year-month-day)
-- 4. the amount of the sale on that day
with cte1 as 
	(select s2.store_id, r.rental_date::date, count (i.inventory_id), sum(p.amount)
	from inventory i 
	join rental r on i.inventory_id  = r.inventory_id  
	join staff s on r.staff_id = s.staff_id 
	join store s2 on s.staff_id = s2.manager_staff_id
	join payment p on r.rental_id = p.payment_id 
	group by s2.store_id, r.rental_date::date),
cte2 as 
	(
	select cte1.store_id, cte1.rental_date::date, cte1.count, 
	row_number () over (partition by cte1.store_id order by cte1.count desc)
	from cte1	
	),
cte3 as
	(
	select cte1.store_id, cte1.rental_date::date, cte1.sum, 
	row_number () over (partition by cte1.store_id order by cte1.sum)
	from cte1		
	)	
select t.store_id, t.rental_date, t.count, cte3.rental_date, cte3.sum
from(
	select *
	from cte2
	where cte2.row_number = 1) t 
join cte3 on cte3.store_id = t.store_id
where cte3.row_number = 1
