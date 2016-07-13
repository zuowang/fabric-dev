
simon
6:18 PM you see how it takes over 1 second to execute 1000 transactions (one batch)?
6:18 that's not consensus
zuowang
6:23 PM I don't catch your meaning. the ourstanding requests are not passed the consensus, aren't they? And I saw they reduce 1000 over 1 second.
simon
6:24 PM they are already in consensus
6:25 i think there are 13 batch requests queued for execution
zuowang
6:56 PM I think the concensus is processed batch by batch.
6:57 So in the next second, the consensus processed one batch, and the batch is sent to be executed. So the chaincode is waiting for requests to pass the consensus, right？
simon
6:58 PM no
6:59 first the primary sends out a pre-prepare message which contains all transactions.  this will take a while, depending on your batch size
6:59 then all other nodes will reply with a small prepare message
7:00 then all nodes reply to that message with a small commit message
7:00 once a node has received enough (2 in addition to its own) commit messages, it will queue the batch for execution
7:00 and the batch will be executed as soon as the previous batch has been executed
7:01 and it will do that with 20 batches in parallel
7:01 you can see that there are about 3 round trip times in latency
7:02 the execution takes much, much, much longer
zuowang
7:02 PM Could you tell where is the code to start 20 batches in parallel?
simon
7:02 PM sure
7:03 all requests are first forwarded to the primary
7:03 that's in batch submitToLeader
7:04 at the primary, these requests are enqueued into the batch store in leaderProcReq
7:04 if the batch store is full, sendBatch will trigger a consensus round
7:05 it enqueues a pbftMessageEvent which contains a Request
7:05 now we transition into pbft-core.go
zuowang
7:05 PM right, I can follow you.
simon
7:06 PM this then gets processed (eventually) by recvRequest
7:07 the request is stored, persisted to disk, and goes to sendPrePrepare
7:07 now we hit the first conditional
7:07 we say n := instance.seqNo + 1
7:08 and if !instance.inWV(instance.view, n)...
7:08 meaning, if there is no more free n, we do not send the pre-prepare for now
7:09 so we send L/2 pre-prepares in "parallel", without waiting for a request to finish
7:09 instance.h gets changed whenever the network reaches a checkpoint
7:10 which is every K=10
zuowang
7:10 PM why L/2？
simon
7:10 PM it is sort of a hack
7:11 we had some issues with the primary sending out new pre-prepares while some other nodes were still a bit slow
7:12 but regardless, L=K*4, by default, so 40
7:12 meaning there will be 20 batches running concurrently
zuowang
7:12 PM :grinning:
7:12 I see what you mean!
simon
7:13 PM you see that there is sufficient parallelism and little enough network activity
7:13 one performance bottleneck is in the chaincode execution, i'm sure
zuowang
7:14 PM https://github.com/hyperledger/fabric/issues/2023	
GitHub
Add log-level support for chaincode · Issue #2023 · hyperledger/fabric · GitHub
Description Docker daemon has a very high cpu usage when run performance test. Profile shows that the high cpu usage is caused by verbose logging in chaincode container. When docker daemon start...
7:14 I found the docker daemon has a very high cpu usage.
7:14 the reason is that the log-level of chaincode is hacked to be DEBUG.
simon
7:15 PM yes
7:15 i know
zuowang
7:15 PM the log is too verbose.
simon
7:15 PM i've done all of this optimization stuff in january :slightly_smiling_face:
zuowang
7:15 PM have you found any other bottlenecks?
7:16 Have you fix this issue? I have submit a patch for this today.
simon
7:18 PM nobody was interested really
7:18 then there was a big "oh no our performance sucks"
7:18 i told them what the problems were
7:19 and then nobody cared, people started complaining about consensus
7:19 it's always consensus
7:19 because, what else
7:19 ...
zuowang
7:20 PM I read from pbft paper. The benchmark of their evaluation is more than 6k tps.
simon
7:20 PM well yea
zuowang
7:21 PM So I will concentrate on chaincode performance.
simon
7:21 PM their transactions also don't do a dozen GRPC calls to a docker container
7:21 the problem i see is goroutine scheduling latency
7:21 because go is N:M threading, it has an internal scheduler
7:21 chaincode execution works like this:
7:22 grpc packet to chaincode "invoke"
7:22 chaincode grpc back to fabric "getstate"
7:22 fabric back to chaincode "result of getstate"
7:22 ... repeat
7:22 finally, "putstate" and "finish"
7:23 the problem is that there are many goroutines running in the fabric peer process
7:23 but only one can service the grpc "getstate" request (edited)
7:23 the chances that this one goroutine is scheduled drops with the number of active REST connections, etc.
7:24 so what happens is that it takes a while for this goroutine to be scheduled
7:24 then it gets the data from the database and sends it back
7:24 and that scheduling latency makes execution slow
7:26 does that make sense?
zuowang
7:33 PM how do you detect that the grpc "getstate" request is delayed?
7:34 The connection was unstable.
simon
7:35 PM indirectly
7:35 i created a set of microbenchmarks which show exactly this behavior
7:36 the latency goes up into ms
zuowang
7:37 PM or we can have some  feed back mechanism.
7:39 I ran you benchmark. But may be we can detect it directly.
7:39 with some performence counter.
