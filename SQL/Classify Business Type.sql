select distinct business_name,
case 
    when business_name like '%restaurant%' then 'restaurant'
    when business_name like '%caf%' or business_name like '%coffee%' then 'cafe'
    when business_name like '%school%' then 'school'
    else 'other' end as business_type
from sf_restaurant_health_violations;
