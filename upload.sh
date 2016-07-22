#!/bin/bash


OLD_IFS="$IFS"
IFS="!"

counter=0
org=0
data=""
lines=""
while read line
do
    [[ $line =~ "X1!@!X2!@!X3!@!X4!@!X5!@!X6!@!X7!@!X8!@!X10!@!X9" ]] && continue
    if [ $counter -eq 10 ]; then
      if [ $org -eq 0 ]; then
        curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d '{  "enrollId": "jim",  "enrollSecret": "6avZQLwcUe9b" }' "http://10.199.90.105:5000/registrar"
        curl -i -X POST -H "Content-Type: application/json" http://10.199.90.105:5000/chaincode -d "{ \"jsonrpc\": \"2.0\", \"method\": \"invoke\", \"params\": { \"type\": 1, \"chaincodeID\":{ \"name\":\"6cbda1570b51c045731f618441a8b12072448b51512bb043564ee13288f56f1e7c88d6fe91701bd94583de2151235ed3baeec83004bc7d7aeb801f8425ba3299\" },\"ctorMsg\": { \"function\":\"write\", \"args\":[$data] }, \"secureContext\":\"jim\", \"confidentialityLevel\":1, \"metadata\":\"amlt\", \"attributes\":[\"role\"]  }, \"id\": 5}"
        ((org=org+1))
      elif [ $org -eq 1 ]; then
        curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d '{  "enrollId": "diego",  "enrollSecret": "DRJ23pEQl16a" }' "http://10.199.90.105:5000/registrar"
        curl -i -X POST -H "Content-Type: application/json" http://10.199.90.105:5000/chaincode -d "{ \"jsonrpc\": \"2.0\", \"method\": \"invoke\", \"params\": { \"type\": 1, \"chaincodeID\":{ \"name\":\"6cbda1570b51c045731f618441a8b12072448b51512bb043564ee13288f56f1e7c88d6fe91701bd94583de2151235ed3baeec83004bc7d7aeb801f8425ba3299\" },\"ctorMsg\": { \"function\":\"write\", \"args\":[$data] }, \"secureContext\":\"diego\", \"confidentialityLevel\":1, \"metadata\":\"ZGllZ28=\", \"attributes\":[\"role\"]  }, \"id\": 5}"
       ((org=org+1))
      else
        curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d '{  "enrollId": "binhn",  "enrollSecret": "7avZQLwcUe9q" }' "http://10.199.90.105:5000/registrar"
        curl -i -X POST -H "Content-Type: application/json" http://10.199.90.105:5000/chaincode -d "{ \"jsonrpc\": \"2.0\", \"method\": \"invoke\", \"params\": { \"type\": 1, \"chaincodeID\":{ \"name\":\"6cbda1570b51c045731f618441a8b12072448b51512bb043564ee13288f56f1e7c88d6fe91701bd94583de2151235ed3baeec83004bc7d7aeb801f8425ba3299\" },\"ctorMsg\": { \"function\":\"write\", \"args\":[$data] }, \"secureContext\":\"binhn\", \"confidentialityLevel\":1, \"metadata\":\"YmluaG4=\", \"attributes\":[\"role\"]  }, \"id\": 5}"
        org=0
      fi
      counter=0
      data=""
    fi
    arr=($line)
    #echo ${arr[0]}${arr[2]}
    #echo $line
    if [ $counter -eq 0 ]; then
      data+="\"${arr[0]}${arr[2]}\",\"${line%?}\""
    else
      data+=",\"${arr[0]}${arr[2]}\",\"${line%?}\""
    fi
    ((counter=counter+1))
done < testds.csv


IFS="$OLD_IFS"
