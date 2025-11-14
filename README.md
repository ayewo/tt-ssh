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
```sh
# 1. The `ssha()` shell function appends several handy commands/aliases to `~/.bash_aliases` on the VM
ssha -v -p 23768 -i ~/.ssh/ayewo/github/id_ed25519 root@01.proxy.koyeb.app
Ctrl+D


# 2. Ubuntu update and dependencies
ssh -v -p 23768 -i ~/.ssh/ayewo/github/id_ed25519 root@01.proxy.koyeb.app
apt update
apt-get install tree zip vim htop screen lsof strace -y


# 3. clone and install pytorch-tt dependencies
mkdir -p /root/tt && cd /root/tt
git clone https://github.com/tenstorrent/pytorch2.0_ttnn
cd pytorch2.0_ttnn/
pip install -r requirements-dev.txt
pip install -e .


# 4. refresh the tt-metal folder present on the VM and Python v-env
cd /root/tt/tt-metal/ && ./build_metal.sh && ./create_venv.sh

# 5. run the PyTorch tests
...

```
Running the `create_venv.sh` is a [crucial](https://github.com/tenstorrent/tt-metal/issues/30732#issuecomment-3416288067) last step otherwise you'll get "`sfpi not found at /root/.ttnn_runtime_artifacts/runtime/sfpi or /opt/tenstorrent/sfpi`".
