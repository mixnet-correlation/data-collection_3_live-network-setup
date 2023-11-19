# Dataset Collection Orchestrator in the Live-Network Setup, PoPETs 2024.2 paper "MixMatch"

Dataset collection orchestrator in the Live-Network Setup for PoPETs 2024.2 paper "MixMatch: Flow Matching for Mixnet Traffic".

We assume you are using the public cloud provider Hetzner as the place to run the cloud instances used to collect data in the Live-Network Setup. Thus, the first three scripts ([`1-provision-nym-gateway-hetzner.sh`](./1-provision-nym-gateway-hetzner.sh), [`2-provision-nym-endpoints-hetzner.sh`](./2-provision-nym-endpoints-hetzner.sh), and [`3-spawn-nym-gateway-endpoints-hetzner.sh`](./3-spawn-nym-gateway-endpoints-hetzner.sh)) assume the `hcloud` command-line utility to be installed and authenticated against a Hetzner Cloud account. Please ensure that is the case, for example, by following the instructions on this page: [github.com/hetznercloud/cli](https://github.com/hetznercloud/cli). It should be straightforward to translate the logic behind these three scripts to alternative cloud providers or even local-only setups. Going forward, we assume that `hcloud` is installed and configured.


## Setting Up and Collecting a Dataset

The first three scripts of this repository will take care of provisioning and spawning one private gateway instance and five endpoints instances. Run them as follows:
```bash
root@ubuntu2204 $   mkdir -p ~/mixmatch
root@ubuntu2204 $   cd ~/mixmatch
root@ubuntu2204 $   git clone https://github.com/mixnet-correlation/data-collection_3_live-network-setup.git
root@ubuntu2204 $   cd data-collection_3_live-network-setup
root@ubuntu2204 $   ./1-provision-nym-gateway-hetzner.sh
root@ubuntu2204 $   ./2-provision-nym-endpoints-hetzner.sh
root@ubuntu2204 $   ./3-spawn-nym-gateway-endpoints-hetzner.sh
```

Please check the contents of the produced log files to ensure everything has gone as planned.

Next, SSH into the gateway instance and execute the start script for the gateway process:
```bash
root@mixcorr-nym-gateway-ccx22-exp08 $   tmux
root@mixcorr-nym-gateway-ccx22-exp08 $   /root/mixcorr/data-collection_3_live-network-setup/4-exp08-run-experiments-nym-gateway.sh
```

Make sure to note down the Nym node details of the gateway instance as you'll need these when starting the endpoints instances.

In turn, SSH into each endpoints instance with the Nym gateway node details at hand and run:
```bash
root@mixcorr-nym-endpoints-ccx22-exp08-NUMBER $   tmux
root@mixcorr-nym-endpoints-ccx22-exp08-NUMBER $   vim /root/mixcorr/data-collection_3_live-network-setup/5-exp08-run-experiments-nym-endpoints.sh
... Make sure to edit and double-check all configuration values at the top of the script ...
root@mixcorr-nym-endpoints-ccx22-exp08-NUMBER $   /root/mixcorr/data-collection_3_live-network-setup/5-exp08-run-experiments-nym-endpoints.sh
```

Once all endpoints instances have concluded the dataset collection, make sure to download the result folders (located at `mixcorr_res_dir` as defined as part of [`5-exp08-run-experiments-nym-endpoints.sh`](./5-exp08-run-experiments-nym-endpoints.sh)) from each endpoints instance as well as all the Sphinx flow traces from the gateway instance (located at `mixcorr_res_dir` as defined as part of [`4-exp08-run-experiments-nym-gateway.sh`](./4-exp08-run-experiments-nym-gateway.sh)).
