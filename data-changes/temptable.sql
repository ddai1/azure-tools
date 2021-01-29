use glglive

select
top 10 
person_id,
first_name,
last_name
into #t_person
from dbo.PERSON

select *
from #t_person

drop table #t_person
