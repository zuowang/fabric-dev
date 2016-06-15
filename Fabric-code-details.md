### Fabric代码走读 ###

### Consensus流程 ###

Pbft Consensus包含三个阶段：PrePrepare， Prepare，Commit。下面Chaincode调用流程中可以看到，接收到Commit消息，意味着达成共识，才会去调用Chaincode的代码。

0  0x0000000000a02e1a in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).recvCommit
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:834
1  0x0000000000a028da in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).maybeSendCommit
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:823
2  0x0000000000a02310 in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).recvPrepare
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:804
3  0x0000000000a00d97 in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).recvPrePrepare
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:767
4  0x00000000009fa3c6 in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).ProcessEvent
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:339
5  0x00000000009e70dc in github.com/hyperledger/fabric/consensus/obcpbft.(*obcBatch).ProcessEvent
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/obc-batch.go:462
6  0x0000000000abbd5d in github.com/hyperledger/fabric/consensus/obcpbft/events.SendEvent
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/events/events.go:113
7  0x0000000000abbdd2 in github.com/hyperledger/fabric/consensus/obcpbft/events.(*managerImpl).Inject
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/events/events.go:123
8  0x0000000000abbeba in github.com/hyperledger/fabric/consensus/obcpbft/events.(*managerImpl).eventLoop
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/events/events.go:132
9  0x0000000000480540 in runtime.goexit
   at /opt/go/src/runtime/asm_amd64.s:1998

### Invoke Chaincode ###

Chaincode是Deploy后是作为一个docker container运行的。Fabric提供REST和GRPC(commandline)两种API，下面是他们的例子和调用入口：
#### REST API ####
>curl -X post 0.0.0.0:5000

func (s *ServerOpenchainREST) Invoke(rw web.ResponseWriter, req *web.Request) {  core/rest/rest_api.go:816
func (d *Devops) Invoke(ctx context.Context, chaincodeInvocationSpec *pb.ChaincodeInvocationSpec) (*pb.Response, error) { core/devops.go:245

#### GRPC ####
>CORE_PEER_ADDRESS=172.17.0.2:30303 ./peer chaincode invoke -n 3ad1fc0c484709031dc75e9f0fe432a1b4940f6cdabd2484c4dfe457666d58dc93e968d4eb444fff39bf6e47b0baa1d6b4948010d46276af4485e9ea035e3299 -c '{"Function":"invoke", "Args": ["a","b","1"]}'


var chaincodeInvokeCmd = &cobra.Command{ peer/main.go:206
func chaincodeInvoke(cmd *cobra.Command, args []string) error { peer/main.go:859
func chaincodeInvokeOrQuery(cmd *cobra.Command, args []string, invoke bool) (err error) { peer/main.go:873
func (c *devopsClient) Invoke(ctx context.Context, in *ChaincodeInvocationSpec, opts ...grpc.CallOption) (*Response, error) { protos/devops.pb.go:131

GRPC服务器端，执行Invoke调用。因为当前VP是primary Peer，所以会走到sendTransactionsToLocalEngine，然后发消息给Event Manager(ManagerImpl)执行Transaction。

 0  0x00000000009d8999 in github.com/hyperledger/fabric/consensus/obcpbft.(*externalEventReceiver).RecvMsg
    at ./src/github.com/hyperledger/fabric/consensus/obcpbft/external.go:45
 1  0x0000000000608d15 in github.com/hyperledger/fabric/consensus/helper.(*EngineImpl).ProcessTransactionMsg
    at ./src/github.com/hyperledger/fabric/consensus/helper/engine.go:84
 2  0x000000000069d2a4 in github.com/hyperledger/fabric/core/peer.(*PeerImpl).sendTransactionsToLocalEngine
    at ./src/github.com/hyperledger/fabric/core/peer/peer.go:504
 3  0x000000000069ee45 in github.com/hyperledger/fabric/core/peer.(*PeerImpl).ExecuteTransaction
    at ./src/github.com/hyperledger/fabric/core/peer/peer.go:609
 4  0x0000000000611551 in github.com/hyperledger/fabric/core.(*Devops).invokeOrQuery
    at ./src/github.com/hyperledger/fabric/core/devops.go:197
 5  0x0000000000611ddf in github.com/hyperledger/fabric/core.(*Devops).Invoke
    at ./src/github.com/hyperledger/fabric/core/devops.go:246
 6  0x00000000006c585d in github.com/hyperledger/fabric/protos._Devops_Invoke_Handler
    at ./src/github.com/hyperledger/fabric/protos/devops.pb.go:210
 7  0x0000000000584f83 in github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).processUnaryRPC
    at ./src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:350
 8  0x0000000000586a84 in github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).handleStream
    at ./src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:467
 9  0x000000000058aac3 in github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).Serve.func2.1.1
    at ./src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:278
10  0x0000000000480540 in runtime.goexit
    at /opt/go/src/runtime/asm_amd64.s:1998 

Event Manager是负责处理消息，以及提供消息处理超时服务等。 下面可以看到Event Manager是怎么启动的。
func serve(args []string) error { peer/main.go:384   
func GetEngine(coord peer.MessageHandlerCoordinator) (peer.Engine, error) {   consensus/helper/engine.go:111
func NewConsenter(stack consensus.Stack) consensus.Consenter {   consensus/controller/controller.go:38
func GetPlugin(c consensus.Stack) consensus.Consenter {   consensus/obcpbft/obc-pbft.go:43
func New(stack consensus.Stack) consensus.Consenter {   consensus/obcpbft/obc-pbft.go:52
func newObcBatch(id uint64, config *viper.Viper, stack consensus.Stack) *obcBatch {  consensus/obcpbft/obc-batch.go:82
func (em *managerImpl) Start() { consensus/obcpbft/events/events.go:99
func (em *managerImpl) eventLoop() { consensus/obcpbft/events/events.go:128


Event Manager消息处理循环中，接收到ProcessTransactionMsg，创建goroutine执行请求。
0  0x00000000009e2a72 in github.com/hyperledger/fabric/consensus/obcpbft.(*obcBatch).execute
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/obc-batch.go:207
1  0x0000000000a04851 in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).executeOne
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:922
2  0x0000000000a03f4e in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).executeOutstanding
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:877
3  0x0000000000a039b1 in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).recvCommit
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:863
4  0x00000000009f9ff4 in github.com/hyperledger/fabric/consensus/obcpbft.(*pbftCore).ProcessEvent
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/pbft-core.go:343
5  0x00000000009e70dc in github.com/hyperledger/fabric/consensus/obcpbft.(*obcBatch).ProcessEvent
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/obc-batch.go:462
6  0x0000000000abbd5d in github.com/hyperledger/fabric/consensus/obcpbft/events.SendEvent
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/events/events.go:113
7  0x0000000000abbdd2 in github.com/hyperledger/fabric/consensus/obcpbft/events.(*managerImpl).Inject
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/events/events.go:123
8  0x0000000000abbeba in github.com/hyperledger/fabric/consensus/obcpbft/events.(*managerImpl).eventLoop
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/events/events.go:132
9  0x0000000000480540 in runtime.goexit
   at /opt/go/src/runtime/asm_amd64.s:1998

Chaincode的执行在goroutine里callstack。
0  0x000000000061b2b4 in github.com/hyperledger/fabric/core/chaincode.(*ChaincodeSupport).Execute
   at ./src/github.com/hyperledger/fabric/core/chaincode/chaincode_support.go:580
1  0x000000000061c767 in github.com/hyperledger/fabric/core/chaincode.Execute
   at ./src/github.com/hyperledger/fabric/core/chaincode/exectransaction.go:100
2  0x000000000061d4fb in github.com/hyperledger/fabric/core/chaincode.ExecuteTransactions
   at ./src/github.com/hyperledger/fabric/core/chaincode/exectransaction.go:147
3  0x000000000060b51e in github.com/hyperledger/fabric/consensus/helper.(*Helper).ExecTxs
   at ./src/github.com/hyperledger/fabric/consensus/helper/helper.go:182
4  0x00000000009e3928 in github.com/hyperledger/fabric/consensus/obcpbft.(*obcBatch).executeImpl
   at ./src/github.com/hyperledger/fabric/consensus/obcpbft/obc-batch.go:242
5  0x0000000000480540 in runtime.goexit
   at /opt/go/src/runtime/asm_amd64.s:1998

