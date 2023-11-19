#!/usr/bin/env bash


# Safety settings.
set -euo pipefail
shopt -s failglob


### MODIFY BEGIN ###

mixcorr_exp_id="exp08"
mixcorr_nym_version="nym-binaries-v1.1.13"
mixcorr_exp_name="${mixcorr_exp_id}_${mixcorr_nym_version}_static-http-download"

mixcorr_nym_dir="/root/.nym"
mixcorr_root_dir="/root/mixcorr"
mixcorr_res_dir_root="${mixcorr_root_dir}/data-collection_results"

mixcorr_orchestration_dir="${mixcorr_root_dir}/data-collection_3_live-network-setup"
mixcorr_scens_dir="${mixcorr_root_dir}/data-collection_1_experiments"

mixcorr_nym_endpoints_dir="${mixcorr_root_dir}/nym_endpoints_${mixcorr_nym_version}"
mixcorr_nym_network_requester_path="${mixcorr_nym_endpoints_dir}/nym-network-requester"
mixcorr_nym_socks5_client_path="${mixcorr_nym_endpoints_dir}/nym-socks5-client"

# Specify the total number of runs to be conducted by this script for this experiment.
mixcorr_exp_runs_target=10000

# Specify the number of characters in the static file (i.e., its size) to be generated
# at the start of each experiment run that will be downloaded by all curl clients on the
# respective other endpoints instance. The final file will be 10 characters shorter that
# will be filled with the run-respective ID.
# Set to: 1 MiB.
mixcorr_file_http_chars_num=1048576

# Specify private Nym gateway for endpoints to use during the experiment. We export below
# variables such that any child process of this script will see them as environment variables.
# The relevant keys to identify our private gateway are expected to be passed as arguments 1
# and 2 when calling this script, e.g.:
#     ./5-exp08-run-experiments-nym-endpoints.sh BhUaeKhEpNkR3itQXNMLwh3PzKxQJr1EYQBpUXYPYvx 7V1BpWvKCMjjmHUitw9WQUfXbD3iC2dDx9mLzbYc2t7t
export mixcorr_static_private_gateway_identity_key="${1}"
export mixcorr_static_private_gateway_sphinx_key="${2}"
export mixcorr_static_private_gateway_owner="SET_TO_WALLET_ADDRESS_USED_DURING_GATEWAY_SETUP"
export mixcorr_static_private_gateway_stake="100000000"
export mixcorr_static_private_gateway_location="Milky Way, Universe"
export mixcorr_static_private_gateway_host="SET_TO_GATEWAY_IP"
export mixcorr_static_private_gateway_mix_host="SET_TO_GATEWAY_IP:1789"
export mixcorr_static_private_gateway_clients_port="9000"
export mixcorr_static_private_gateway_version="1.1.13"

### MODIFY END ###


# Capture time of invoking this script and generate log file name.
ts_file="+%Y-%m-%d_%H-%M-%S"
run_time=$(date "${ts_file}")

# Define output directory for this experiment.
instance_hostname=$( uname --nodename )
mixcorr_res_dir="${mixcorr_res_dir_root}/${run_time}_${instance_hostname}_${mixcorr_exp_name}"
mkdir -p "${mixcorr_res_dir}"

log_file="${mixcorr_res_dir}/logs_5-exp08-run-experiments-nym-endpoints.log"
touch "${log_file}"

cp "${0}" "${mixcorr_res_dir}/" &>> "${log_file}"


# Logs line (arg 1) to STDOUT and log file prefixed with
# the current timestamp (YYYY/MM/DD_HH:MM:SS.NNNNNNNNN).
ts_log="+%Y/%m/%d_%H:%M:%S.%N"
log_ts () {
    ts=$( date "${ts_log}" )
    printf "[${ts}] ${1}\n"
    printf "[${ts}] ${1}\n" &>> "${log_file}"
}


# Logs line (arg 2) to supplied log file (arg 1) prefixed with
# the current timestamp (YYYY/MM/DD_HH:MM:SS.NNNNNNNNN).
log_to_file_ts () {
    ts=$( date "${ts_log}" )
    printf "[${ts}] ${2}\n" &>> "${1}"
}


# Kill any leftover processes and prior experiment state before proceeding
# to the next experiment run (that requires a "clean slate" instance).
killall_run () {

    ( killall --quiet nym-client nym-socks5-client nym-network-requester curl || true ) &>> "${log_file}"
    ( kill $( ps aux | grep "[p]ython3 -m http.server" | awk '{print $2}' ) 2> /dev/null || true ) &>> "${log_file}"

    sleep 2

    ( killall --quiet nym-client nym-socks5-client nym-network-requester curl || true ) &>> "${log_file}"
    ( kill $( ps aux | grep "[p]ython3 -m http.server" | awk '{print $2}' ) 2> /dev/null || true ) &>> "${log_file}"

    log_ts "[run#${mixcorr_exp_run}] Logging network information after killing processes..."
    ss -tlpn &>> "${log_file}"
    printf "\n" &>> "${log_file}"
}


# Run requester_server part of each run.
run_requester_server () {

    log_ts "[run#${mixcorr_exp_run}] Running initialization steps for requester_server now..."
    mixcorr_network_requester_init=$( "${mixcorr_nym_network_requester_path}" init --id "network_requester_${mixcorr_exp_run}" --gateway "${mixcorr_static_private_gateway_identity_key}" 2>&1 )
    log_to_file_ts "${run_res_requester_server_log_file}" "Initialization for network_requester_${mixcorr_exp_run}:\n${mixcorr_network_requester_init}\n"

    mixcorr_network_requester_addr=$( echo "${mixcorr_network_requester_init}" | grep "The address of this client is: " | grep -o -E "[[:alnum:]]+\.[[:alnum:]]+\@[[:alnum:]]+" )
    mixcorr_network_requester_identity_key=$( echo "${mixcorr_network_requester_addr}" | grep -o -E "^[[:alnum:]]+" )
    log_to_file_ts "${run_res_requester_server_log_file}" "Following nym-network-requester address was generated and matched for network_requester_${mixcorr_exp_run}:\n${mixcorr_network_requester_addr}\n"
    log_to_file_ts "${run_res_requester_server_log_file}" "Of this address, the identity part for our tracking purposes for network_requester_${mixcorr_exp_run} is:\n${mixcorr_network_requester_identity_key}\n"

    log_to_file_ts "${run_res_requester_server_log_file}" "Saving '${mixcorr_network_requester_addr}' in ${run_res_dir}/address_responder_nym-network-requester.txt...\n"
    printf "${mixcorr_network_requester_addr}\n" > "${run_res_dir}/address_responder_nym-network-requester.txt"

    log_to_file_ts "${run_res_requester_server_log_file}" "Marking '127.0.0.1' as allowed destination for nym-network-requester in ${mixcorr_nym_dir}/service-providers/network-requester/allowed.list...\n"
    printf "127.0.0.1\n" > "${mixcorr_nym_dir}/service-providers/network-requester/allowed.list"

    log_to_file_ts "${run_res_requester_server_log_file}" "Preparing ${run_res_webserver_dir} and HTTP document for Python3 webserver...\n"
    cp "${mixcorr_res_dir}/document_to_download.txt" "${run_res_webserver_dir}/document.txt" &>> "${run_res_requester_server_log_file}"
    ls -la "${run_res_webserver_dir}/document.txt" &>> "${run_res_requester_server_log_file}"
    printf "\n" >> "${run_res_requester_server_log_file}"
    printf "_run-${mixcorr_exp_run}" >> "${run_res_webserver_dir}/document.txt"
    ls -la "${run_res_webserver_dir}/document.txt" &>> "${run_res_requester_server_log_file}"
    printf "\n" >> "${run_res_requester_server_log_file}"

    log_to_file_ts "${run_res_requester_server_log_file}" "Starting nym-network-requester network_requester_${mixcorr_exp_run}..."
    ( ( "${mixcorr_nym_network_requester_path}" run --id "network_requester_${mixcorr_exp_run}" ) &>> "${run_res_requester_server_log_file}" ) &

    mixcorr_nym_network_requester_ready=$( ( grep -c "> All systems go. Press CTRL-C to stop the server." "${run_res_requester_server_log_file}" ) || true )
    while [[ "${mixcorr_nym_network_requester_ready}" -ne 1 ]]; do
        log_to_file_ts "${run_res_requester_server_log_file}" "Sleeping for 1 second, because mixcorr_nym_network_requester_ready=${mixcorr_nym_network_requester_ready} != 1\n"
        sleep 1
        mixcorr_nym_network_requester_ready=$( ( grep -c "> All systems go. Press CTRL-C to stop the server." "${run_res_requester_server_log_file}" ) || true )
    done

    log_to_file_ts "${run_res_requester_server_log_file}" "Starting the python3-based webserver process..."
    ( ( python3 -m http.server --bind 127.0.0.1 --directory "${run_res_webserver_dir}" 9909 ) &>> "${run_res_requester_server_log_file}" ) &
    printf "\n" >> "${run_res_requester_server_log_file}"

    sleep 2

    log_ts "[run#${mixcorr_exp_run}] All scripts for requester_server completed!"
}


# Run socks5_client part of each run.
run_socks5_client () {

    log_ts "[run#${mixcorr_exp_run}] Running initialization steps for socks5-client now..."
    mixcorr_provider_identity_key=$( cat "${run_res_dir}/address_responder_nym-network-requester.txt" )
    mixcorr_socks5_client_init=$( "${mixcorr_nym_socks5_client_path}" init --id "socks5-client_${mixcorr_exp_run}" --gateway "${mixcorr_static_private_gateway_identity_key}" --provider "${mixcorr_provider_identity_key}" 2>&1 )
    log_to_file_ts "${run_res_socks5_client_log_file}" "Initialization for socks5-client_${mixcorr_exp_run}:\n${mixcorr_socks5_client_init}\n"

    mixcorr_socks5_client_addr=$( echo "${mixcorr_socks5_client_init}" | grep "The address of this client is: " | grep -o -E "[[:alnum:]]+\.[[:alnum:]]+\@[[:alnum:]]+" )
    mixcorr_socks5_client_identity_key=$( echo "${mixcorr_socks5_client_addr}" | grep -o -E "^[[:alnum:]]+" )
    log_to_file_ts "${run_res_socks5_client_log_file}" "Following nym-socks5-client address was generated and matched for socks5-client_${mixcorr_exp_run}:\n${mixcorr_socks5_client_addr}\n"
    log_to_file_ts "${run_res_socks5_client_log_file}" "Of this address, the identity part for our tracking purposes for socks5-client_${mixcorr_exp_run} is:\n${mixcorr_socks5_client_identity_key}\n"

    log_to_file_ts "${run_res_socks5_client_log_file}" "Saving '${mixcorr_socks5_client_addr}' in ${run_res_dir}/address_initiator_nym-socks5-client.txt...\n"
    printf "${mixcorr_socks5_client_addr}\n" > "${run_res_dir}/address_initiator_nym-socks5-client.txt"

    log_to_file_ts "${run_res_socks5_client_log_file}" "Starting nym-socks5-client socks5-client_${mixcorr_exp_run}...\n"
    ( ( "${mixcorr_nym_socks5_client_path}" run --id "socks5-client_${mixcorr_exp_run}" ) &>> "${run_res_socks5_client_log_file}" ) &

    mixcorr_nym_socks5_client_ready=$( ( grep -c "> Serving Connections..." "${run_res_socks5_client_log_file}" ) || true )
    log_to_file_ts "${run_res_socks5_client_log_file}" "mixcorr_nym_socks5_client_ready=${mixcorr_nym_socks5_client_ready}"
    while [[ "${mixcorr_nym_socks5_client_ready}" -ne 1 ]]; do
        log_to_file_ts "${run_res_socks5_client_log_file}" "Sleeping for 1 second, because mixcorr_nym_socks5_client_ready=${mixcorr_nym_socks5_client_ready} != 1\n"
        sleep 1
        mixcorr_nym_socks5_client_ready=$( ( grep -c "> Serving Connections..." "${run_res_socks5_client_log_file}" ) || true )
    done

    log_to_file_ts "${run_res_socks5_client_log_file}" "Logging network information on started processes..."
    ss -tlpn &>> "${run_res_socks5_client_log_file}"
    printf "\n" &>> "${run_res_socks5_client_log_file}"

    log_ts "[run#${mixcorr_exp_run}] All scripts for socks5-client completed!"
}


# Conduct curl download that makes up the core of each run after endpoints
# have been started properly and are ready for use.
conduct_curl_download () {

    log_ts "[run#${mixcorr_exp_run}] Downloading target HTTP file via socks5-client now..."

    # Timestamp: Seconds since UNIX Epoch (Jan 01, 1970) with current nanoseconds appended.
    ts_curl_download="+%s%N"
    start=$( date "${ts_curl_download}" )

    # Header 'Accept-Encoding: identity' ensures that no compression is applied.
    ( curl --proxy socks5h://127.0.0.1:1080 --header "Accept-Encoding: identity" --output "${run_res_curl_client_dir}/document.txt" http://127.0.0.1:9909/document.txt ) &>> "${run_res_curl_log_file}"

    end=$( date "${ts_curl_download}" )

    cat << EOF > "${run_res_dir}/experiment.json"
{
    "start": ${start},
    "end": ${end}
}
EOF

    sleep 5
    log_ts "[run#${mixcorr_exp_run}] Download of run ${mixcorr_exp_run} completed or aborted (successful download check pending)!"
}


# Check if curl download run succeeded or failed.
verify_run_completion_status () {

    log_ts "[run#${mixcorr_exp_run}] Verifying whether experiment download was a success..."

    file_curl_client="${run_res_curl_client_dir}/document.txt"
    file_webserver="${run_res_webserver_dir}/document.txt"
    network_requester_log_success=$( ( grep -c "Proxy for 127.0.0.1:9909 is finished" "${run_res_requester_server_log_file}" ) || true )
    socks5_client_log_success=$( ( grep -c "Proxy for 127.0.0.1:9909 is finished" "${run_res_socks5_client_log_file}" ) || true )

    cur_run_successful="no"
    if [[ "${network_requester_log_success}" -eq 1 ]] && [[ "${socks5_client_log_success}" -eq 1 ]]; then

        if cmp --silent "${file_curl_client}" "${file_webserver}"; then
            log_ts "[run#${mixcorr_exp_run}] Download successful, files match!"
            ( sha512sum "${file_curl_client}" "${file_webserver}" >> "${run_res_dir}/SUCCEEDED" ) &>> "${log_file}"
            printf "\n" >> "${run_res_dir}/SUCCEEDED"
            cur_run_successful="yes"
        else
            log_ts "[run#${mixcorr_exp_run}] Download failed, files don't match!"
            ( sha512sum "${file_curl_client}" "${file_webserver}" >> "${run_res_dir}/FAILED" ) &>> "${log_file}"
            printf "\n" >> "${run_res_dir}/FAILED"
        fi
    else
        log_ts "[run#${mixcorr_exp_run}] Download failed, proxy did not even complete!"
        printf "Proxy between curl=>socks5-client and network-requester=>webserver did not complete\n" >> "${run_res_dir}/FAILED"
    fi
    printf "\n" >> "${log_file}"

    if [[ "${cur_run_successful}" == "yes" ]]; then
        mixcorr_exp_runs_successful=$(( "${mixcorr_exp_runs_successful}" + 1 ))
    fi
}


log_ts "Script '5-exp08-run-experiments-nym-endpoints.sh' invoked with the following variables:"
log_ts "    - run_time='${run_time}'"
log_ts "    - log_file='${log_file}'"
log_ts "    - instance_hostname='${instance_hostname}'"
log_ts "    - mixcorr_exp_id='${mixcorr_exp_id}'"
log_ts "    - mixcorr_nym_version='${mixcorr_nym_version}'"
log_ts "    - mixcorr_exp_name='${mixcorr_exp_name}'"
log_ts "    - mixcorr_nym_dir='${mixcorr_nym_dir}'"
log_ts "    - mixcorr_root_dir='${mixcorr_root_dir}'"
log_ts "    - mixcorr_res_dir_root='${mixcorr_res_dir_root}'"
log_ts "    - mixcorr_res_dir='${mixcorr_res_dir}'"
log_ts "    - mixcorr_orchestration_dir='${mixcorr_orchestration_dir}'"
log_ts "    - mixcorr_scens_dir='${mixcorr_scens_dir}'"
log_ts "    - mixcorr_nym_endpoints_dir='${mixcorr_nym_endpoints_dir}'"
log_ts "    - mixcorr_nym_network_requester_path='${mixcorr_nym_network_requester_path}'"
log_ts "    - mixcorr_nym_socks5_client_path='${mixcorr_nym_socks5_client_path}'"
log_ts "    - mixcorr_file_http_chars_num='${mixcorr_file_http_chars_num}'"
log_ts "    - mixcorr_static_private_gateway_owner='${mixcorr_static_private_gateway_owner}'"
log_ts "    - mixcorr_static_private_gateway_stake='${mixcorr_static_private_gateway_stake}'"
log_ts "    - mixcorr_static_private_gateway_location='${mixcorr_static_private_gateway_location}'"
log_ts "    - mixcorr_static_private_gateway_host='${mixcorr_static_private_gateway_host}'"
log_ts "    - mixcorr_static_private_gateway_mix_host='${mixcorr_static_private_gateway_mix_host}'"
log_ts "    - mixcorr_static_private_gateway_clients_port='${mixcorr_static_private_gateway_clients_port}'"
log_ts "    - mixcorr_static_private_gateway_identity_key='${mixcorr_static_private_gateway_identity_key}'"
log_ts "    - mixcorr_static_private_gateway_sphinx_key='${mixcorr_static_private_gateway_sphinx_key}'"
log_ts "    - mixcorr_static_private_gateway_version='${mixcorr_static_private_gateway_version}'"
printf "\n" &>> "${log_file}"


log_ts "Logging system information..."
uname -a &>> "${log_file}"
printf "\n" &>> "${log_file}"
lshw -short -sanitize &>> "${log_file}"
printf "\n" &>> "${log_file}"
lscpu &>> "${log_file}"
printf "\n" &>> "${log_file}"
lsblk &>> "${log_file}"
printf "\n" &>> "${log_file}"
df -hT &>> "${log_file}"
printf "\n" &>> "${log_file}"

log_ts "Logging git status of ${mixcorr_orchestration_dir}..."
git -C "${mixcorr_orchestration_dir}" status &>> "${log_file}"
printf "\n" &>> "${log_file}"

log_ts "Logging git status of ${mixcorr_scens_dir}..."
git -C "${mixcorr_scens_dir}" status &>> "${log_file}"
printf "\n" &>> "${log_file}"

log_ts "Generating $(( ${mixcorr_file_http_chars_num} - 10 )) random characters for experiment document of size ${mixcorr_file_http_chars_num} Bytes (10 remaining characters will be run-specific ID)..."
( pwgen -sync $(( ${mixcorr_file_http_chars_num} - 10 )) 1 > "${mixcorr_res_dir}/document_to_download.txt" ) &>> "${log_file}"
truncate -s -1 "${mixcorr_res_dir}/document_to_download.txt" &>> "${log_file}"
ls -la "${mixcorr_res_dir}/document_to_download.txt" &>> "${log_file}"
printf "\n" &>> "${log_file}"


mixcorr_exp_runs_successful=0
mixcorr_exp_runs_attempted=1

while (( "${mixcorr_exp_runs_successful}" < "${mixcorr_exp_runs_target}" )); do

    # Prepare this run's ID.
    printf -v mixcorr_exp_run "%05d" "${mixcorr_exp_runs_attempted}"

    log_ts "[run#${mixcorr_exp_run}] Attempting experiment run ${mixcorr_exp_run}..."

    log_ts "[run#${mixcorr_exp_run}] First, remove possible leftover processes from previous run..."
    killall_run

    # Prepare paths for this run.
    run_res_dir="${mixcorr_res_dir}/${mixcorr_exp_id}_curl_run_${mixcorr_exp_run}"
    run_res_nym_dir="${run_res_dir}/nym_folder"
    run_res_webserver_dir="${run_res_dir}/webserver_directory"
    run_res_curl_client_dir="${run_res_dir}/curl_client_directory"
    run_res_requester_server_log_file="${run_res_dir}/logs_requester-server_run-${mixcorr_exp_run}.log"
    run_res_socks5_client_log_file="${run_res_dir}/logs_socks5-client_run-${mixcorr_exp_run}.log"
    run_res_curl_log_file="${run_res_dir}/logs_curl_run-${mixcorr_exp_run}.log"

    log_ts "[run#${mixcorr_exp_run}] Creating result folder ${run_res_dir} with basic folder and file structure for this run..."
    mkdir -p "${run_res_dir}" &>> "${log_file}"
    mkdir -p "${run_res_nym_dir}" &>> "${log_file}"
    mkdir -p "${run_res_webserver_dir}" &>> "${log_file}"
    mkdir -p "${run_res_curl_client_dir}" &>> "${log_file}"
    touch "${run_res_requester_server_log_file}" &>> "${log_file}"
    touch "${run_res_socks5_client_log_file}" &>> "${log_file}"
    touch "${run_res_curl_log_file}" &>> "${log_file}"

    # Run requester_server processes of this experiment run.
    run_requester_server

    # Run socks5_client processes of this experiment run.
    run_socks5_client

    # Download file via HTTP using curl.
    conduct_curl_download

    log_ts "[run#${mixcorr_exp_run}] Stopping all processes exclusive to this run after download concluded..."
    killall_run

    log_ts "[run#${mixcorr_exp_run}] Saving ${mixcorr_nym_dir} folders to ${run_res_nym_dir}, then deleting ${mixcorr_nym_dir}..."
    printf "\n" >> "${run_res_requester_server_log_file}"
    rsync -av "${mixcorr_nym_dir}"/ "${run_res_nym_dir}" &>> "${run_res_requester_server_log_file}"
    printf "\n" >> "${run_res_requester_server_log_file}"
    rm -rf "${mixcorr_nym_dir}" &>> "${run_res_requester_server_log_file}"

    # Check if run succeeded or failed.
    verify_run_completion_status

    log_ts "[run#${mixcorr_exp_run}] We have run ${mixcorr_exp_runs_attempted} so far, of which ${mixcorr_exp_runs_successful} have been successful. Our target number of successful runs is ${mixcorr_exp_runs_target} ($(( ${mixcorr_exp_runs_target} - ${mixcorr_exp_runs_successful} )) to go).\n"

    # Increment the run counter.
    mixcorr_exp_runs_attempted=$(( "${mixcorr_exp_runs_attempted}" + 1 ))

done


printf "\n" &>> "${log_file}"
log_ts "Completed ${mixcorr_exp_runs_target} runs for experiment ${mixcorr_exp_name}! Exiting."
