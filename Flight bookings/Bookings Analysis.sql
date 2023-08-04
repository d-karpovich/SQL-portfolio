--task 1 +

select aircraft_code, count(*)
from seats s 
group by aircraft_code 
having count(*) < 50

--task 2 +
with cte as
	(select date_trunc('month', book_date)::date as booking_month, sum(total_amount) as booking_amount
	from bookings b 
	group by date_trunc('month', book_date)
	order by 1)
select cte.booking_month, lag(cte.booking_amount) over (), cte.booking_amount,
	case when lag(cte.booking_amount) over () = 0
		then 0
		else round(((cte.booking_amount - lag(cte.booking_amount) over())/lag(cte.booking_amount) over () * 100), 2)
	end as difference
from cte

with cte as
	(select date_trunc('month', book_date)::date as booking_month, sum(total_amount) as booking_amount
	from bookings b 
	group by date_trunc('month', book_date)
	order by 1)
select cte.booking_month, lag(cte.booking_amount) over (), cte.booking_amount,
	coalesce (round(((cte.booking_amount - lag(cte.booking_amount) over())/lag(cte.booking_amount) over () * 100), 2), 0) as difference
from cte

--task 3 +
--explain analyse --28.22/0.336
select aircraft_code, array_agg(fare_conditions) as fc
from seats s 
group by 1
having array_position(array_agg(fare_conditions) , 'Business')  is null

--task 4
with cte as (
	select aircraft_code, count(*) as seats_no
	from seats s 
	group by 1
	), 
cte2 as (
	select actual_departure, departure_airport, f.aircraft_code, cte.seats_no,
		sum(cte.seats_no) over (partition by departure_airport, actual_departure::date order by actual_departure) as cum_total,
		count(*) over (partition by departure_airport, actual_departure::date) as flight_count
	from flights f 
	left outer join boarding_passes bp on f.flight_id = bp.flight_id
	join cte on cte.aircraft_code = f.aircraft_code 
	where bp.flight_id is null and f.actual_departure is not null 
	)
select actual_departure, departure_airport , aircraft_code, seats_no, cum_total 
from cte2
where flight_count > 1


--task 5
select a.airport_name as departure , a2.airport_name as arrival, count(*), sum(count(*)) over (), count(*) / sum(count(*)) over () * 100. as proportion
from flights f
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 
group by 1,2


--task 6 +
select substring(contact_data ->> 'phone', 3, 3) as phonecode, count(passenger_id) 
from tickets t 
group by 1


--task 7 +
with cte as (
	select concat(f.departure_airport, f.arrival_airport), sum(tf.amount),
		case 
			when sum(tf.amount) < 50000000 then 'low'
			when sum(tf.amount) >= 50000000 and sum(tf.amount) < 150000000 then 'medium'
			else 'high'
		end as amount_cat
	from flights f 
	join ticket_flights tf on f.flight_id = tf.flight_id 
	group by 1)
select cte.amount_cat, count(concat)
from cte
group by 1

--task 8 +
select percentile_cont(0.5) within group (order by tf.amount) ticket_amount, 
	(select percentile_cont(0.5) within group (order by b.total_amount) booking_amount
	from bookings b),
	round(
		(select percentile_cont(0.5) within group (order by b.total_amount) booking_amount from bookings b)::numeric/
		(percentile_cont(0.5) within group (order by tf.amount))::numeric, 2) ratio
from ticket_flights tf

--task 9
create extension cube

create extension earthdistance

with cte as (
	select airport_code, ll_to_earth( latitude, longitude)
	from airports a),
cpk as (
	select t.departure_airport,  t.arrival_airport, min(t.amount) /  (earth_distance(cte.ll_to_earth, cte1.ll_to_earth)/1000) as cost_per_km--, earth_distance(cte.ll_to_earth, cte1.ll_to_earth)/1000 as earth_dist
	from (	
		select f.departure_airport,  f.arrival_airport, min(tf.amount) as amount
		from ticket_flights tf 
		join flights f on f.flight_id = tf.flight_id 
		group by 1, 2
		) t
	join cte on cte.airport_code = t.departure_airport 
	join cte as cte1 on cte1.airport_code = t.arrival_airport 
	group by 1, 2, cte.ll_to_earth, cte1.ll_to_earth
	)
select round(min(cpk.cost_per_km)::numeric, 2)
from cpk
