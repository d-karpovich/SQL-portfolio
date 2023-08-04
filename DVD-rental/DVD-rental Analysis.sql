--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.
select concat_ws(' ', last_name, first_name) as "Customer name",
address,
city,
country
from customer 
join address using(address_id)
join city using(city_id)
join country using(country_id)


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.
-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.
select c.store_id, count(customer_id)as "Number of customers", ci.city, concat_ws(' ', st.last_name, st.first_name) as "Staff name"  
from customer c
join store s on c.store_id=s.store_id 
join address a on s.address_id=a.address_id 
join city ci on a.city_id = ci.city_id
join staff st on s.store_id = st.store_id 
group by c.store_id, ci.city_id, st.staff_id 
having count(customer_id) > 300


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов
select concat_ws(' ', c.last_name, c.first_name) as "Customer name", count(r.rental_id) 
from rental r 
join customer c on r.customer_id = c.customer_id 
group by c.customer_id 
order by count(r.rental_id) desc
limit 5




--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма
select concat_ws(' ', c.last_name, c.first_name), count(*), 
round(sum(p.amount)), min(p.amount), max(p.amount)
from customer c 
join rental r on c.customer_id = r.customer_id 
join payment p on r.rental_id = p.rental_id 
group by c.customer_id



--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 select c1.city, c2.city
 from city c1
 cross join city c2
 where c1.city < c2.city




--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 select customer_id, 
 round(avg(return_date::date - rental_date::date), 2)
 from rental r
 group by customer_id
 order by 1


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
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




--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.
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




--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".
select s.staff_id, count(p.payment_id),
	case 
		when count(p.payment_id) > 7300 then 'Да'
		else 'Нет'		
	end as "Премия"
from staff s
join payment p on p.staff_id = s.staff_id
group by s.staff_id 
