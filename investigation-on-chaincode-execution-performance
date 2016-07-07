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
    }

(3) Modify TestExecuteInvokeTransaction in core/chaincode/exectransaction_test.go:534 ​It takes 0.14s to execute 10000 transactions on peer​

 
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


ashnur
9:01 PM zuowang: what kind of machine was this running on?
simon
9:04 PM it really doesn't matter much
ashnur
11:50 PM dunno, for me it seems like a significant factor to judge these numbers
simon
1:34 AM why?
cbf
2:03 AM I’m unclear why system chaincode is taking so much time… any thoughts?
simon
2:14 AM @muralisr: any ideas?
2:14 maybe there also internal grpc happening?
muralisr
2:47 AM @cbf @simon  the system chaincode still retains the chaincode machinery on the peer side and the the chaincode side (the FSM for example) via common code. Only the transport is different (grpc/TCP vs channels/goroutines)
simon
2:48 AM so why is it so slow then?
muralisr
2:51 AM hmm because it still retains the chaincode machinery on both sides
2:51 ?
2:51 there should be a factor improvement between docker chaincode and system chaincode though
cbf
3:01 AM yeah but it isn’t what I would have expected
3:01 is it doing the marshaling/unmarshaling?
simon
3:06 AM well this would be an easy candidate for profiling
muralisr
3:18 AM The grpc protobuf marshalling/unmarshalling is not there. Unlike the direct Database calls, there’s back and forth between chaincode and the peer for every ledger access. The mechanics of this back and forth to allow for constraints (serial invokes vs parallel etc) woud likely be a big part
3:19 we ​could​ figure out direct access from chaincode to ledger to break some of the chitchat… but then we’ll have to refactor common code
3:22 on a different note, the other thing I though we could do fairly easily with docker chaincodes is to execute transactions to different chaincodes concurrently. On a multichaincode system we immediately get more utilization
simon
3:24 AM what if one chaincode calls the other?
muralisr
3:24 AM back of the que
3:25 so each chaincode really has a q of transactions
3:30 I’ve been meaning to try it out in a branch… hopefully soon
simon
3:31 AM what do you mean, back of the queue?
3:31 then the semantics work completely differently
3:31 how do you get a proper total order?
muralisr
3:31 AM each of the chaincode will have a q of transactions
3:31 this would only for ​execution​
3:31 not for ordering
3:33 the execute call would have to synchronously wait for the executions and reurn the transactions when the batch is complete
3:34 again this only makes a difference when there are  txs to multiple chaincodes.
simon
3:34 AM not impressed
muralisr
3:34 AM because
3:34 if you have 10 transactions
3:34 you could be executing them in parallel
simon
3:35 AM sure
3:35 but that's why we have v2
muralisr
3:35 AM right
simon
3:35 AM where we can look at the pre/postimage
3:35 and we can see directly which executions are independent
3:35 and then can run all of them in parallel
3:35 possibly even on separate machines
3:36 treat it like a database
muralisr
3:37 AM maybe I’m missing something….. in the endorser, when it receives 10 transactions how does it know how to execute them in parallel ?
simon
3:38 AM it receives the pre and postimage
muralisr
3:38 AM don’t you have to execute first when submitted ?
simon
3:38 AM if pre and postimages do not intersect, they are independent
3:39 the submitting peer sends pre and post image
3:39 or at least the keys
3:40 that's the whole reason why we want to redesign it
3:40 so that execution can be scaled
muralisr
3:40 AM so client->submitting peer (execute chaincode) -> endorsers ……………. consensus ?
simon
3:41 AM yes
3:41 endorsers also execute
muralisr
3:41 AM right
3:41 that’s what I thought
3:41 and thats where I thought you are going to have the same issue
3:42 but perhaps endorsers don’t “execute" using chaincode ?
simon
3:42 AM of course they do
3:42 they have to
muralisr
3:44 AM then I don’t understand how the  parallelization can NOT help there as well
simon
3:44 AM yes it does
3:45 but you can look at which jobs to parallelize
3:45 actually, all can be parallelized, because the state doesn't get changed by execution
muralisr
3:47 AM ok…. I still see need to do the kind of parallization. I only claim we can do it even now based on just the chaincodes being executed
simon
3:49 AM but how do you deal with the fact that some chaincodes can call other chaincodes?
3:49 i think we need to look more into the execution overhead
3:49 why is it 20x
3:52 and only 6x between system cc and real cc
muralisr
3:57 AM c-c won’t be direct call like it is today but will have to be added to the que of tx for that chaincode
3:58 direct DB GetState / PutState instead of peer-chaincode exchange has overheads
3:59 some of it is minimized by system chaincode by avoiding grpc channel calls
simon
3:36 PM well it seems that the difference ix 6x between syscc and real cc
3:36 compared to another 20x between syscc and direct emulated cc
3:36 that tells me that the chaincode coordination is inefficient, and not grpc
