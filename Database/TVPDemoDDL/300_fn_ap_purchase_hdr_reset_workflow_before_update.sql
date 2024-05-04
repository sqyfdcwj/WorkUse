
CREATE OR REPLACE FUNCTION public.fn_ap_purchase_hdr_reset_workflow_before_update (
)
RETURNS trigger AS
$body$
BEGIN
    INSERT INTO apps.po_trigger_log(purchase_id, created_by, log)
    SELECT NEW.purchase_id, TG_NAME, 
        'amount_net: ' || cast(OLD.amount_net AS VARCHAR) || ' -> ' || cast(NEW.amount_net AS VARCHAR)
     || ', checked: ' || CASE WHEN OLD.checked THEN 'T' ELSE 'F' END || ' -> ' || CASE WHEN NEW.checked THEN 'T' ELSE 'F' END
     || ', updated_by: ' || coalesce(NEW.updated_by, '');

    IF TG_OP = 'UPDATE' THEN
        IF OLD.amount_net <> NEW.amount_net 
          AND NEW.checked = OLD.checked AND NEW.checked 
          AND NEW.vendor_id NOT IN (1352, 2217, 2995) 
        THEN
            NEW.checked = FALSE;
            NEW.checked_by = '';
            NEW.checked_on = NULL;
            NEW.confirmed = FALSE;
            NEW.confirmed_by = '';
            NEW.confirmed_on = NULL;
            NEW.print_times = 0;
            
            INSERT INTO apps.po_trigger_log(purchase_id, created_by, log)
            SELECT NEW.purchase_id, TG_NAME, 'Changed';
        END IF;
    END IF;    
    RETURN NEW;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.fn_ap_purchase_hdr_reset_workflow_before_update ()
  OWNER TO postgres;

CREATE TRIGGER ap_purchase_hdr_reset_workflow_tr
  BEFORE UPDATE 
  ON public.ap_purchase_hdr
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.fn_ap_purchase_hdr_reset_workflow_before_update();
