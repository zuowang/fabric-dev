echo "start..."
pass=("MS9qrN8hFjlE" "jGlNl6ImkuDo" "zMflqOKezFiA" "vWdLCE00vJy0" "3nXSrfoYGFCP" "yg5DVhm0er1z" "b7pmSxzKNFiw" "YsWZD4qQmYxo" "W8G0usrU7jRk" "H80SiB5ODKKQ")
for((i=0;i<10;i++)); do
{

  CORE_PEER_ADDRESS=172.17.0.2:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true build/bin/peer network login test_user$i -p ${pass[$i]}
  for((j=1;j<1000;j++)); do
  {
    CORE_PEER_ADDRESS=172.17.0.2:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true build/bin/peer chaincode invoke -u test_user$i -n 3ad1fc0c484709031dc75e9f0fe432a1b4940f6cdabd2484c4dfe457666d58dc93e968d4eb444fff39bf6e47b0baa1d6b4948010d46276af4485e9ea035e3299 -c '{"Function":"invoke", "Args": ["a","b","1"]}'
  }
  done
}&
done
wait
echo "end..."
