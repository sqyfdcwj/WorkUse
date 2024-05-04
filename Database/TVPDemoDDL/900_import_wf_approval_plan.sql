insert into wf_approval_plan(company_id, used_in_form)
select c.company_id, '-TfrmPO-'
from sys_company c
where not exists (
    select 1
    from wf_approval_plan ap
    where ap.company_id = c.company_id
);