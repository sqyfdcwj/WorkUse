CREATE OR REPLACE FUNCTION public.wf_approval_event_po_tr (
)
RETURNS trigger AS
$body$
BEGIN    
    --Cancelled
    IF NEW.is_cancelled AND NEW.is_cancelled <> OLD.is_cancelled THEN
        RAISE NOTICE '%', 'Cancelled by wf_approval_event_po_tr';
        
        INSERT INTO apps.po_trigger_log(purchase_id, created_by, log)
        SELECT NEW.purchase_id, TG_NAME, 'Cancelled';
    
        UPDATE ap_purchase_hdr
        SET checked = FALSE,
            checked_on = NULL,
            checked_by = NULL,
            confirmed = FALSE,
            confirmed_on = NULL,
            confirmed_by = NULL,
            updated_on = NEW.updated_on,
            updated_by = NEW.updated_by
            
        WHERE purchase_id = NEW.purchase_id;
        RETURN NULL;
    END IF;
    
    --Completed
    IF NEW.is_completed AND NEW.is_completed <> OLD.is_completed THEN
        RAISE NOTICE '%', 'Confirmed by wf_approval_event_po_tr'; 
        
        INSERT INTO apps.po_trigger_log(purchase_id, created_by, log)
        SELECT NEW.purchase_id, TG_NAME, 'Completed';
        
        UPDATE ap_purchase_hdr
        SET confirmed = TRUE,
            confirmed_on = NEW.updated_on,
            confirmed_by = NEW.updated_by,
            updated_on = NEW.updated_on,
            updated_by = NEW.updated_by
            
        WHERE purchase_id = NEW.purchase_id
          AND NOT coalesce(confirmed, FALSE);
        
        RETURN NULL;    
    END IF;

    
    --In Progress
    RAISE NOTICE '%', 'Update ap_purchase_hdr.updated_on AND updated_by';
    UPDATE ap_purchase_hdr
    SET updated_on = NEW.updated_on,
        updated_by = NEW.updated_by
                        
    WHERE purchase_id = NEW.purchase_id;

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.wf_approval_event_po_tr ()
  OWNER TO postgres;

CREATE TRIGGER wf_approval_event_po_tr
  AFTER UPDATE 
  ON public.wf_approval_event_po
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.wf_approval_event_po_tr();
