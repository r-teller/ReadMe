This terraform module will create an example environment to demonstrate transitive routing issues and how to workaround them using cloud-vpn

Just update terraform.tfvars file to include your billing account and organization id and apply.

On apply the following items will be created
- 3 projects
- Each project will contain a single VPC with a Primary subnetwork with two secondary ranges
- Each project will contain a single jump host that can be used to validate routing
- Firewall rules to allow traffic from IAP to the jump host to allow SSH
- Full mesh VPC peering between all three VPCs
- A private GKE cluster with a single premtible node in the Alpha VPC
- VPN peering between the Alpha and Bravo VPC

You can delete the VPN peers to better understand behavior when the peering is not established
```bash
terraform destroy -target module.vpn_peering
```