# Variables Documentation

This document describes all available variables for the k3s-ha Ansible role.

## Required Variables

### k3s_token
- **Type**: String
- **Required**: Yes
- **Description**: Authentication token for the k3s cluster. Must be the same across all nodes.
- **Example**: `"K10c7b6d4e8f9a1234567890abcdef"`
- **Security**: Should be a strong, randomly generated string (at least 32 characters)

## Core Configuration

### k3s_version
- **Type**: String  
- **Default**: `"latest"`
- **Description**: Version of k3s to install
- **Examples**: `"v1.28.3+k3s2"`, `"latest"`

### k3s_cluster_init
- **Type**: Boolean
- **Default**: `false`
- **Description**: Whether this node should initialize the cluster (first master only)
- **Example**: `true`

### k3s_server_url
- **Type**: String
- **Default**: `""`
- **Description**: URL of existing k3s server to join (for additional masters)
- **Example**: `"https://192.168.1.10:6443"`

### k3s_embedded_etcd
- **Type**: Boolean
- **Default**: `true`
- **Description**: Use embedded etcd for HA (recommended for most setups)

## Directory Configuration

### k3s_bin_dir
- **Type**: String
- **Default**: `"/usr/local/bin"`
- **Description**: Directory where k3s binary will be installed

### k3s_data_dir
- **Type**: String
- **Default**: `"/var/lib/rancher/k3s"`
- **Description**: Directory for k3s data storage

### k3s_config_dir
- **Type**: String
- **Default**: `"/etc/rancher/k3s"`
- **Description**: Directory for k3s configuration files

## Network Configuration

### k3s_cluster_cidr
- **Type**: String
- **Default**: `"10.42.0.0/16"`
- **Description**: CIDR block for pod networking

### k3s_service_cidr
- **Type**: String
- **Default**: `"10.43.0.0/16"`
- **Description**: CIDR block for service networking

### k3s_cluster_domain
- **Type**: String
- **Default**: `"cluster.local"`
- **Description**: DNS domain for the cluster

## Security Configuration

### k3s_tls_san
- **Type**: List
- **Default**: `[]`
- **Description**: Additional Subject Alternative Names for TLS certificates
- **Example**: 
```yaml
k3s_tls_san:
  - "192.168.1.100"
  - "k3s.example.com"
```

### k3s_write_kubeconfig_mode
- **Type**: String
- **Default**: `"0644"`
- **Description**: File permissions for the kubeconfig file

## Component Management

### k3s_disable_components
- **Type**: List
- **Default**: `[]`
- **Description**: List of k3s components to disable
- **Available components**: `traefik`, `servicelb`, `metrics-server`, `local-storage`
- **Example**:
```yaml
k3s_disable_components:
  - traefik
  - servicelb
```

## Node Configuration

### k3s_node_labels
- **Type**: List
- **Default**: `[]`
- **Description**: Labels to apply to the node
- **Example**:
```yaml
k3s_node_labels:
  - "node-role.kubernetes.io/control-plane=true"
  - "environment=production"
```

### k3s_node_taints
- **Type**: List
- **Default**: `[]`
- **Description**: Taints to apply to the node
- **Example**:
```yaml
k3s_node_taints:
  - "node-role.kubernetes.io/control-plane:NoSchedule"
```

## Advanced Configuration

### k3s_server_args
- **Type**: List
- **Default**: `[]`
- **Description**: Additional arguments to pass to k3s server
- **Example**:
```yaml
k3s_server_args:
  - "--disable-network-policy"
  - "--flannel-backend=vxlan"
```

### k3s_datastore_endpoint
- **Type**: String
- **Default**: `""`
- **Description**: External datastore endpoint (for external etcd/database)
- **Example**: `"etcd://etcd1:2379,etcd2:2379,etcd3:2379"`

## System Configuration

### k3s_system_user
- **Type**: String
- **Default**: `"k3s"`
- **Description**: System user for k3s service

### k3s_system_group
- **Type**: String
- **Default**: `"k3s"`
- **Description**: System group for k3s service

## Variable Validation

The role includes validation for critical variables:

1. **k3s_token**: Must be non-empty
2. **Cluster initialization**: Either `k3s_cluster_init` must be true OR `k3s_server_url` must be provided
3. **Network CIDRs**: Should not overlap with existing network infrastructure

## Best Practices

1. **Secrets**: Use Ansible Vault for sensitive variables like `k3s_token`
2. **Networking**: Ensure cluster and service CIDRs don't conflict with your infrastructure
3. **HA Setup**: Use odd number of master nodes (3, 5, 7) for better quorum handling
4. **TLS SANs**: Include all possible access points (IPs, hostnames, load balancer addresses)