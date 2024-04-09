<?php

require_once 'EDILib/EDIDecode.php';

$obj = json_decode(file_get_contents("TestEDI_ORDRSP_Multi.json"), TRUE) or die("Failed to decode JSON");
$interchange = new EDIInterchange($obj);

for ($i = 0; $i < 1; $i++) {
    $msg = $interchange->getMessage($i);

    $docNumber = $msg->findSegVal(segWithName("BGM"), "BGM02/BGM0201");
    $docPreparationDateTime = $msg->findSegVal(segWithName("DTM"), "DTM01/DTM0102");

    $predBY = segWithVal("NAD", "NAD01", "BY");
    $nadBYId = $msg->findLoopSegVal(loopSubSeg("NADLoop1", $predBY), $predBY, "NAD02/NAD0201");
    $predSE = segWithVal("NAD", "NAD01", "SE");
    $nadSEId = $msg->findLoopSegVal(loopSubSeg("NADLoop1", $predSE), $predSE, "NAD02/NAD0201");
    $curcode = $msg->findLoopSegVal(loopWithName("CUXLoop1"), segWithName("CUX"), "CUX01/CUX0102");

    var_dump(
        $docNumber,
        $docPreparationDateTime,
        $nadBYId,
        $nadSEId,
        $curcode
    );

    $linLoopList = $msg->findLoopList(loopWithName("LINLoop1"));
    foreach ($linLoopList as $linLoop) {
        $poDtl["lin_action_request_code"] = $linLoop->findSegVal("LINLoop1", segWithName("LIN"), "LIN02");
        $poDtl["lin_vendor_item_code"] = $linLoop->findSegVal("LINLoop1", segWithName("LIN"), "LIN03/LIN0301");       
        
        // PIA needs special treatment

        $poDtl["qty_confirmed_qty"] = $linLoop->findSegVal("LINLoop1", segWithName("QTY"), "QTY01/QTY0102");
        $priLoopList = $linLoop->findLoopList("LINLoop1", loopWithName("PRILoop1"));
        foreach ($priLoopList as $priLoop) {
            $prDtl["pri_price"] = $priLoop->findSegVal("PRILoop1", segWithName("PRI"), "PRI01/PRI0102");
            $prDtl["pri_unit_price_basis"] = $priLoop->findSegVal("PRILoop1", segWithName("PRI"), "PRI01/PRI0105");
        }

        $sccLoopList = $linLoop->findLoopList("LINLoop1", loopWithName("SCCLoop2"));
        foreach ($sccLoopList as $sccLoop) {
            $qtyLoopList = $sccLoop->findLoopList("SCCLoop2", loopWithName("QTYLoop4"));
            foreach ($qtyLoopList as $qtyLoop) {
                $prDtl["qty_confirmed_qty"] = $qtyLoop->findSegVal("QTYLoop4", segWithName("DTM"), "DTM01/DTM0102");
                $prDtl["requested_delivery_date"] = $qtyLoop->findSegVal("QTYLoop4", segWithVal("DTM", "DTM01/DTM0101", "2"), "DTM01/DTM0102");
                $prDtl["confirmed_delivery_date"] = $qtyLoop->findSegVal("QTYLoop4", segWithVal("DTM", "DTM01/DTM0101", "67"), "DTM01/DTM0102");
            }
        }

        var_dump($prDtl);
    }
}
