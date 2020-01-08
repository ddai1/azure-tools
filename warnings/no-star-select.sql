/*
executionMasks:
  jwt-role-glg: 0
glgjwtComment: 'Flag [0] includes = DENY_ALL'
*/

set transaction isolation level read uncommitted;

select *
from bridge.call
where consultation_participant_id = 34998813
