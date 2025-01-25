select * from artist
select count(*) from artist
select * from canvas_size
select count(*) from canvas_size
select * from museum
select count(*) from museum
select * from museum_hrs
select count(*) from museum_hrs
select * from product_size
select count(*) from product_size
select * from subject
select count(*) from subject
select * from work
select count(*) from work


--All the paintings that are not displayed on any museums

select * from work
where museum_id is null;

--Are there museums without any paintings?

select name as museum_name from museum m 
where not exists 
(select * from work w where m.m_id = w.museum_id); 
-- the answer is no.

--How many paintings have an asking price of more than their regular price?

select * from product_size
where sales_price > regular_price;

--Identify the paintings whose asking price is less than 50% of its regular price

select w.name, ps.sales_price, ps.regular_price, w.work_id
from work as w join product_size as ps on w.work_id = ps.work_id
where (sales_price < (0.5 * regular_price));

--The most expensive canva size

select cs.label as canva, ps.sales_price 
from canvas_size as cs join product_size as ps 
on cs.size_id::text = ps.size_id
 order by ps.sales_price desc limit 1;
                          --OR
select cs.label as canva, ps.sales_price
	from (select *
		  , rank() over(order by sales_price desc) as rnk 
		  from product_size) ps
	join canvas_size cs on cs.size_id::text=ps.size_id
	where ps.rnk=1;	

-- Delete duplicate records from work, product_size, subject 

delete from work where ctid not in
(select min(ctid) from work 
group by work_id order by min(ctid) asc);

delete from product_size where ctid not in
(select min(ctid) from product_size
group by work_id, size_id order by min(ctid) asc);

delete from subject where ctid not in
(select min(ctid) from subject
group by work_id, subject );

--Identify the museums with invalid city information in the given dataset

select * from museum 
	where city ~ '^[0-9]'

--Get the top 10 most famous painting subject

select subject, count(subject) as counts
from subject group by subject 
order by counts desc limit 10;

--Identify the museums which are open on both Sunday and Monday. Display museum name, city.

 select m.name as museum_name, m.city 
 from museum as m join museum_hrs as mh1 on m.m_id = mh1.museum_id
 where day ='Sunday' 
 and exists 
 (select * from museum_hrs mh2 where mh1.museum_id=mh2.museum_id and mh2.day = 'Monday');

--Museums that are open every single day?

select x.name from
(select m.name, mh.day,
row_number() over(partition by m.name) as rownum
from museum as m join museum_hrs as mh on
m.m_id = mh.museum_id) as x
where x.rownum = 7;

--The top 5 most popular museum? (Popularity is defined based on most no of paintings
--in a museum)

select x.name from
(select w.museum_id, m.name, count(w.work_id) as no_of_paintings
from work as w join museum as m 
on w.museum_id = m.m_id
where w.museum_id is not null 
group by w.museum_id, m.name 
order by no_of_paintings desc limit 5) as x;

--The top 5 most popular artist? (Popularity is defined based on most no of paintings done by
--an artist)

select w.artist_id, a.full_name, a.nationality, count(w.work_id) as no_of_paintings 
from artist as a join work as w 
on a.artist_id = w.artist_id
group by w.artist_id, a.full_name, a.nationality
order by no_of_paintings desc limit 5;

--Display the 3 least popular canva sizes

select x.canva_size from
(select cs.label as canva_size, ps.size_id, count (ps.work_id) as no_of_paintings,
dense_rank() over(order by count (ps.work_id) ) as ranking
from canvas_size as cs join product_size as ps on cs.size_id::text = ps.size_id
group by cs.label, ps.size_id) as x where x.ranking <= 3;

--Which museum is open for the longest during a day. 
--Display museum name, state and hours open and which day?

select x.name, x.state, x.day, x.opened_duration from
(select  m.name, m.state, mh.day,
to_timestamp(open,'HH:MI AM') as open_time, to_timestamp(close,'HH:MI PM') as close_time,
(to_timestamp(close,'HH:MI PM') - to_timestamp(open,'HH:MI AM')) as opened_duration,
rank() over(order by (to_timestamp(close,'HH:MI PM') - to_timestamp(open,'HH:MI AM')) desc) as rnk
from museum as m join museum_hrs as mh on m.m_id = mh.museum_id) as x
where x.rnk = 1;

--Artists whose paintings are displayed in multiple countries

with cte as
		(select  distinct a.full_name as artist
		, w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.m_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;

--Display the country and the city with most no of museums. Output 2 seperate columns to
--mention the city and country. If there are multiple value, seperate them with comma.

with 
   cte_country as
     (select country, count(*),
      rank() over(order by count(*) desc) as rnk
      from museum group by country),
   cte_city as
     (select city, count(*),
      rank() over(order by count(*) desc) as rnk
      from museum group by city)
select string_agg(distinct country, ',') , string_agg(city, ',') 
from cte_country cross join cte_city
where cte_country.rnk = 1 and cte_city.rnk = 1;
--







