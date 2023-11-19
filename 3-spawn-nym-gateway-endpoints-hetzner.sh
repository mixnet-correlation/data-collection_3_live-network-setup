#!/usr/bin/env bash


# Safety settings.
set -euo pipefail
shopt -s failglob


### MODIFY BEGIN ###

mixcorr_exp_id="exp08"

mixcorr_server_type="ccx22"
mixcorr_server_location="nbg1"
read -p "Specify name of Hetzner firewall to apply to instances: " mixcorr_server_firewall
read -p "Specify name(s) of SSH key(s) as stored on Hetzner to use for access to instances: " mixcorr_server_sshkey

mixcorr_gateway_server_name="mixcorr-nym-gateway-${mixcorr_server_type}-${mixcorr_exp_id}"
read -p "Specify IPv4 address of the gateway instance: " mixcorr_gateway_server_primary_ipv4
read -p "Specify the name that you assigned to the IPv4 address of the gateway instance: " mixcorr_gateway_server_primary_ipv4_name
mixcorr_gateway_server_image_description="mixcorr-gateway-${mixcorr_server_type}-${mixcorr_exp_id}"

mixcorr_endpoints_server_one_name="mixcorr-nym-endpoints-${mixcorr_server_type}-${mixcorr_exp_id}-one"
mixcorr_endpoints_server_two_name="mixcorr-nym-endpoints-${mixcorr_server_type}-${mixcorr_exp_id}-two"
mixcorr_endpoints_server_three_name="mixcorr-nym-endpoints-${mixcorr_server_type}-${mixcorr_exp_id}-three"
mixcorr_endpoints_server_four_name="mixcorr-nym-endpoints-${mixcorr_server_type}-${mixcorr_exp_id}-four"
mixcorr_endpoints_server_five_name="mixcorr-nym-endpoints-${mixcorr_server_type}-${mixcorr_exp_id}-five"
mixcorr_endpoints_server_image_description="mixcorr-endpoints-${mixcorr_server_type}-${mixcorr_exp_id}"

printf "\n"

### MODIFY END ###


# Capture time of invoking this script and generate log file name.
ts_file="+%Y-%m-%d_%H-%M-%S"
run_time=$(date "${ts_file}")
log_file="${mixcorr_exp_id}_${run_time}_3-spawn-nym-gateway-endpoints-hetzner.log"
touch "${log_file}"


# Logs line (arg 1) to STDOUT and log file prefixed with
# the current timestamp (YYYY/MM/DD_HH:MM:SS.NNNNNNNNN).
ts_log="+%Y/%m/%d_%H:%M:%S.%N"
log_ts () {
    ts=$(date "${ts_log}")
    printf "[${ts}] ${1}\n"
    printf "[${ts}] ${1}\n" &>> "${log_file}"
}


log_ts "Script '3-spawn-nym-gateway-endpoints-hetzner.sh' invoked with the following variables:"
log_ts "    - run_time='${run_time}'"
log_ts "    - log_file='${log_file}'"
log_ts "    - mixcorr_exp_id='${mixcorr_exp_id}'"
log_ts "    - mixcorr_server_type='${mixcorr_server_type}'"
log_ts "    - mixcorr_server_location='${mixcorr_server_location}'"
log_ts "    - mixcorr_server_firewall='${mixcorr_server_firewall}'"
log_ts "    - mixcorr_server_sshkey='${mixcorr_server_sshkey}'"
log_ts "    - mixcorr_gateway_server_name='${mixcorr_gateway_server_name}'"
log_ts "    - mixcorr_gateway_server_primary_ipv4='${mixcorr_gateway_server_primary_ipv4}'"
log_ts "    - mixcorr_gateway_server_primary_ipv4_name='${mixcorr_gateway_server_primary_ipv4_name}'"
log_ts "    - mixcorr_gateway_server_image_description='${mixcorr_gateway_server_image_description}'"
log_ts "    - mixcorr_endpoints_server_one_name='${mixcorr_endpoints_server_one_name}'"
log_ts "    - mixcorr_endpoints_server_two_name='${mixcorr_endpoints_server_two_name}'"
log_ts "    - mixcorr_endpoints_server_three_name='${mixcorr_endpoints_server_three_name}'"
log_ts "    - mixcorr_endpoints_server_four_name='${mixcorr_endpoints_server_four_name}'"
log_ts "    - mixcorr_endpoints_server_five_name='${mixcorr_endpoints_server_five_name}'"
log_ts "    - mixcorr_endpoints_server_image_description='${mixcorr_endpoints_server_image_description}'"
printf "\n" &>> "${log_file}"


log_ts "Finding image ID for snapshot with description '${mixcorr_gateway_server_image_description}'..."
mixcorr_gateway_server_image_id=$( hcloud image list --type "snapshot" --output "columns=id,description" | grep "${mixcorr_gateway_server_image_description}" | tr -s " " | cut -d " " -f 1 )
log_ts "Found image with ID '${mixcorr_gateway_server_image_id}' for snapshot with description '${mixcorr_gateway_server_image_description}'..."


log_ts "Finding image ID for snapshot with description '${mixcorr_endpoints_server_image_description}'..."
mixcorr_endpoints_server_image_id=$( hcloud image list --type "snapshot" --output "columns=id,description" | grep "${mixcorr_endpoints_server_image_description}" | tr -s " " | cut -d " " -f 1 )
log_ts "Found image with ID '${mixcorr_endpoints_server_image_id}' for snapshot with description '${mixcorr_endpoints_server_image_description}'..."


log_ts "Creating gateway instance ${mixcorr_gateway_server_name}..."
( hcloud --poll-interval 5000ms server create \
    --start-after-create \
    --name "${mixcorr_gateway_server_name}" \
    --primary-ipv4 "${mixcorr_gateway_server_primary_ipv4_name}" \
    --type "${mixcorr_server_type}" \
    --location "${mixcorr_server_location}" \
    --image "${mixcorr_gateway_server_image_id}" \
    --firewall "${mixcorr_server_firewall}" \
    --ssh-key "${mixcorr_server_sshkey}" &>> "${log_file}" ) &
mixcorr_gateway_proc_id="${!}"
sleep 1
printf "\n" &>> "${log_file}"


log_ts "Creating endpoints instance ${mixcorr_endpoints_server_one_name}..."
( hcloud --poll-interval 5000ms server create \
    --start-after-create \
    --name "${mixcorr_endpoints_server_one_name}" \
    --type "${mixcorr_server_type}" \
    --location "${mixcorr_server_location}" \
    --image "${mixcorr_endpoints_server_image_id}" \
    --firewall "${mixcorr_server_firewall}" \
    --ssh-key "${mixcorr_server_sshkey}" &>> "${log_file}" ) &
mixcorr_endpoints_server_one_proc_id="${!}"
sleep 1
printf "\n" &>> "${log_file}"

log_ts "Creating endpoints instance ${mixcorr_endpoints_server_two_name}..."
( hcloud --poll-interval 5000ms server create \
    --start-after-create \
    --name "${mixcorr_endpoints_server_two_name}" \
    --type "${mixcorr_server_type}" \
    --location "${mixcorr_server_location}" \
    --image "${mixcorr_endpoints_server_image_id}" \
    --firewall "${mixcorr_server_firewall}" \
    --ssh-key "${mixcorr_server_sshkey}" &>> "${log_file}" ) &
mixcorr_endpoints_server_two_proc_id="${!}"
sleep 1
printf "\n" &>> "${log_file}"

log_ts "Creating endpoints instance ${mixcorr_endpoints_server_three_name}..."
( hcloud --poll-interval 5000ms server create \
    --start-after-create \
    --name "${mixcorr_endpoints_server_three_name}" \
    --type "${mixcorr_server_type}" \
    --location "${mixcorr_server_location}" \
    --image "${mixcorr_endpoints_server_image_id}" \
    --firewall "${mixcorr_server_firewall}" \
    --ssh-key "${mixcorr_server_sshkey}" &>> "${log_file}" ) &
mixcorr_endpoints_server_three_proc_id="${!}"
sleep 1
printf "\n" &>> "${log_file}"

log_ts "Creating endpoints instance ${mixcorr_endpoints_server_four_name}..."
( hcloud --poll-interval 5000ms server create \
    --start-after-create \
    --name "${mixcorr_endpoints_server_four_name}" \
    --type "${mixcorr_server_type}" \
    --location "${mixcorr_server_location}" \
    --image "${mixcorr_endpoints_server_image_id}" \
    --firewall "${mixcorr_server_firewall}" \
    --ssh-key "${mixcorr_server_sshkey}" &>> "${log_file}" ) &
mixcorr_endpoints_server_four_proc_id="${!}"
sleep 1
printf "\n" &>> "${log_file}"

log_ts "Creating endpoints instance ${mixcorr_endpoints_server_five_name}..."
( hcloud --poll-interval 5000ms server create \
    --start-after-create \
    --name "${mixcorr_endpoints_server_five_name}" \
    --type "${mixcorr_server_type}" \
    --location "${mixcorr_server_location}" \
    --image "${mixcorr_endpoints_server_image_id}" \
    --firewall "${mixcorr_server_firewall}" \
    --ssh-key "${mixcorr_server_sshkey}" &>> "${log_file}" ) &
mixcorr_endpoints_server_five_proc_id="${!}"
sleep 1
printf "\n" &>> "${log_file}"


log_ts "Started all instance creation processes, now waiting for them to complete..."
wait "${mixcorr_gateway_proc_id}" "${mixcorr_endpoints_server_one_proc_id}" "${mixcorr_endpoints_server_two_proc_id}" "${mixcorr_endpoints_server_three_proc_id}" "${mixcorr_endpoints_server_four_proc_id}" "${mixcorr_endpoints_server_five_proc_id}"
log_ts "All instance creation processes completed, continuing in 15 seconds..."
sleep 15


log_ts "Replacing entries for ${mixcorr_gateway_server_primary_ipv4} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${mixcorr_gateway_server_primary_ipv4}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${mixcorr_gateway_server_primary_ipv4}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"


mixcorr_endpoints_server_one_ip=$( hcloud server ip "${mixcorr_endpoints_server_one_name}" ) &>> "${log_file}"
log_ts "Created endpoints instance ${mixcorr_endpoints_server_one_name} with IP ${mixcorr_endpoints_server_one_ip}"

log_ts "Replacing entries for ${mixcorr_endpoints_server_one_ip} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${mixcorr_endpoints_server_one_ip}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${mixcorr_endpoints_server_one_ip}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"


mixcorr_endpoints_server_two_ip=$( hcloud server ip "${mixcorr_endpoints_server_two_name}" ) &>> "${log_file}"
log_ts "Created endpoints instance ${mixcorr_endpoints_server_two_name} with IP ${mixcorr_endpoints_server_two_ip}"

log_ts "Replacing entries for ${mixcorr_endpoints_server_two_ip} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${mixcorr_endpoints_server_two_ip}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${mixcorr_endpoints_server_two_ip}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"


mixcorr_endpoints_server_three_ip=$( hcloud server ip "${mixcorr_endpoints_server_three_name}" ) &>> "${log_file}"
log_ts "Created endpoints instance ${mixcorr_endpoints_server_three_name} with IP ${mixcorr_endpoints_server_three_ip}"

log_ts "Replacing entries for ${mixcorr_endpoints_server_three_ip} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${mixcorr_endpoints_server_three_ip}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${mixcorr_endpoints_server_three_ip}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"


mixcorr_endpoints_server_four_ip=$( hcloud server ip "${mixcorr_endpoints_server_four_name}" ) &>> "${log_file}"
log_ts "Created endpoints instance ${mixcorr_endpoints_server_four_name} with IP ${mixcorr_endpoints_server_four_ip}"

log_ts "Replacing entries for ${mixcorr_endpoints_server_four_ip} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${mixcorr_endpoints_server_four_ip}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${mixcorr_endpoints_server_four_ip}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"


mixcorr_endpoints_server_five_ip=$( hcloud server ip "${mixcorr_endpoints_server_five_name}" ) &>> "${log_file}"
log_ts "Created endpoints instance ${mixcorr_endpoints_server_five_name} with IP ${mixcorr_endpoints_server_five_ip}"

log_ts "Replacing entries for ${mixcorr_endpoints_server_five_ip} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${mixcorr_endpoints_server_five_ip}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${mixcorr_endpoints_server_five_ip}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"


log_ts "Logging information about all created instances..."
hcloud server describe "${mixcorr_gateway_server_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
hcloud server describe "${mixcorr_endpoints_server_one_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
hcloud server describe "${mixcorr_endpoints_server_two_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
hcloud server describe "${mixcorr_endpoints_server_three_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
hcloud server describe "${mixcorr_endpoints_server_four_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
hcloud server describe "${mixcorr_endpoints_server_five_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"


printf "\n" &>> "${log_file}"
log_ts "Created gateway and all endpoints instances! Exiting."
