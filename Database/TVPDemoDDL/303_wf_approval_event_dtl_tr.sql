CREATE OR REPLACE FUNCTION public.wf_approval_event_dtl_tr (
)
RETURNS trigger AS
$body$
DECLARE
    _next_approval_seq INTEGER;
BEGIN
    IF NEW.is_rejected AND NEW.is_rejected <> OLD.is_rejected THEN
        RAISE NOTICE 'wf_approval_event_dtl_tr => Update wf_approval_event.is_cancelled';
    
        UPDATE wf_approval_event
        SET is_cancelled = TRUE,
            updated_on = NEW.updated_on,
            updated_by = NEW.updated_by
            
        WHERE approval_event_id = NEW.approval_event_id;
    END IF;
    
    IF NEW.is_approved AND NEW.is_approved <> OLD.is_approved THEN
        SELECT tmp.next_approval_seq
        INTO _next_approval_seq
        FROM (
            SELECT approval_event_dtl_id, approval_seq, 
                lag(approval_seq, -1) over(ORDER BY approval_seq) AS next_approval_seq
            FROM wf_approval_event_dtl
            WHERE approval_event_id = NEW.approval_event_id
        ) tmp
        WHERE tmp.approval_event_dtl_id = NEW.approval_event_dtl_id
        LIMIT 1;
        
        RAISE NOTICE 'wf_approval_event_dtl_tr => Update wf_approval_event.is_approved';
                             
        UPDATE wf_approval_event h
        SET current_approval_seq = _next_approval_seq,
            is_completed = _next_approval_seq IS NULL,
            updated_on = NEW.updated_on,  
            updated_by = NEW.updated_by
            
        WHERE approval_event_id = NEW.approval_event_id;
    END IF;
    
    RETURN NEW;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.wf_approval_event_dtl_tr ()
  OWNER TO postgres;

CREATE TRIGGER wf_approval_event_dtl_tr
  AFTER UPDATE 
  ON public.wf_approval_event_dtl
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.wf_approval_event_dtl_tr();
