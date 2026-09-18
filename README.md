# Local Cluster Deployment on Intranet

## 1. Project Overview
## 2. Architecture
## 3. Infrastructure / Node Details

# Part 01 — Infrastructure and Node Creation
## 4. Create the Nodes
## 5. Configure Hostnames
## 6. Configure Network
## 7. Configure Tailscale
## 8. Verify SSH
## 9. Verify Connectivity

# Part 02 — Kubernetes Node Preparation
## 10. Disable Swap
## 11. Kernel Modules
## 12. Sysctl
## 13. Install containerd
## 14. Configure containerd
## 15. Install kubeadm
## 16. Install kubelet
## 17. Install kubectl

# Part 03 — HAProxy Load Balancer
## 18. Install HAProxy
## 19. Configure HAProxy
## 20. Validate HAProxy
## 21. Test API Connectivity

# Part 04 — Initialize Kubernetes
## 22. Create kubeadm Configuration
## 23. Initialize Master 01
## 24. Configure kubectl
## 25. Verify Control Plane

# Part 05 — Add Control Plane Nodes
## 26. Join Master 02
## 27. Join Master 03
## 28. Verify Three-Master Cluster
## 29. Verify etcd

# Part 06 — Add Worker Nodes
## 30. Generate Worker Join Command
## 31. Join Worker 01
## 32. Join Worker 02
## 33. Join Worker 03
## 34. Verify Nodes

# Part 07 — Install Calico
## 35. Install Calico
## 36. Verify Calico
## 37. Verify Pod Networking

# Part 08 — External Admin Client
## 38. Install kubectl
## 39. Configure kubeconfig
## 40. Connect Through HAProxy
## 41. Verify Admin Access

# Part 09 — OpenEBS
## 42. Install OpenEBS
## 43. Verify OpenEBS
## 44. Check StorageClasses

# Part 10 — Persistent Storage
## 45. Create Namespace
## 46. Create PVC
## 47. Verify PV/PVC
## 48. Explain Storage Allocation
## 49. Verify Volume Mount

# Part 11 — Monitoring
## 50. Install Prometheus
## 51. Install Grafana
## 52. Install Node Exporter
## 53. Verify Monitoring

# Part 12 — etcd Architecture
## 54. Three-Member etcd
## 55. etcd Leader
## 56. Leader Detection
## 57. etcd Health Verification

# Part 13 — etcd Backup
## 58. Backup Architecture
## 59. Backup Script
## 60. TLS Configuration
## 61. Leader Detection
## 62. Snapshot Creation
## 63. Snapshot Validation

# Part 14 — Backup Storage
## 64. OpenEBS PVC
## 65. Mount Backup Volume
## 66. Store Snapshot
## 67. Verify Backup

# Part 15 — CronJob
## 68. Create CronJob
## 69. Configure 24-Hour Schedule
## 70. Manual Backup Test
## 71. Verify Jobs
## 72. Verify Logs

# Part 16 — Backup Retention
## 73. Retention Policy
## 74. Automatic Cleanup
## 75. Storage Monitoring

# Part 17 — Restore
## 76. Restore Architecture
## 77. Validate Snapshot
## 78. Restore Procedure
## 79. Verify Kubernetes After Restore

# Part 18 — Troubleshooting
## 80. Node NotReady
## 81. kubelet Issues
## 82. containerd Issues
## 83. HAProxy Issues
## 84. API Server Issues
## 85. Calico Issues
## 86. OpenEBS Issues
## 87. PVC Pending
## 88. Backup Failure
## 89. etcd Failure

# Part 19 — Security
## 90. Admin Access
## 91. etcd Security
## 92. TLS Certificates
## 93. Secrets
## 94. Backup Security

# Part 20 — Final Validation
## 95. Cluster Validation
## 96. HAProxy Validation
## 97. etcd Validation
## 98. OpenEBS Validation
## 99. Backup Validation
## 100. Final Checklist

# Part 21 — Final Architecture
## 101. Complete Architecture
## 102. End-to-End Flow
