CREATE OR REPLACE FUNCTION public.ap_purchase_hdr_tr_add_wf_approval_event (
)
RETURNS trigger AS
$body$
DECLARE
    _parent_approval_event_id INTEGER; --Used in wf_approval_event_po
    _approval_event_id INTEGER; --Used in wf_approval_event_po and wf_approval_event_dtl
    _approval_plan_id INTEGER;  --Used in wf_approval_event_po
BEGIN
    INSERT INTO apps.po_trigger_log(purchase_id, created_by, log)
    SELECT NEW.purchase_id, TG_NAME, 
        'checked: ' || CASE WHEN OLD.checked THEN 'T' ELSE 'F' END || ' -> '  || CASE WHEN NEW.checked THEN 'T' ELSE 'F' END
     || ', updated_by = ' || coalesce(NEW.updated_by, '');
     
    IF NEW.checked AND NEW.checked <> coalesce(OLD.checked,false) THEN
        _approval_event_id = nextval('wf_approval_event_approval_event_id_seq');
        _parent_approval_event_id = max(approval_event_id)
                                    FROM wf_approval_event_po
                                    WHERE purchase_id = NEW.purchase_id;
                                    
        _approval_plan_id = approval_plan_id
                            FROM wf_approval_plan ph
                            WHERE ph.company_id = NEW.company_id OR ph.company_id = 0
                              AND used_in_form ~* '-TfrmPO-'
                            ORDER BY ph.company_id DESC
                            LIMIT 1;
                            
        RAISE NOTICE '%', 'ap_purchase_hdr_tr_add_wf_approval_event INSERT INTO wf_approval_event_po';
        INSERT INTO wf_approval_event_po (
            approval_event_id, parent_approval_event_id, approval_plan_id,
            ref_id, ref_no, purchase_id, 
            created_on, created_by
        )
        SELECT _approval_event_id, _parent_approval_event_id, _approval_plan_id,
            NEW.purchase_id, NEW.purchase_no, NEW.purchase_id, 
            now(), NEW.checked_by;
            
        INSERT INTO apps.po_trigger_log(purchase_id, created_by, log)
        SELECT NEW.purchase_id, TG_NAME, 'created wf_approval_event, id = ' || cast(_approval_event_id AS VARCHAR);
            
        RAISE NOTICE '%', 'ap_purchase_hdr_tr_add_wf_approval_event INSERT INTO wf_approval_event_dtl';
		INSERT INTO wf_approval_event_dtl (
            approval_event_id, approval_seq, approver_staff_id, 
            created_on, created_by
        )
        SELECT _approval_event_id, d.approval_seq, d.approver_staff_id,
            now(), NEW.checked_by
            
        FROM wf_approval_plan_dtl d
        WHERE d.approval_plan_id = _approval_plan_id;
        
    END IF;
    
    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.ap_purchase_hdr_tr_add_wf_approval_event ()
  OWNER TO postgres;


CREATE TRIGGER ap_purchase_hdr_tr_add_wf_approval_event
  AFTER UPDATE 
  ON public.ap_purchase_hdr
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.ap_purchase_hdr_tr_add_wf_approval_event();
