use sakila;


-- Query 1: Get number of monthly active customers.
-- step 1: crating view from all data from rental for further use
create or replace view user_activity as
	select rental_id, customer_id,
		convert(rental_date, date) as Activity_date,
		date_format(convert(rental_date, date), '%m') as Activity_month,
		date_format(convert(rental_date, date), '%Y') as Activity_year
	from rental;
    
select * from user_activity;

-- step 2:
create or replace view monthy_active_users as
	select Activity_year, Activity_month, count(distinct customer_id) as active_user
    from user_activity
    group by Activity_year, Activity_month;
    
select * from monthy_active_users;

-- Query 2: Active users in the previous month.
select Activity_year, Activity_month, active_user,
		lag(active_user) over (order by Activity_year, Activity_month) as last_month
from monthy_active_users;

-- Query 3: Percentage change in the number of active customers.
create or replace view percentage_monthy_active_users as
with cte_view as (
	select Activity_year, Activity_month, active_user,
		lag(active_user) over (order by Activity_year, Activity_month) as last_month
	from monthy_active_users 
)
	select Activity_year, Activity_month, active_user, last_month,
		(((active_user - Last_month)/active_user)*100) as percentage
	from cte_view;

select * from percentage_monthy_active_users;

-- Query 4: Retained customers every month.
select * from user_activity;

-- step 1: unique active users per month
create or replace view distinct_users as
	select distinct customer_id as Active_id, Activity_year, Activity_month
    from user_activity
    order by Activity_year, Activity_month, Active_id;

select * from distinct_users;

-- step 2: to find retaind customers
create or replace view retained_customers as
	select d1.Active_id, d1.Activity_year, d1.Activity_month, d2.Activity_month as last_month
    from distinct_users as d1
    join distinct_users as d2 on d1.Activity_year = d2.Activity_year
								and d1.Activity_month = d2.Activity_month + 1
                                and d1.Active_id = d2.Active_id
	order by d1.Active_id, d1.Activity_year, d1.Activity_month;
    
select * from retained_customers;

-- step 3: count retained customers per month
create or replace view total_retained_users as
	select Activity_year, Activity_month, count(Active_id) as Retained_customer
    from retained_customers
    group by Activity_year, Activity_month;
    
select * from total_retained_users;

-- step 4: using lag for the previous moth customers
create or replace view retained_users_monthly as
	select *,
		lag(Retained_customer) over () as Previous_month_users
    from total_retained_users;

select * from retained_users_monthly;

-- step 5: difference between retained and previous month customers
select *, Retained_customer - Previous_month_users from retained_users_monthly;