with dates as (
select 
distinct entry_date
from premium_accounts_by_day
order by entry_date asc
limit 7
),

curr_prem as
(
select entry_date, account_id
from premium_accounts_by_day
where entry_date in (select entry_date from dates)
and final_price > 0
),

prem_7day as
(
select entry_date, account_id
from premium_accounts_by_day
where entry_date in (select date_add(entry_date, interval 7 day) from dates)
and final_price > 0
)

select c.entry_date,
count(c.account_id), 
count(p.account_id)
from curr_prem c
left join
prem_7day p
on c.entry_date = date_add(p.entry_date, interval -7 day)
and c.account_id = p.account_id
group by 1
order by 1;
