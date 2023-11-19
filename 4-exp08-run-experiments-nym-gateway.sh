#!/usr/bin/env bash


# Safety settings.
set -euo pipefail
shopt -s failglob


### MODIFY BEGIN ###

mixcorr_exp_id="exp08"
mixcorr_nym_version="nym-binaries-v1.1.13"
mixcorr_exp_name="${mixcorr_exp_id}_${mixcorr_nym_version}_static-http-download"

mixcorr_root_dir="/root/mixcorr"
mixcorr_res_dir_root="${mixcorr_root_dir}/data-collection_results"

mixcorr_orchestration_dir="${mixcorr_root_dir}/data-collection_3_live-network-setup"
mixcorr_scens_dir="${mixcorr_root_dir}/data-collection_1_experiments"

mixcorr_nym_gateway_name="mixcorr_gateway_private"
mixcorr_nym_gateway_dir="${mixcorr_root_dir}/nym_gateway_${mixcorr_nym_version}"
mixcorr_nym_gateway_path="${mixcorr_nym_gateway_dir}/nym-gateway"

### MODIFY END ###


# Capture time of invoking this script and generate log file name.
ts_file="+%Y-%m-%d_%H-%M-%S"
run_time=$(date "${ts_file}")

# Define output directory for this experiment.
instance_hostname=$( uname --nodename )
mixcorr_res_dir="${mixcorr_res_dir_root}/${run_time}_${instance_hostname}_${mixcorr_exp_name}"
mixcorr_nym_gateway_sphinxflow_dir="${mixcorr_res_dir}/gateway_sphinxflows"
mkdir -p "${mixcorr_nym_gateway_sphinxflow_dir}"

log_file="${mixcorr_res_dir}/logs_4-exp08-run-experiments-nym-gateway.log"
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


log_ts "Script '4-exp08-run-experiments-nym-gateway.sh' invoked with the following variables:"
log_ts "    - run_time='${run_time}'"
log_ts "    - log_file='${log_file}'"
log_ts "    - instance_hostname='${instance_hostname}'"
log_ts "    - mixcorr_exp_id='${mixcorr_exp_id}'"
log_ts "    - mixcorr_nym_version='${mixcorr_nym_version}'"
log_ts "    - mixcorr_exp_name='${mixcorr_exp_name}'"
log_ts "    - mixcorr_root_dir='${mixcorr_root_dir}'"
log_ts "    - mixcorr_res_dir_root='${mixcorr_res_dir_root}'"
log_ts "    - mixcorr_res_dir='${mixcorr_res_dir}'"
log_ts "    - mixcorr_orchestration_dir='${mixcorr_orchestration_dir}'"
log_ts "    - mixcorr_scens_dir='${mixcorr_scens_dir}'"
log_ts "    - mixcorr_nym_gateway_dir='${mixcorr_nym_gateway_dir}'"
log_ts "    - mixcorr_nym_gateway_name='${mixcorr_nym_gateway_name}'"
log_ts "    - mixcorr_nym_gateway_path='${mixcorr_nym_gateway_path}'"
log_ts "    - mixcorr_nym_gateway_sphinxflow_dir='${mixcorr_nym_gateway_sphinxflow_dir}'"
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

log_ts "Starting ${mixcorr_nym_gateway_name} at ${mixcorr_nym_gateway_path}..."
( mixcorr_gateway_sphinxflow_dir="${mixcorr_nym_gateway_sphinxflow_dir}" "${mixcorr_nym_gateway_path}" run --id "${mixcorr_nym_gateway_name}" ) &>> "${log_file}"


printf "\n" &>> "${log_file}"
log_ts "Start script for gateway ${mixcorr_nym_gateway_name} exiting!"
