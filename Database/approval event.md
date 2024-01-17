* [wf_approval_event_po] and [ap_purchase_hdr]
For a [ap_purchase_hdr] record h:
1. It can have any number of [is_active = false] [wf_approval_event_po] records
2. If not (h.is_checked or h.confirmed), it have 0 [is_active = true] [wf_approval_event_po] records
3. If h.checked and not h.confirmed, it has 1 [is_active = true] [wf_approval_event_po] record
4. If h.is_checked and h.confirmed, it have 0 [is_active = true] [wf_approval_event_po] records

* [wf_approval_event_po].[is_active]
This is a calculated field.
is_active = not (coalesce(current_approval_seq, 0) = 0 or is_completed or is_cancelled)

* Requirement: find the approval_event_dtl_id
It must fulfill ALL requirement:
1. [ap_purchase_hdr].checked AND NOT [ap_purchase_hdr].confirmed
2. [ap_purchase_hdr].status_id IS NOT NULL and <> 0
3. [ap_purchase_hdr] has only 1 [is_active = true] [wf_approval_event_po] eh record
