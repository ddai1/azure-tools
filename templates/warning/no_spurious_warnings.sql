/*
executionMasks:
  jwt-role-glg: 17
glgjwtComment: 'Flag [17] includes = APP|USER'
*/

--parameters:
--@consultation_id int consultationId
--@task_id int taskId

set transaction isolation level read uncommitted;

/*
Should produce none of of these warnings:
- Function in a where clause: PROBE
- .sql preferred over mustache
*/

if @task_id is not null
begin
  select @consultation_id = consultation_id
  from task.consultation_relation
  where task_id = @task_id
end

--create table to store top ranked Cps
	DECLARE @CP_data TABLE
	(
 	  consultation_participant_id int
	  ,consultation_id int
  	  ,person_id int
	);

--add top scored ranked Cps to table
       INSERT INTO @CP_data (consultation_participant_id, consultation_id, person_id)--, score)
		select top 20
		  c.consultation_id,
		  cp.consultation_participant_id,
		  cp.person_id
		  from consult.consultation c
		    join consult.consultation_participant cp on cp.consultation_id = c.consultation_id
		    join dbo.council_member cm on cp.person_id = cm.person_id
		    join dbo.meeting_council_member_status_relation mcmsr on
		      cp.consultation_participant_status_id = mcmsr.meeting_participant_status_id
		      and cp.meeting_id = mcmsr.meeting_id
		      and mcmsr.app_name = 'simulacrum'
		    join tracking.MEETING_COUNCIL_MEMBER_STATUS_RELATION t
			  on mcmsr.meeting_council_member_status_relation_id = t.meeting_council_member_status_relation_id
		  where
		    cp.consultation_participant_status_id = 2
		    and c.consultation_id = @consultation_id
        and not exists(
            select 1 from dbo.INQUIRY_FOLLOWUP_RESPONSES i
            where i.council_member_id = cm.council_member_id
            and i.consultation_id = c.consultation_id
            and i.send_invite >= 0
          )
			--make sure the user is not already invited elsewhere
			and not exists (
					select consultation_participant_id
					from consult.consultation c2
					join consult.consultation_participant in_folder_cp
						on c2.consultation_id = in_folder_cp.consultation_id
						and in_folder_cp.consultation_participant_id != 2
						and in_folder_cp.person_id = cp.person_id
					where c2.consultation_folder_id = c.consultation_folder_id
					and c2.consultation_id != c.consultation_id
			)

--grab CM data
select
  cm.council_member_id, cm.short_bio,
  p.person_id, p.first_name, p.last_name,
  cm.company, cm.phone, p.email, p.title,
  cm.linked_in_profile_url,
  ad.city,
  ad.state,
  cou.country_name
	from @CP_data cpd
	join dbo.person p on cpd.person_id = p.person_id
    join dbo.council_member cm on cm.person_id = cpd.person_id
    join dbo.ADDRESS ad on cm.council_member_id = ad.council_member_id
    join gl.COUNTRY_CODES cou on ad.country = cou.code_id

--grab work history
select
  --company info
  cm.council_member_id,
  c.company_id,
  c.primary_name primaryName,
  c.url,
  bd.businessdescription,
  cmjfr.current_ind, cmjfr.end_year endYear, cmjfr.end_month endMonth, cmjfr.start_month startMonth, cmjfr.start_year startYear, cmjfr.title as jobTitle,
  --consultation info
  cpd.consultation_id, cpd.consultation_participant_id
  from @CP_data cpd
	 join dbo.council_member cm on cpd.person_id = cm.person_id
    join dbo.council_member_job_function_relation cmjfr on cmjfr.council_member_id = cm.council_member_id
    join dbo.company c on c.company_id = cmjfr.company_id
    left join capiq.dbo.ciqbusinessdescription bd on c.ciqid = bd.companyid

--grab PQs
select
cm.council_member_id
,q.question_text
,qr.Response_value as Value_Text
,ISNULL(qr.comment, '') as Comment
,c.consultation_id
,c.title as consultation_title
,qr.Response_Date as Comment_Date
from dbo.question q
join dbo.QUESTION_RESPONSE qr on qr.question_id = q.QUESTION_ID
join QUESTION_MEETING_REQUEST_RELATION qmrr on qmrr.QUESTION_ID = q.QUESTION_ID
join consult.CONSULTATION c on c.CONSULTATION_ID = qmrr.MEETING_REQUEST_ID
JOIN dbo.PERSON P ON QR.RESPONDENT_ID = P.PERSON_ID
join dbo.COUNCIL_MEMBER CM ON P.PERSON_ID = CM.Person_ID
join @CP_data cpd on cpd.person_id = QR.RESPONDENT_ID
where qr.QUESTION_RESPONSE_ID in
(
		--take 30 most reacent from each person
        select QUESTION_RESPONSE_ID
			 from (select QUESTION_RESPONSE_ID QUESTION_RESPONSE_ID
				  ,row_number() over(partition by qr.RESPONDENT_ID order by qr.Response_Date desc) as rownum
			        from dbo.QUESTION_RESPONSE QR
					 join @CP_data cpd on cpd.person_id = QR.RESPONDENT_ID
					) as tempTable
		where tempTable.rownum <= 30
)

--return some Consultation Data
select
  c.consultation_id consultationId,
  c.consultation_description_text description,
  c.title title,
  cmc.match_requirements,
  cmc.compliance_considerations,
  cmc.candidate_profile
from
  consult.consultation c
  left join consult.consultation_match_criteria cmc
    on cmc.consultation_id = c.consultation_id
    and getUTCDate() > cmc.valid_from_utc
    and getUTCDate() < cmc.valid_to_utc
where
  c.consultation_id = @consultation_id

--return the consultation in the folder
select distinct c2s.consultation_id, c2s.title
from consult.consultation c
join consult.CONSULTATION_FOLDER cf
on cf.consultation_folder_id = c.consultation_folder_id
join consult.consultation c2s
on cf.consultation_folder_id = c2s.consultation_folder_id
where
  c.consultation_id = @consultation_id
  and c2s.consultation_id != @consultation_id


-- This should NOT produce multiple databases warning
SELECT TOP 1
  P.FIRST_NAME
  , P.LAST_NAME
  , P.EMAIL
  , ET.TITLE
  , ET.MEETING_ID
  , ETR.DELIVERED_ON_UTC
  , ETR.CREATE_DATE_UTC
  , ETR.NOTIFIED_ON_UTC
  , ETR.APP_NAME
  , CE.COMPLIANCE_STATUS_ID
  , ET.START_DATE
  , MA.TZ_NAME
  , FIRM.CLIENT_NAME
  , FIRM.CLIENT_ID
  , C.CONTACT_ID
  , co.Research_Region__c
FROM
  EVENT_TRANSCRIPT_REQUEST ETR
  JOIN EVENT_TABLE ET ON ETR.MEETING_ID = ET.MEETING_ID
  JOIN MEETING_MEETING_ADDRESS_RELATION MMAR on ET.MEETING_ID = MMAR.MEETING_ID AND MMAR.PRIMARY_IND = 1
  JOIN MEETING_ADDRESS MA on MMAR.MEETING_ADDRESS_ID = MA.MEETING_ADDRESS_ID
  JOIN CONTACT C ON C.CONTACT_ID = ETR.CONTACT_ID
  JOIN PERSON P ON P.PERSON_ID = C.PERSON_ID
  JOIN CLIENT FIRM ON C.CLIENT_ID = FIRM.CLIENT_ID
  JOIN [SFDC].[dbo].[Contact] co ON co.VegaID__c = C.CONTACT_ID
  LEFT JOIN COMPLIANCE_EVENT CE ON CE.MEETING_ID = ETR.MEETING_ID AND CE.CLIENT_ID = C.CLIENT_ID
WHERE
  C.CLIENT_ID not in (4724, 6324)
