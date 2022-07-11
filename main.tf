
variable "esxi_host"     {}
variable "esxi_user"     {}
variable "esxi_password" {}

terraform {
	required_providers {
		esxi = {
			source = "josenk/esxi"
			version = "1.10.2"
		}
	}
}

provider "esxi" {
	esxi_hostname = var.esxi_host
	esxi_username = var.esxi_user
	esxi_password = var.esxi_password
}

resource "esxi_virtual_disk" "proxy_disk" {
	virtual_disk_disk_store = "Data"
	virtual_disk_dir        = "Terraform"
	virtual_disk_name       = "proxy_disk.vdmk"
	virtual_disk_size       = 32
}

resource "esxi_virtual_disk" "node_disk" {
	virtual_disk_disk_store = "Data"
	virtual_disk_dir        = "Terraform"
	virtual_disk_name       = "node_disk.vdmk"
	virtual_disk_size       = 32
}

resource "esxi_guest" "teleport_proxy" {

	guest_name     = "teleport_proxy"
	disk_store     = "Data"
	virthwver      = "11"
	power          = "on"
	boot_disk_size = 32
	guestos        = "ubuntu"
	ovf_source     = "./bionic-server-cloudimg-amd64.ova"

	network_interfaces {
		virtual_network = "playground"
	}

	virtual_disks {
		virtual_disk_id = esxi_virtual_disk.proxy_disk.id
		slot            = "0:1"
	}

	guestinfo = {
		"userdata"          = base64gzip(file("./proxy/cloud-init.yaml"))
		"userdata.encoding" = "gzip+base64"
		"metadata"          = base64gzip(file("./proxy/meta.yaml"))
		"metadata.encoding" = "gzip+base64"
	}
}

resource "esxi_guest" "teleport_node" {

	guest_name     = "teleport_node"
	disk_store     = "Data"
	virthwver      = "11"
	power          = "on"
	boot_disk_size = 32
	guestos        = "ubuntu"
	ovf_source     = "./bionic-server-cloudimg-amd64.ova"

	network_interfaces {
		virtual_network = "playground"
	}

	virtual_disks {
		virtual_disk_id = esxi_virtual_disk.node_disk.id
		slot            = "0:1"
	}

	guestinfo = {
		"userdata"          = base64gzip(file("./node/cloud-init.yaml"))
		"userdata.encoding" = "gzip+base64"
		"metadata"          = base64gzip(file("./node/meta.yaml"))
		"metadata.encoding" = "gzip+base64"
	}

}


