## How to Deploy

Below is an explanation of how to connect directly to a Koyeb Tenstorrent instance through SSH using [Koyeb TCP Proxy](https://www.koyeb.com/docs/run-and-scale/tcp-proxy).

By following this guide, you will be able to deploy a Koyeb service on a Tenstorrent instance and establish a connection from the Koyeb service via SSH.

### Requirements

To use this example, you need:

- [A Koyeb account](https://app.koyeb.com/auth/signup).
- Access to the private preview for Tenstorrent instances. You can request access [here](https://www.koyeb.com/tenstorrent).
- A public SSH key used to authenticate access to the Koyeb service.
- The "Deploy to Koyeb" button below replaces [`koyeb/tt-ssh`](https://hub.docker.com/r/koyeb/tt-ssh) with [`ghcr.io/ayewo/tt-ssh`](https://github.com/ayewo/tt-ssh/pkgs/container/tt-ssh) Docker image.

### Deploy to Koyeb

Get started by creating the service on Koyeb by clicking the button below:

[![Deploy to Koyeb](https://www.koyeb.com/static/images/deploy/button.svg)](https://app.koyeb.com/deploy?name=tt-ssh&type=docker&image=ghcr.io%2Fayewo%2Ftt-ssh&privileged=true&instance_type=gpu-tenstorrent-n300s&regions=na&env%5BPUBLIC_KEY%5D=REPLACE_ME&volume_path%5Btt-data%5D=%2Fworkdir&volume_size%5Btt-data%5D=10&ports=22%3Btcp%3B%3Btrue%3Btcp&instances_min=1)

Clicking on this button brings you to the Koyeb Service creation page with the settings pre-configured to launch this application. Make sure to modify the `PUBLIC_KEY` environment variable with your own value during the configuration process.

After the service is deployed, you can connect to the `root` account of your Koyeb Service via SSH using the Koyeb TCP Proxy details shown in your Koyeb control panel:

```
ssh -p 2222 root@01.proxy.koyeb.app
```

_The command above is an example, make sure to replace the hostname and port with the actual values provided in your Koyeb control panel._


### Building the Docker Image
The Docker image in this repo was built inside a pre-existing Koyeb instance where `/root/tt/tt-metal` already contained compiled binaries.

The `tt-metal` folder was set up on Koyeb as follows:
```sh
cd /root/tt
git clone https://github.com/tenstorrent/tt-metal.git --recurse-submodules
cd tt-metal/
./build_metal.sh

./create_venv.sh
-> Creating virtual env in: /root/tt/tt-metal/python_env
...
-> Generating git hooks
-> pre-commit installed at .git/hooks/pre-commit
-> pre-commit installed at .git/hooks/commit-msg
-> If you want stubs, run ./scripts/build_scripts/create_stubs.sh

source python_env/bin/activate
```

To use the code in this repo to build the Docker image (15+ GB), do the following:
```sh
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxx"
export GHCR_USERNAME="ayewo"
export IMAGE_NAME="tt-ssh"
export IMAGE_TAG="latest"
export DOCKER_BUILDKIT=1

./build-and-push.sh
```


## How to Use
On a new Koyeb instance:

1. Note that `ssha()` is a custom `zsh` function. It appends several local commands/aliases from my shell to the VM's `~/.bash_aliases` that I find handy:
```sh
ssha -v -p 23768 -i ~/.ssh/ayewo/github/id_ed25519 root@01.proxy.koyeb.app
exit
```

2. Ubuntu update and install some basic utilities:
```
ssh -v -p 23768 -i ~/.ssh/ayewo/github/id_ed25519 root@01.proxy.koyeb.app
apt update

# dependencies / utils that I find handy on the VM
apt install ca-certificates gpg tree less zip vim htop screen net-tools lsof strace ripgrep -y

# tenstorrent utils / dependencies
apt install wget git python3-pip dkms cargo -y 
```

3. Refresh[^1] the `tt-metal/` folder and the Python virtual-env on the VM (the `tt-metal/` folder was [built into](https://github.com/ayewo/tt-ssh/blob/27dd1e4c397c6a7943cad65c8f1886735b313382/Dockerfile#L50-L52) the Docker image):
```
cd /root/tt/tt-metal/ && ./build_metal.sh && ./create_venv.sh
```

Running the `create_venv.sh` is a [crucial](https://github.com/tenstorrent/tt-metal/issues/30732#issuecomment-3416288067) last step otherwise you'll get "`sfpi not found at /root/.ttnn_runtime_artifacts/runtime/sfpi or /opt/tenstorrent/sfpi`".


4. Now activate the Python virtual-env refreshed in step 3:
```
source /root/tt/tt-metal/python_env/bin/activate
```

5. Test you have a working environment with this:
```
cd /root/tt/tt-metal/
export PYTHONPATH=/root/tt/tt-metal
python3 -m ttnn.examples.usage.run_op_on_device
```

  You can further confirm you have a working environment by running each of the PyTorch examples below[^2][^3].

> [!NOTE]
> The [examples](https://github.com/ayewo/tt-ssh/tree/main/examples) are taken directly from the Tenstorrent docs: https://docs.tenstorrent.com/tt-metal/latest/ttnn/ttnn/usage.html#basic-examples

```
cd /tmp && git clone https://github.com/ayewo/tt-ssh/
cd /tmp/tt-ssh/examples/
source /root/tt/tt-metal/python_env/bin/activate

python 01.py
python 02.py
...
```

```sh
(python_env) root@00635c27:/tmp/tt-ssh/examples# python 01.py 
2025-11-14 09:02:38.783 | DEBUG    | ttnn:<module>:77 - Initial ttnn.CONFIG:
Config{cache_path=/root/.cache/ttnn,model_cache_path=/root/.cache/ttnn/models,tmp_dir=/tmp/ttnn,enable_model_cache=false,enable_fast_runtime_mode=true,throw_exception_on_fallback=false,enable_logging=false,enable_graph_report=false,enable_detailed_buffer_report=false,enable_detailed_tensor_report=false,enable_comparison_mode=false,comparison_mode_should_raise_exception=false,comparison_mode_pcc=0.9999,root_report_path=generated/ttnn/reports,report_name=std::nullopt,std::nullopt}
2025-11-14 09:02:38.894 | info     |             UMD | Established cluster ETH FW version: 6.14.0 (topology_discovery_wormhole.cpp:324)
2025-11-14 09:02:38.903 | info     |          Device | Opening user mode device driver (tt_cluster.cpp:209)
2025-11-14 09:02:38.910 | info     |             UMD | Established cluster ETH FW version: 6.14.0 (topology_discovery_wormhole.cpp:324)
2025-11-14 09:02:38.936 | info     |             UMD | Established cluster ETH FW version: 6.14.0 (topology_discovery_wormhole.cpp:324)
2025-11-14 09:02:38.954 | info     |             UMD | Harvesting mask for chip 0 is 0x201 (NOC0: 0x201, simulated harvesting mask: 0x0). (cluster.cpp:413)
2025-11-14 09:02:38.983 | info     |             UMD | Harvesting mask for chip 1 is 0x204 (NOC0: 0x204, simulated harvesting mask: 0x0). (cluster.cpp:413)
2025-11-14 09:02:38.996 | info     |             UMD | Opening local chip ids/PCIe ids: {0}/[0] and remote chip ids {1} (cluster.cpp:257)
2025-11-14 09:02:38.996 | info     |             UMD | All devices in cluster running firmware version: 255.255.0 (cluster.cpp:235)
2025-11-14 09:02:38.996 | info     |             UMD | IOMMU: disabled (cluster.cpp:177)
2025-11-14 09:02:38.996 | info     |             UMD | KMD version: 1.32.0 (cluster.cpp:180)
2025-11-14 09:02:38.999 | info     |             UMD | Pinning pages for Hugepage: virtual address 0x7fd600000000 and size 0x40000000 pinned to physical address 0x200000000 (pci_device.cpp:536)
2025-11-14 09:02:38.999 | info     |             UMD | Pinning pages for Hugepage: virtual address 0x7fd5c0000000 and size 0x40000000 pinned to physical address 0x1c0000000 (pci_device.cpp:536)
2025-11-14 09:02:39.028 | info     |          Fabric | TopologyMapper mapping start (mesh=0): n_log=2, n_phys=2, log_deg_hist={1:2}, phys_deg_hist={1:2} (topology_mapper.cpp:574)
2025-11-14 09:02:39.028 | info     |          Fabric | Fast-path path-graph mapping succeeded for mesh 0 (topology_mapper.cpp:777)
2025-11-14 09:02:39.673 | info     |          Device | Closing user mode device drivers (tt_cluster.cpp:428)
```

```sh
(python_env) root@00635c27:/tmp/tt-ssh/examples# python 02.py 
2025-11-14 09:02:48.263 | DEBUG    | ttnn:<module>:77 - Initial ttnn.CONFIG:
Config{cache_path=/root/.cache/ttnn,model_cache_path=/root/.cache/ttnn/models,tmp_dir=/tmp/ttnn,enable_model_cache=false,enable_fast_runtime_mode=true,throw_exception_on_fallback=false,enable_logging=false,enable_graph_report=false,enable_detailed_buffer_report=false,enable_detailed_tensor_report=false,enable_comparison_mode=false,comparison_mode_should_raise_exception=false,comparison_mode_pcc=0.9999,root_report_path=generated/ttnn/reports,report_name=std::nullopt,std::nullopt}
2025-11-14 09:02:48.367 | info     |             UMD | Established cluster ETH FW version: 6.14.0 (topology_discovery_wormhole.cpp:324)
2025-11-14 09:02:48.376 | info     |          Device | Opening user mode device driver (tt_cluster.cpp:209)
2025-11-14 09:02:48.381 | info     |             UMD | Established cluster ETH FW version: 6.14.0 (topology_discovery_wormhole.cpp:324)
2025-11-14 09:02:48.407 | info     |             UMD | Established cluster ETH FW version: 6.14.0 (topology_discovery_wormhole.cpp:324)
2025-11-14 09:02:48.424 | info     |             UMD | Harvesting mask for chip 0 is 0x201 (NOC0: 0x201, simulated harvesting mask: 0x0). (cluster.cpp:413)
2025-11-14 09:02:48.452 | info     |             UMD | Harvesting mask for chip 1 is 0x204 (NOC0: 0x204, simulated harvesting mask: 0x0). (cluster.cpp:413)
2025-11-14 09:02:48.466 | info     |             UMD | Opening local chip ids/PCIe ids: {0}/[0] and remote chip ids {1} (cluster.cpp:257)
2025-11-14 09:02:48.466 | info     |             UMD | All devices in cluster running firmware version: 255.255.0 (cluster.cpp:235)
2025-11-14 09:02:48.466 | info     |             UMD | IOMMU: disabled (cluster.cpp:177)
2025-11-14 09:02:48.466 | info     |             UMD | KMD version: 1.32.0 (cluster.cpp:180)
2025-11-14 09:02:48.469 | info     |             UMD | Pinning pages for Hugepage: virtual address 0x7f1fc0000000 and size 0x40000000 pinned to physical address 0x200000000 (pci_device.cpp:536)
2025-11-14 09:02:48.469 | info     |             UMD | Pinning pages for Hugepage: virtual address 0x7f1f80000000 and size 0x40000000 pinned to physical address 0x1c0000000 (pci_device.cpp:536)
2025-11-14 09:02:48.506 | info     |          Fabric | TopologyMapper mapping start (mesh=0): n_log=2, n_phys=2, log_deg_hist={1:2}, phys_deg_hist={1:2} (topology_mapper.cpp:574)
2025-11-14 09:02:48.506 | info     |          Fabric | Fast-path path-graph mapping succeeded for mesh 0 (topology_mapper.cpp:777)
2025-11-14 09:02:48.661 | info     |           Metal | Profiler started on device 0 (device_pool.cpp:203)
tensor([[2.1094],
        [0.8203],
        [1.2266],
        [2.2500]], dtype=torch.bfloat16)
2025-11-14 09:02:49.393 | info     |          Device | Closing user mode device drivers (tt_cluster.cpp:428)
```

6. Now that you have a working environment, you can work on your fork. In my case, this is my fork of the `pytorch2.0_ttnn` repo. Git clone and install its dependencies:
```
mkdir -p /root/tt && cd /root/tt
git clone https://github.com/ayewo/pytorch2.0_ttnn
cd pytorch2.0_ttnn/
git switch feat/mistral
pip install -r requirements-dev.txt
pip install -e .
```


[^1]: On an N300s(4 vCPU, 32GB RAM, 24GB VRAM, 320GB Disk) Koyeb instance, compilation of a fresh git clone of `tt-metal/` via `./build_metal.sh` takes ~22mins while a refresh of an already cloned folder (built into the Docker image) using the same shell script takes ~10s. Similarly, venv creation inside `tt-metal/` via `./create_venv.sh` takes ~4mins while a refresh is almost instantenous.

[^2]: To avoid getting the warning `File size 48 is not as expected 56 for mutex REG_TLB_0_PCIe` or similar errors (view source for an example below), be sure to run `export PYTHONPATH=/root/tt/tt-metal` prior to running `python3 -m ttnn.examples.usage.run_op_on_device`.
```
python3 -m ttnn.examples.usage.run_op_on_device
2026-02-18 14:52:59.440 | DEBUG    | ttnn:<module>:77 - Initial ttnn.CONFIG:
Config{cache_path=/root/.cache/ttnn,model_cache_path=/root/.cache/ttnn/models,tmp_dir=/tmp/ttnn,enable_model_cache=false,enable_fast_runtime_mode=true,throw_exception_on_fallback=false,enable_logging=false,enable_graph_report=false,enable_detailed_buffer_report=false,enable_detailed_tensor_report=false,enable_comparison_mode=false,comparison_mode_should_raise_exception=false,comparison_mode_pcc=0.9999,root_report_path=generated/ttnn/reports,report_name=std::nullopt,std::nullopt}
2026-02-18 14:53:01.472 | warning  |             UMD | File size 48 is not as expected 56 for mutex REG_TLB_0_PCIe. This could be due to new pthread library version, or some other external factor. (robust_mutex.cpp:199)
2026-02-18 14:53:01.472 | warning  |             UMD | The file was resized, but the initialized flag is correct. This is an unexpected case, the mutex might fail. Mutex name: REG_TLB_0_PCIe (robust_mutex.cpp:144)
```

[^3]: Also an error like `TT_FATAL: Read unexpected run_mailbox value from core (x=25,y=17) (assert.hpp:104)` or `2026-04-02 09:39:53.241 | critical |          Always | TT_FATAL: Read unexpected run_mailbox value from core (x=25,y=16) (assert.hpp:104)` is also due to forgetting to run `export PYTHONPATH=/root/tt/tt-metal` prior to running `python3 -m ttnn.examples.usage.run_op_on_device`.
```
python3 -m ttnn.examples.usage.run_op_on_device
2026-04-02 09:39:51.174 | DEBUG    | ttnn:<module>:77 - Initial ttnn.CONFIG:
Config{cache_path=/root/.cache/ttnn,model_cache_path=/root/.cache/ttnn/models,tmp_dir=/tmp/ttnn,enable_model_cache=false,enable_fast_runtime_mode=true,throw_exception_on_fallback=false,enable_logging=false,enable_graph_report=false,enable_detailed_buffer_report=false,enable_detailed_tensor_report=false,enable_comparison_mode=false,comparison_mode_should_raise_exception=false,comparison_mode_pcc=0.9999,root_report_path=generated/ttnn/reports,report_name=std::nullopt,std::nullopt}
2026-04-02 09:39:52.978 | info     |             UMD | Creating TopologyDiscovery for architecture: wormhole_b0 (topology_discovery.cpp:69)
2026-04-02 09:39:52.979 | info     |             UMD | Established firmware bundle version: 19.3.1 (topology_discovery.cpp:471)
2026-04-02 09:39:52.996 | info     |          Device | Opening user mode device driver (tt_cluster.cpp:224)
2026-04-02 09:39:52.996 | info     |             UMD | Creating TopologyDiscovery for architecture: wormhole_b0 (topology_discovery.cpp:69)
2026-04-02 09:39:52.997 | info     |             UMD | Established firmware bundle version: 19.3.1 (topology_discovery.cpp:471)
2026-04-02 09:39:53.013 | info     |             UMD | Creating TopologyDiscovery for architecture: wormhole_b0 (topology_discovery.cpp:69)
2026-04-02 09:39:53.014 | info     |             UMD | Established firmware bundle version: 19.3.1 (topology_discovery.cpp:471)
2026-04-02 09:39:53.046 | info     |             UMD | Harvesting masks for chip 0 tensix: 0x208 dram: 0x0 eth: 0x0 pcie: 0x0 l2cpu: 0x0 (cluster.cpp:325)
2026-04-02 09:39:53.139 | info     |             UMD | Harvesting masks for chip 1 tensix: 0x210 dram: 0x0 eth: 0x0 pcie: 0x0 l2cpu: 0x0 (cluster.cpp:325)
2026-04-02 09:39:53.153 | info     |             UMD | Opening local chip ids/PCIe ids: {0}/[0] and remote chip ids {1} (cluster.cpp:180)
2026-04-02 09:39:53.153 | info     |             UMD | IOMMU: disabled (cluster.cpp:155)
2026-04-02 09:39:53.153 | info     |             UMD | KMD version: 2.5.0 (cluster.cpp:158)
2026-04-02 09:39:53.155 | info     |             UMD | Starting devices in cluster (cluster.cpp:951)
2026-04-02 09:39:53.156 | info     |             UMD | Mapped hugepage 0x200000000 to NOC address 0x800000000 (silicon_sysmem_manager.cpp:215)
2026-04-02 09:39:53.156 | info     |             UMD | Mapped hugepage 0x1c0000000 to NOC address 0x840000000 (silicon_sysmem_manager.cpp:215)
2026-04-02 09:39:53.191 | info     |     Distributed | Using auto discovery to generate mesh graph. (metal_env.cpp:330)
2026-04-02 09:39:53.191 | info     |     Distributed | Constructing control plane using auto-discovery (no mesh graph descriptor). (metal_env.cpp:392)
2026-04-02 09:39:53.192 | info     |             UMD | Creating TopologyDiscovery for architecture: wormhole_b0 (topology_discovery.cpp:69)
2026-04-02 09:39:53.193 | info     |             UMD | Established firmware bundle version: 19.3.1 (topology_discovery.cpp:471)
2026-04-02 09:39:53.209 | info     |          Fabric | TopologyMapper: Logical Multi-Mesh Adjacency Map: (topology_mapper.cpp:1474)
2026-04-02 09:39:53.209 | info     |          Fabric |
=== Logical Mesh-Level Graph Adjacency Map ===
Total nodes: 1
Degree histogram: {0:1}
 (topology_solver.tpp:91)
2026-04-02 09:39:53.209 | info     |          Fabric |
=== Logical Mesh 0 Internal Graph Adjacency Map ===
Total nodes: 2
Degree histogram: {1:2}
 (topology_solver.tpp:91)
2026-04-02 09:39:53.209 | info     |          Fabric | TopologyMapper: Physical Multi-Mesh Adjacency Map: (topology_mapper.cpp:1485)
2026-04-02 09:39:53.209 | info     |          Fabric |
=== Physical Mesh-Level Graph Adjacency Map ===
Total nodes: 1
Degree histogram: {0:1}
 (topology_solver.tpp:91)
2026-04-02 09:39:53.209 | info     |          Fabric |
=== Physical Mesh 0 Internal Graph Adjacency Map ===
Total nodes: 2
Degree histogram: {1:2}
 (topology_solver.tpp:91)
2026-04-02 09:39:53.209 | info     |          Fabric | Starting multi-mesh mapping: 1 logical mesh(es) to 1 physical mesh(es) (topology_mapper_utils.cpp:1117)
2026-04-02 09:39:53.209 | info     |          Fabric | Multi-mesh mapping attempt 1/2: Trying inter-mesh mapping (topology_mapper_utils.cpp:1158)
2026-04-02 09:39:53.210 | info     |          Fabric | Attempt 1: Inter-mesh mapping succeeded, found 1 mesh pair(s) (topology_mapper_utils.cpp:1187)
2026-04-02 09:39:53.210 | info     |          Fabric | Multi-mesh mapping succeeded after 1 attempt(s): 1 mesh pair(s) mapped (topology_mapper_utils.cpp:1326)
2026-04-02 09:39:53.222 | info     |    BuildKernels | Using pre-compiled firmware from: /root/tt/tt-metal/tt_metal/pre-compiled/12436636796942346141/ (build_env_manager.cpp:259)
2026-04-02 09:39:53.226 | info     |    BuildKernels | Using pre-compiled firmware from: /root/tt/tt-metal/tt_metal/pre-compiled/12436636796942346141/ (build_env_manager.cpp:259)
2026-04-02 09:39:53.235 | info     |           Metal | While initializing device 0, active ethernet dispatch core (x=21,y=17) detected as still running, issuing exit signal. (risc_firmware_initializer.cpp:331)
2026-04-02 09:39:53.235 | info     |           Metal | While initializing device 0, active ethernet dispatch core (x=18,y=17) detected as still running, issuing exit signal. (risc_firmware_initializer.cpp:331)
2026-04-02 09:39:53.235 | info     |           Metal | While initializing device 0, active ethernet dispatch core (x=25,y=17) detected as still running, issuing exit signal. (risc_firmware_initializer.cpp:331)
Read unexpected run_mailbox value: 0x40 (expected 0x80 or 0x0)
2026-04-02 09:39:53.235 | critical |          Always | TT_FATAL: Read unexpected run_mailbox value from core (x=25,y=17) (assert.hpp:104)
2026-04-02 09:39:53.237 | warning  |          Always | Detected dispatch kernels still running but failed to complete an early exit. This may happen from time to time following a reset, continuing to FW initialization... (risc_firmware_initializer.cpp:351)
2026-04-02 09:39:53.240 | info     |           Metal | While initializing device 1, active ethernet dispatch core (x=18,y=16) detected as still running, issuing exit signal. (risc_firmware_initializer.cpp:331)
2026-04-02 09:39:53.240 | info     |           Metal | While initializing device 1, active ethernet dispatch core (x=25,y=16) detected as still running, issuing exit signal. (risc_firmware_initializer.cpp:331)
Read unexpected run_mailbox value: 0x40 (expected 0x80 or 0x0)
2026-04-02 09:39:53.241 | critical |          Always | TT_FATAL: Read unexpected run_mailbox value from core (x=25,y=16) (assert.hpp:104)
2026-04-02 09:39:53.243 | warning  |          Always | Detected dispatch kernels still running but failed to complete an early exit. This may happen from time to time following a reset, continuing to FW initialization... (risc_firmware_initializer.cpp:351)
tensor([[2.6562],
        [2.2031],
        [2.5000],
        [2.0156]], dtype=torch.bfloat16)
2026-04-02 09:40:01.828 | info     |          Device | Closing user mode device drivers (tt_cluster.cpp:478)
2026-04-02 09:40:01.828 | info     |             UMD | Closing devices in cluster (cluster.cpp:962)
```
