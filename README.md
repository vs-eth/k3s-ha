# k3s-ha

An Ansible role to set up k3s with only master nodes for high availability clusters.

## Overview

This Ansible role deploys a highly available k3s cluster using only master nodes. It's designed for scenarios where you want a lightweight Kubernetes distribution with high availability but don't need separate worker nodes.

## Features

- 🚀 **Master-only setup**: Creates a k3s cluster with only control plane nodes
- 🔐 **High Availability**: Uses embedded etcd for multi-master clusters  
- ⚙️ **Configurable**: Extensive customization options via variables
- 🛡️ **Secure**: Proper TLS configuration and token-based authentication
- 📦 **Lightweight**: Minimal resource requirements compared to full Kubernetes
- 🔧 **Flexible**: Support for custom networking, storage, and components

## Requirements

- Ansible 2.9+
- Target hosts running Ubuntu 20.04+, Debian 11+, or RHEL/CentOS 8+
- SSH access to target hosts with sudo privileges
- At least 1GB RAM and 1 CPU core per node
- Network connectivity between nodes on port 6443

## Installation

### From Ansible Galaxy (when published)

```bash
ansible-galaxy install vs-eth.k3s-ha
```

### From Source

```bash
git clone https://github.com/vs-eth/k3s-ha.git
cd k3s-ha
```

## Quick Start

1. **Create an inventory file** with your master nodes:

```ini
[k3s_masters]
master1 ansible_host=192.168.1.10
master2 ansible_host=192.168.1.11  
master3 ansible_host=192.168.1.12
```

2. **Create a playbook** using the role:

```yaml
---
- hosts: k3s_masters
  become: true
  vars:
    k3s_token: "your-secure-token-here"
    k3s_cluster_init: "{{ inventory_hostname == groups['k3s_masters'][0] }}"
    k3s_server_url: "{{ 'https://' + hostvars[groups['k3s_masters'][0]]['ansible_default_ipv4']['address'] + ':6443' if inventory_hostname != groups['k3s_masters'][0] else '' }}"
  roles:
    - k3s-ha
```

3. **Run the playbook**:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `k3s_token` | Cluster authentication token | `"K10c7b6d4e8f9a1234567890abcdef"` |

### Important Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k3s_version` | `"latest"` | k3s version to install |
| `k3s_cluster_init` | `false` | Initialize cluster (true for first node) |
| `k3s_server_url` | `""` | Join URL for additional masters |
| `k3s_embedded_etcd` | `true` | Use embedded etcd for HA |
| `k3s_cluster_cidr` | `"10.42.0.0/16"` | Pod network CIDR |
| `k3s_service_cidr` | `"10.43.0.0/16"` | Service network CIDR |
| `k3s_tls_san` | `[]` | Additional TLS SAN entries |
| `k3s_disable_components` | `[]` | Components to disable |

### Network Configuration

```yaml
k3s_cluster_cidr: "10.42.0.0/16"
k3s_service_cidr: "10.43.0.0/16"
k3s_cluster_domain: "cluster.local"
```

### TLS Configuration

```yaml
k3s_tls_san:
  - "192.168.1.100"  # Load balancer IP
  - "k3s.example.com"  # DNS name
```

### Component Management

```yaml
k3s_disable_components:
  - traefik      # Disable built-in ingress
  - servicelb    # Disable built-in load balancer
  - local-storage # Disable local storage
```

## Examples

See the [`examples/`](examples/) directory for complete examples:

- [`playbook.yml`](examples/playbook.yml) - Complete HA setup playbook
- [`inventory.ini`](examples/inventory.ini) - Example inventory file

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   k3s-master-1  │    │   k3s-master-2  │    │   k3s-master-3  │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │ k3s server│  │◄───┤  │ k3s server│  │◄───┤  │ k3s server│  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │   etcd    │  │◄───┤  │   etcd    │  │◄───┤  │   etcd    │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Usage Patterns

### Single Master (Development)

```yaml
- hosts: k3s_masters
  vars:
    k3s_token: "dev-token-123"
    k3s_cluster_init: true
  roles:
    - k3s-ha
```

### Multi Master HA (Production)

```yaml
- hosts: k3s_masters
  vars:
    k3s_token: "{{ vault_k3s_token }}"
    k3s_cluster_init: "{{ inventory_hostname == groups['k3s_masters'][0] }}"
    k3s_server_url: "{{ 'https://' + hostvars[groups['k3s_masters'][0]]['ansible_default_ipv4']['address'] + ':6443' if inventory_hostname != groups['k3s_masters'][0] else '' }}"
    k3s_tls_san: "{{ groups['k3s_masters'] | map('extract', hostvars, 'ansible_default_ipv4') | map(attribute='address') | list }}"
  roles:
    - k3s-ha
```

## Accessing the Cluster

After deployment, access your cluster:

```bash
# Copy kubeconfig from any master node
scp ubuntu@master1:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Update server address in kubeconfig
kubectl config set-cluster default --server=https://master1:6443

# Test cluster access
kubectl get nodes
```

## Troubleshooting

### Common Issues

1. **Token mismatch**: Ensure all nodes use the same `k3s_token`
2. **Network connectivity**: Check firewall rules for port 6443
3. **Time synchronization**: Ensure all nodes have synchronized time
4. **Disk space**: Check available space in `/var/lib/rancher/k3s`

### Logs

```bash
# Check k3s service status
sudo systemctl status k3s

# View k3s logs
sudo journalctl -u k3s -f

# Check cluster status
kubectl get nodes -o wide
```

## Security Considerations

- **Token Security**: Use a strong, randomly generated token
- **Network Security**: Restrict access to port 6443
- **TLS Certificates**: Properly configure TLS SAN entries
- **Updates**: Regularly update k3s version for security patches

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

GNU General Public License v3.0 - see [LICENSE](LICENSE) file for details.

## Changelog

### v1.0.0
- Initial release
- Master-only k3s setup support
- HA configuration with embedded etcd
- Comprehensive documentation and examples
