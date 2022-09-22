#!/bin/bash

# List of all regions to copy from
ALL_REGIONS="
au-syd1
de-fra1
es-mad1
fi-hel1
fi-hel2
nl-ams1
pl-waw1
sg-sin1
uk-lon1
us-chi1
us-nyc1
us-sjo1
"

# Rocky Linux 8
OS="01000000-0000-4000-8000-000150010100"
GRAPHS_DIR="$(date -I)-$(date +%s)"
DISK_SIZE="10"
DISK_TYPE="maxiops" # maxiops or hdd
PLAN="2xCPU-4GB"
REGIONS="
us-sjo1
de-fra1
fi-hel1
fi-hel2
"

if [ ${#SSH_KEY} -eq 0 ]; then
  echo "Please set SSH_KEY"
  exit 1
fi

function run_benchmark() {
  HOSTNAME="bencher-$1"
  IP_ADDR=$(upctl server create \
    --title "Bencher $1" \
    --zone $1 \
    --hostname $HOSTNAME \
    --os $OS \
    --plan $PLAN \
    --storage "action=create,address=virtio,title=${1}-disk-1,size=$DISK_SIZE,tier=${DISK_TYPE},type=disk" \
    --storage "action=create,address=virtio,title=${1}-disk-2,size=$DISK_SIZE,tier=${DISK_TYPE},type=disk" \
    --storage "action=create,address=virtio,title=${1}-disk-3,size=$DISK_SIZE,tier=${DISK_TYPE},type=disk" \
    --ssh-keys "${SSH_KEY}.pub" \
    -ojson \
    --wait | jq -r '.ip_addresses[] | select(.access | match("public")) | select(.family | match("IPv4")).address')

  until nc -vz $IP_ADDR 22; do
    sleep 5
  done

  echo "Running remote script..."
  ssh -oStrictHostKeyChecking=no root@${IP_ADDR} -i $SSH_KEY 'bash -s' <./remote.sh

  mkdir -p ./graphs/${GRAPHS_DIR}
  scp -oStrictHostKeyChecking=no -i $SSH_KEY root@${IP_ADDR}:/root/*.png ./graphs/${GRAPHS_DIR}/

  echo "Graphs pulled successfully, deleting server $HOSTNAME..."
  upctl server stop --wait $HOSTNAME
  upctl server delete --delete-storages $HOSTNAME
}

# Run all servers in seperate processes
for REGION in $REGIONS; do
  run_benchmark $REGION &
  sleep 1
done

echo "Waiting for jobs to finish..."
wait
echo "Done..."
