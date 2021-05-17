# Lab Setup

## Kube Config

```bash
mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Auto-Completion

```bash
sudo apt-get install bash-completion vim -y

# configure completion in the current shell
source <(kubectl completion bash)

# ensure future shells have completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

## Allow General Containers

A master node is tainted to not allow general containers by default for security reasons. The following command will remove the taint from all nodes. The worker/minion node does not have the taint to begin with, so you should see one success and one not found error. Note the value to be removed has minus signa at end.

```bash
kubectl describe nodes | grep -i Taint

kubectl taint nodes --all node-role.kubernetes.io/master-
```
