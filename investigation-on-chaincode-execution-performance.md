As suggested by simon, and I am posting my investigation on chaincode execution performance here:
(1) Modify TestExecuteInvokeTransaction in core/chaincode/exectransaction_test.go:534 ​It takes 20s to execute 10000 transactions on chaincode_example02​

    start := time.Now()
    for i := 0; i < 10000; i++ {
        , , _, err := invoke(ctxt, spec, pb.Transaction_CHAINCODE_INVOKE)
        if err != nil {
            return fmt.Errorf("Error invoking <%s>: %s", chaincodeID, err)
        }
    }
    elapse := time.Now().Sub(start).Nanoseconds()
    fmt.Printf("total time: %d\n", elapse)

(2) Modify Invoke in examples/chaincode/go/chaincode_example02/chaincode_example02.go:74 ​it takes 10s to execute 10000 empty transactions​
func (t *SimpleChaincode) Invoke(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
  return nil, nil
}(3) Modify TestExecuteInvokeTransaction in core/chaincode/exectransaction_test.go:534 ​It takes 0.14s to execute 10000 transactions on peer​

 
    start := time.Now()
    for i := 0; i < N; i++ {
        ledgerObj, _ := ledger.GetLedger()
        ledgerObj.TxBegin("1")

        chaincodeID := cID.Name
        astr, _ := ledgerObj.GetState(chaincodeID, "a", false)
        bstr, _ := ledgerObj.GetState(chaincodeID, "b", false)
        aval, _ := strconv.Atoi(string(astr))
        bval, _ := strconv.Atoi(string(bstr))
        aval -= 10
        bval += 10
        astr = []byte(strconv.Itoa(aval))
        bstr = []byte(strconv.Itoa(bval))
        ledgerObj.SetState(chaincodeID, "a", astr)
        ledgerObj.SetState(chaincodeID, "b", bstr)
        ledgerObj.TxFinished("1", true)
        //_, _, _, err := invoke(ctxt, spec, pb.Transaction_CHAINCODE_INVOKE)
        //if err != nil {
        //    return fmt.Errorf("Error invoking <%s>: %s", chaincodeID, err)
        //}
    }
    elapse := time.Now().Sub(start).Nanoseconds()

(4) Modify TestExecuteDeploySysChaincode in core/system_chaincode/systemchaincode_test.go:193 ​It takes 3.55s to execute 10000 transactions on sample syscc​

    start := time.Now()
    for i := 0; i < 10000; i++ {
        _, _, _, err = invoke(ctxt, spec, pb.Transaction_CHAINCODE_INVOKE)
    }
    elapse := time.Now().Sub(start).Nanoseconds()
    fmt.Printf("total time: %d\n", elapse)
