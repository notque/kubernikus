provider "openstack" {
  auth_url         = "https://identity-3.${var.region}.cloud.sap/v3"
  region           = "${var.region}"
  user_name        = "${var.user_name}"
  user_domain_name = "${var.user_domain_name}"
  password         = "${var.password}"
  tenant_name      = "cloud_admin"
  domain_name      = "ccadmin"
}

provider "ccloud" {
  alias            = "cloud_admin"

  auth_url         = "https://identity-3.${var.region}.cloud.sap/v3"
  region           = "${var.region}"
  user_name        = "${var.user_name}"
  user_domain_name = "${var.user_domain_name}"
  password         = "${var.password}"
  tenant_name      = "cloud_admin"
  domain_name      = "ccadmin"
}

provider "ccloud" {
  alias            = "kubernikus"

  auth_url         = "https://identity-3.${var.region}.cloud.sap/v3"
  region           = "${var.region}"
  user_name        = "${var.user_name}"
  user_domain_name = "${var.user_domain_name}"
  password         = "${var.password}"
  tenant_id        = "${openstack_identity_project_v3.kubernikus.id}"
}


data "openstack_identity_project_v3" "kubernikus_domain" {
  name      = "${var.domain_name}"
  is_domain = true
}

data "ccloud_identity_group_v3" "ccadmin_domain_admins" {
  provider = "ccloud.cloud_admin"
  name = "CCADMIN_DOMAIN_ADMINS"
}

data "openstack_identity_role_v3" "admin" {
  name = "admin"
}

data "openstack_identity_role_v3" "compute_admin" {
  name = "compute_admin"
}

data "openstack_identity_role_v3" "network_admin" {
  name = "network_admin"
}

data "openstack_identity_role_v3" "resource_admin" {
  name = "resource_admin"
}

data "openstack_identity_role_v3" "volume_admin" {
  name = "volume_admin"
}

data "openstack_networking_network_v2" "external_network" {
  name = "FloatingIP-external-ccadmin"
}


resource "openstack_identity_project_v3" "kubernikus" {
  name        = "kubernikus"
  domain_id   = "${data.openstack_identity_project_v3.kubernikus_domain.id}"
  description = "Kubernikus Control-Plane"
}

resource "openstack_identity_role_v3" "kubernetes_admin" {
  name = "kubernetes_admin"
}

resource "openstack_identity_role_assignment_v3" "admin" {
  group_id   = "${data.ccloud_identity_group_v3.ccadmin_domain_admins.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"
  role_id    = "${data.openstack_identity_role_v3.admin.id}"
}

resource "openstack_identity_role_assignment_v3" "compute_admin" {
  group_id   = "${data.ccloud_identity_group_v3.ccadmin_domain_admins.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"
  role_id    = "${data.openstack_identity_role_v3.compute_admin.id}"
}

resource "openstack_identity_role_assignment_v3" "network_admin" {
  group_id   = "${data.ccloud_identity_group_v3.ccadmin_domain_admins.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"
  role_id    = "${data.openstack_identity_role_v3.network_admin.id}"
}

resource "openstack_identity_role_assignment_v3" "resource_admin" {
  group_id   = "${data.ccloud_identity_group_v3.ccadmin_domain_admins.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"
  role_id    = "${data.openstack_identity_role_v3.resource_admin.id}"
}

resource "openstack_identity_role_assignment_v3" "volume_admin" {
  group_id   = "${data.ccloud_identity_group_v3.ccadmin_domain_admins.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"
  role_id    = "${data.openstack_identity_role_v3.volume_admin.id}"
}

resource "openstack_identity_role_assignment_v3" "kubernetes_admin" {
  group_id   = "${data.ccloud_identity_group_v3.ccadmin_domain_admins.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"
  role_id    = "${openstack_identity_role_v3.kubernetes_admin.id}"
}

resource "ccloud_quota" "kubernikus" {
  provider = "ccloud.cloud_admin" 

  domain_id  = "${data.openstack_identity_project_v3.kubernikus_domain.id}"
  project_id = "${openstack_identity_project_v3.kubernikus.id}"

  compute {
    instances = 10
    cores     = 32
    ram       = 81920 
  }

  volumev2 {
    capacity  = 1024
    snapshots = 0
    volumes   = 100
  }

  network {
		floating_ips         = 4
		networks             = 1
		ports                = 500
		routers              = 2
		security_group_rules = 64
		security_groups      = 4
		subnets              = 1
		healthmonitors       = 10
		l7policies           = 10
		listeners            = 10
		loadbalancers        = 10
		pools                = 10
  }
}

resource "openstack_networking_network_v2" "network" {
  tenant_id      = "${openstack_identity_project_v3.kubernikus.id}"
  name           = "kubernikus"
  admin_state_up = "true"
  depends_on     = ["ccloud_quota.kubernikus"]
}

resource "openstack_networking_subnet_v2" "subnet" {
  tenant_id  = "${openstack_identity_project_v3.kubernikus.id}"
  name       = "kubernikus"
  network_id = "${openstack_networking_network_v2.network.id}"
  cidr       = "198.18.0.0/24"
  ip_version = 4
  depends_on = ["ccloud_quota.kubernikus"]
}

resource "openstack_networking_router_v2" "router" {
  tenant_id           = "${openstack_identity_project_v3.kubernikus.id}"
  name                = "kubernikus"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.external_network.id}"
  depends_on          = ["ccloud_quota.kubernikus"]
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet.id}"
}

resource "openstack_networking_secgroup_v2" "kubernikus" {
  tenant_id   = "${openstack_identity_project_v3.kubernikus.id}"
  name        = "kubernikus"
  description = "Kubernikus"
  depends_on  = ["ccloud_quota.kubernikus"]
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_0" {
  tenant_id = "${openstack_identity_project_v3.kubernikus.id}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  remote_ip_prefix  = "198.18.0.0/15"
  security_group_id = "${openstack_networking_secgroup_v2.kubernikus.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  tenant_id = "${openstack_identity_project_v3.kubernikus.id}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  remote_ip_prefix  = "198.18.0.0/15"
  security_group_id = "${openstack_networking_secgroup_v2.kubernikus.id}"
}

resource "ccloud_kubernetes" "kluster" {
  provider = "ccloud.kubernikus" 

  name           = "k-${var.region}"
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCXIxVEUgtUVkvk2VM1hmIb8MxvxsmvYoiq9OBy3J8akTGNybqKsA2uhcwxSJX5Cn3si8kfMfka9EWiJT+e1ybvtsGILO5XRZPxyhYzexwb3TcALwc3LuzpF3Z/Dg2jYTRELTGhYmyca3mxzTlCjNXvYayLNedjJ8fIBzoCuSXNqDRToHru7h0Glz+wtuE74mNkOiXSvhtuJtJs7VCNVjobFQNfC1aeDsri2bPRHJJZJ0QF4LLYSayMEz3lVwIDyAviQR2Aa97WfuXiofiAemfGqiH47Kq6b8X7j3bOYGBvJKMUV7XeWhGsskAmTsvvnFxkc5PAD3Ct+liULjiQWlzDrmpTE8aMqLK4l0YQw7/8iRVz6gli42iEc2ZG56ob1ErpTLAKFWyCNOebZuGoygdEQaGTIIunAncXg5Rz07TdPl0Tf5ZZLpiAgR5ck0H1SETnjDTZ/S83CiVZWJgmCpu8YOKWyYRD4orWwdnA77L4+ixeojLIhEoNL8KlBgsP9Twx+fFMWLfxMmiuX+yksM6Hu+Lsm+Ao7Q284VPp36EB1rxP1JM7HCiEOEm50Jb6hNKjgN4aoLhG5yg+GnDhwCZqUwcRJo1bWtm3QvRA+rzrGZkId4EY3cyOK5QnYV5+24x93Ex0UspHMn7HGsHUESsVeV0fLqlfXyd2RbHTmDMP6w=="

  node_pools = [
    { name = "payload0", flavor = "m1.xlarge_cpu", size = 2 },
    { name = "payload1", flavor = "m1.xlarge_cpu", size = 1 }
  ]

  depends_on = ["openstack_networking_router_v2.router"]
}
