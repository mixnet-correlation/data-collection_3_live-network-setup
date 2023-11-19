#!/usr/bin/env bash


# Safety settings.
set -euo pipefail
shopt -s failglob


### MODIFY BEGIN ###

exp_id="exp08"
exp_rust_version="1.68.2"
exp_nym_version="nym-binaries-v1.1.13"
exp_name="${exp_id}_${exp_nym_version}_static-http-download"
read -p "Provide the address of the Nym wallet to use for this experiment: " exp_nym_wallet_address

server_type="ccx22"
server_name="mixcorr-nym-endpoints-${server_type}-${exp_id}"
server_location="nbg1"
server_image="ubuntu-22.04"
read -p "[${server_name}] Specify name of Hetzner firewall to apply to this instance: " server_firewall
read -p "[${server_name}] Specify name(s) of SSH key(s) as stored on Hetzner to use for access to instance: " server_sshkey
server_snapshot_name="mixcorr-endpoints-${server_type}-${exp_id}"

server_root_dir="/root/mixcorr"

exp_orchestration_repo_tag="main"
server_orchestration_repo="https://github.com/mixnet-correlation/data-collection_3_live-network-setup.git"
server_orchestration_dir="${server_root_dir}/data-collection_3_live-network-setup"

exp_scens_repo_tag="main"
server_scens_repo="https://github.com/mixnet-correlation/data-collection_1_experiments.git"
server_scens_dir="${server_root_dir}/data-collection_1_experiments"

server_nym_endpoints_dir="${server_root_dir}/nym_endpoints_${exp_nym_version}"
server_nym_network_requester_path="${server_nym_endpoints_dir}/nym-network-requester"
server_nym_socks5_client_path="${server_nym_endpoints_dir}/nym-socks5-client"

printf "\n"

### MODIFY END ###


# Capture time of invoking this script and generate log file name.
ts_file="+%Y-%m-%d_%H-%M-%S"
run_time=$(date "${ts_file}")
log_file="${exp_id}_${run_time}_2-provision-nym-endpoints-hetzner.log"
touch "${log_file}"


# Logs line (arg 1) to STDOUT and log file prefixed with
# the current timestamp (YYYY/MM/DD_HH:MM:SS.NNNNNNNNN).
ts_log="+%Y/%m/%d_%H:%M:%S.%N"
log_ts () {
    ts=$(date "${ts_log}")
    printf "[${ts}] ${1}\n"
    printf "[${ts}] ${1}\n" &>> "${log_file}"
}


# Executes command (arg 1) on remote server with xtrace option enabled for
# command traceability. Appends newline to log file after each command.
remote_cmd () {
    hcloud server ssh "${server_name}" "set -x && ${1}" &>> "${log_file}"
    printf "\n" &>> "${log_file}"
}


log_ts "Script '2-provision-nym-endpoints-hetzner.sh' invoked with the following variables:"
log_ts "    - run_time='${run_time}'"
log_ts "    - log_file='${log_file}'"
log_ts "    - exp_id='${exp_id}'"
log_ts "    - exp_rust_version='${exp_rust_version}'"
log_ts "    - exp_nym_version='${exp_nym_version}'"
log_ts "    - exp_name='${exp_name}'"
log_ts "    - exp_nym_wallet_address='${exp_nym_wallet_address}'"
log_ts "    - server_type='${server_type}'"
log_ts "    - server_name='${server_name}'"
log_ts "    - server_location='${server_location}'"
log_ts "    - server_image='${server_image}'"
log_ts "    - server_firewall='${server_firewall}'"
log_ts "    - server_sshkey='${server_sshkey}'"
log_ts "    - server_root_dir='${server_root_dir}'"
log_ts "    - exp_orchestration_repo_tag='${exp_orchestration_repo_tag}'"
log_ts "    - server_orchestration_repo='${server_orchestration_repo}'"
log_ts "    - server_orchestration_dir='${server_orchestration_dir}'"
log_ts "    - exp_scens_repo_tag='${exp_scens_repo_tag}'"
log_ts "    - server_scens_repo='${server_scens_repo}'"
log_ts "    - server_scens_dir='${server_scens_dir}'"
log_ts "    - server_nym_endpoints_dir='${server_nym_endpoints_dir}'"
log_ts "    - server_nym_network_requester_path='${server_nym_network_requester_path}'"
log_ts "    - server_nym_socks5_client_path='${server_nym_socks5_client_path}'"
printf "\n" &>> "${log_file}"


log_ts "Creating instance..."
hcloud server create \
    --start-after-create \
    --name "${server_name}" \
    --type "${server_type}" \
    --location "${server_location}" \
    --image "${server_image}" \
    --firewall "${server_firewall}" \
    --ssh-key "${server_sshkey}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
sleep 15

server_ip=$( hcloud server ip "${server_name}" ) &>> "${log_file}"
log_ts "Created instance with IP ${server_ip}"

log_ts "Replacing entries for ${server_ip} in your ~/.ssh/known_hosts with the new values to avoid authenticity warnings..."
ssh-keygen -R "${server_ip}" &>> "${log_file}"
ssh-keyscan -t ed25519 "${server_ip}" &>> "${log_file}" >> ~/.ssh/known_hosts
printf "\n" &>> "${log_file}"
sleep 1

log_ts "Updating and upgrading..."
remote_cmd "chown -R root:root /root && chmod 0700 /root/.ssh && chmod 0600 /root/.ssh/authorized_keys"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get update --yes"
sleep 1
hcloud server reboot "${server_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
sleep 15
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get update --yes"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --with-new-pkgs"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes --purge"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get clean --yes"
sleep 1
hcloud server reboot "${server_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
sleep 15
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get update --yes"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --with-new-pkgs"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes --purge"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get clean --yes"
sleep 1
hcloud server reboot "${server_name}" &>> "${log_file}"
printf "\n\n" &>> "${log_file}"
sleep 15

log_ts "Installing required packages..."
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get install --yes pkg-config build-essential libssl-dev curl jq git python3 lshw htop tree tmux pwgen"
sleep 1
hcloud server reboot "${server_name}" &>> "${log_file}"
printf "\n\n" &>> "${log_file}"
sleep 15

log_ts "Disabling automatic updates and upgrades..."
remote_cmd "grep -rin 'periodic' /etc/apt/apt.conf.d | sort -d"
remote_cmd "apt-config dump APT::Periodic::Update-Package-Lists"
remote_cmd "apt-config dump APT::Periodic::Unattended-Upgrade"
remote_cmd "sed --in-place 's/APT::Periodic::Update-Package-Lists \"1\"/APT::Periodic::Update-Package-Lists \"0\"/g' /etc/apt/apt.conf.d/20auto-upgrades"
remote_cmd "sed --in-place 's/APT::Periodic::Unattended-Upgrade \"1\"/APT::Periodic::Unattended-Upgrade \"0\"/g' /etc/apt/apt.conf.d/20auto-upgrades"
remote_cmd "grep -rin 'periodic' /etc/apt/apt.conf.d | sort -d"
remote_cmd "apt-config dump APT::Periodic::Update-Package-Lists"
remote_cmd "apt-config dump APT::Periodic::Unattended-Upgrade"
sleep 1

log_ts "Installing Rust in version ${exp_rust_version}..."
remote_cmd "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /root/rustup-init.sh"
remote_cmd "chmod 0700 /root/rustup-init.sh && sh /root/rustup-init.sh --verbose -y --default-toolchain ${exp_rust_version}"
remote_cmd "source /root/.cargo/env && rustup show && rustc --version"
sleep 1

log_ts "Creating root directory ${server_root_dir} for experiments..."
remote_cmd "cd && mkdir -p ${server_root_dir} && ls -lah /root && tree -a ${server_root_dir}"

log_ts "Cloning orchestration repository in version ${exp_orchestration_repo_tag} as ${server_orchestration_dir} into ${server_root_dir}..."
remote_cmd "cd ${server_root_dir} && git clone ${server_orchestration_repo} ${server_orchestration_dir}"
remote_cmd "cd ${server_orchestration_dir} && git reset --hard && git pull && git checkout ${exp_orchestration_repo_tag}"
remote_cmd "cd ${server_orchestration_dir} && chmod 0700 *.sh && git status && ls -lah && tree -a"

log_ts "Cloning scenarios repository in version ${exp_scens_repo_tag} as ${server_scens_dir} into ${server_root_dir}..."
remote_cmd "cd ${server_root_dir} && git clone ${server_scens_repo} ${server_scens_dir}"
remote_cmd "cd ${server_scens_dir} && git reset --hard && git pull && git checkout ${exp_scens_repo_tag}"
remote_cmd "cd ${server_scens_dir} && git status && ls -lah && tree -a"

log_ts "Cloning Nym repository in version ${exp_nym_version} as ${server_nym_endpoints_dir} into ${server_root_dir}..."
remote_cmd "cd ${server_root_dir} && git clone https://github.com/nymtech/nym.git ${server_nym_endpoints_dir}"
remote_cmd "cd ${server_nym_endpoints_dir} && git reset --hard && git pull && git checkout tags/${exp_nym_version}"
remote_cmd "cd ${server_nym_endpoints_dir} && git status"

log_ts "Final cycle of updating and upgrading..."
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get update --yes"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --with-new-pkgs"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes --purge"
remote_cmd "DEBIAN_FRONTEND=noninteractive apt-get clean --yes"
sleep 1
hcloud server reboot "${server_name}" &>> "${log_file}"
printf "\n" &>> "${log_file}"
sleep 15

log_ts "Listing installed packages..."
remote_cmd "DEBIAN_FRONTEND=noninteractive apt list --installed"

log_ts "Logging system information..."
remote_cmd "uname -a"
remote_cmd "lshw -short -sanitize"
remote_cmd "lscpu"
remote_cmd "lsblk"
remote_cmd "df -hT"

log_ts "Applying Nym patches for ${exp_name} to endpoints Nym code base at ${server_nym_endpoints_dir}..."
remote_cmd "cd ${server_nym_endpoints_dir} && git status"
remote_cmd "cd ${server_nym_endpoints_dir} && patch -i ${server_scens_dir}/${exp_name}/endpoints/*.patch -p1"
remote_cmd "cd ${server_nym_endpoints_dir} && git status && git diff"
sleep 1

log_ts "Compiling nym-network-requester at ${server_nym_endpoints_dir} with patches for ${exp_name} and moving its binary to ${server_nym_network_requester_path}..."
remote_cmd "source /root/.cargo/env && cd ${server_nym_endpoints_dir} && rustup show && git status && cargo build --manifest-path ${server_nym_endpoints_dir}/service-providers/network-requester/Cargo.toml --release"
remote_cmd "mv ${server_nym_endpoints_dir}/target/release/nym-network-requester ${server_nym_network_requester_path} && chmod 0700 ${server_nym_network_requester_path}"

log_ts "Compiling nym-socks5-client at ${server_nym_endpoints_dir} with patches for ${exp_name} and moving its binary to ${server_nym_socks5_client_path}..."
remote_cmd "source /root/.cargo/env && cd ${server_nym_endpoints_dir} && rustup show && git status && cargo build --manifest-path ${server_nym_endpoints_dir}/clients/socks5/Cargo.toml --release"
remote_cmd "mv ${server_nym_endpoints_dir}/target/release/nym-socks5-client ${server_nym_socks5_client_path} && chmod 0700 ${server_nym_socks5_client_path}"
sleep 1

log_ts "Showing up to three levels of content of ${server_root_dir}..."
remote_cmd "tree -a -L 3 ${server_root_dir}"
sleep 5

log_ts "Shutting down endpoints instance ${server_name}..."
hcloud --poll-interval 2000ms server shutdown "${server_name}" &>> "${log_file}"
sleep 15
printf "\n" &>> "${log_file}"

log_ts "Taking snapshot '${server_snapshot_name}' of endpoints instance ${server_name}..."
hcloud --poll-interval 2000ms server create-image --type "snapshot" --description "${server_snapshot_name}" "${server_name}" &>> "${log_file}"
sleep 1
printf "\n" &>> "${log_file}"


printf "\n" &>> "${log_file}"
log_ts "Provisioned ${server_name} instance and took snapshot ${server_snapshot_name}! Exiting."
