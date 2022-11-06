# skwr for Raspberry Pi - Because Kubernetes is great, but sometimes it's too much

'skwr' (pronounced 'square') goal is to allow for easy and repeatable deployment of kubenetes single node cluster on a Raspberry Pi device.

## Quick start guide

To create a small kubernetes cluster:

* Install `ansible` and the required module with `./install/kubectl.sh`.
* Run `./install/k3d/install.sh --to TARGET`, where `TARGET` is the hostname or ip of your server.
* The kubeconfig for the cluster will be copied locally in `~/.kube/config`.
* Install `kubectl` with `./install/kubectl.sh`.
* Verify that `kubectl api-resources` returns a list of resources successfully.
