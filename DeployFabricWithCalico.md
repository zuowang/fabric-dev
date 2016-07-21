docker run --net fabric --ip 192.168.0.2 -d -e CORE_VM_ENDPOINT=http://172.17.0.1:2375 -e CORE_LOGGING_LEVEL=DEBUG hyperledger/fabric-membersrvc membersrvc

docker run --net fabric --ip 192.168.0.3 -d -e CORE_VM_ENDPOINT=http://172.17.0.1:2375 -e CORE_PEER_ID=vp0 -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_SECURITY_ENABLED=true -e CORE_SECURITY_PRIVACY=true -e CORE_PEER_PKI_ECA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TCA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TLSCA_PADDR=192.168.0.2:50051 -e CORE_SECURITY_ENROLLID=test_vp0 -e CORE_SECURITY_ENROLLSECRET=MwYpmSRjupbT -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft -e CORE_PBFT_GENERAL_MODE=batch -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_PROFILE_ENABLED=true -P -p 30303:30303 -p 31315:31315 -p 5000:5000 hyperledger/fabric-peer peer node start

docker run --net fabric --rm -e CORE_VM_ENDPOINT=http://172.17.0.1:2375 -e CORE_PEER_ID=vp1 -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_PEER_DISCOVERY_ROOTNODE=192.168.0.3:30303 -e CORE_SECURITY_ENABLED=true -e CORE_SECURITY_PRIVACY=true -e CORE_PEER_PKI_ECA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TCA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TLSCA_PADDR=192.168.0.2:50051 -e CORE_SECURITY_ENROLLID=test_vp1 -e CORE_SECURITY_ENROLLSECRET=5wgHK9qqYaPy -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft -e CORE_PBFT_GENERAL_MODE=batch -e CORE_LOGGING_LEVEL=DEBUG hyperledger/fabric-peer peer node start

docker run --net fabric --rm -it -e CORE_VM_ENDPOINT=http://172.17.0.1:2375 -e CORE_PEER_ID=vp2 -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_PEER_DISCOVERY_ROOTNODE=192.168.0.3:30303 -e CORE_SECURITY_ENABLED=true -e CORE_SECURITY_PRIVACY=true -e CORE_PEER_PKI_ECA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TCA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TLSCA_PADDR=192.168.0.2:50051 -e CORE_SECURITY_ENROLLID=test_vp2 -e CORE_SECURITY_ENROLLSECRET=vQelbRvja7cJ -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft -e CORE_PBFT_GENERAL_MODE=batch -e CORE_LOGGING_LEVEL=DEBUG hyperledger/fabric-peer peer node start

docker run --net fabric --rm -it -e CORE_VM_ENDPOINT=http://172.17.0.1:2375 -e CORE_PEER_ID=vp3 -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_PEER_DISCOVERY_ROOTNODE=192.168.0.3:30303 -e CORE_SECURITY_ENABLED=true -e CORE_SECURITY_PRIVACY=true -e CORE_PEER_PKI_ECA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TCA_PADDR=192.168.0.2:50051 -e CORE_PEER_PKI_TLSCA_PADDR=192.168.0.2:50051 -e CORE_SECURITY_ENROLLID=test_vp3 -e CORE_SECURITY_ENROLLSECRET=9LKqKH5peurL -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft -e CORE_PBFT_GENERAL_MODE=batch -e CORE_LOGGING_LEVEL=DEBUG hyperledger/fabric-peer peer node start

This works:
curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d '{  "enrollId": "jim",  "enrollSecret": "6avZQLwcUe9b" }' "http://192.168.0.3:5000/registrar"

but this failed:
curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d '{  "enrollId": "jim",  "enrollSecret": "6avZQLwcUe9b" }' "http://10.199.90.105:5000/registrar"

That's because -p port1:port2 didn't work. We need to expose container port by ourselves.

First, 
calicoctl profile <PROFILE> rule add inbound allow tcp to ports 5000
Then,
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 5000 -j DNAT  --to 192.168.0.3:5000
iptables -t nat -A OUTPUT -p tcp -o lo --dport 5000 -j DNAT --to-destination 192.168.0.3:5000

> You are viewing the calico-containers documentation for release v0.19.0.

# Expose Container Port to Host Interface / Internet

In the [Calico without Docker networking tutorial](calico-with-docker/without-docker-networking/README.md)
or the [Calico as a Docker network plugin tutorial](calico-with-docker/docker-network-plugin/README.md)
we created containers and assigned endpoints (a container interface) to them. This is used for Container-
To-Container communication.

The example below shows how to expose a port of a container to the host interface so this container is
reachable from outside / the internet.

## Why isn't the `-p` flag on `docker run` working as expected?
If you connect containers to the `docker0` bridge interface, Calico would not
be able to enforce security rules between workloads on the same host; all
containers on the bridge would be able to communicate freely with one other.

> Note: Using Docker networking with the Docker default IPAM driver instructs the
> Calico network driver to route non-network traffic (i.e. destinations outside
> the network CIDR) via the Docker gateway bridge.  Traffic routed through the
> bridge may not be subjected to the policy configured on the host vRouter.

## Exposing Container Port to the Internet (via host interface)
The following steps explain how to expose port 80 of a container with IP
192.168.0.1 to be reachable from the internet via the host.

### Update Profile

First, add a rule to your container's profile to allow inbound TCP traffic to port 80:

> Note: If you are using Calico with Docker networking, you can use the network
> name as the profile.

```
calicoctl profile <PROFILE> rule add inbound allow tcp to ports 80
```

### Add iptables nat and forwarding rules on your host
Next, configure a forwarding rule on the host's interface to port 80 of your container IP

```
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j DNAT  --to 192.168.0.1:80
iptables -t nat -A OUTPUT -p tcp -o lo --dport 80 -j DNAT --to-destination 192.168.0.1:80
```

Now all traffic to your host interface on port 80 will be forwarded to the container IP 192.168.0.1.

For additional information on managing policy for your containers, you can read
the [Advanced Network Policy Guide](AdvancedNetworkPolicy.md).

[![Analytics](https://calico-ga-beacon.appspot.com/UA-52125893-3/calico-containers/docs/ExposePortsToInternet.md?pixel)](https://github.com/igrigorik/ga-beacon)
