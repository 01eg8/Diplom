resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [web_servers]
    web1 ansible_host=vx-1
    web2 ansible_host=vx-2
    web3 ansible_host=vx-3

    [web_server_1]
    web1 ansible_host=vx-1
    [web_server_2]
    web2 ansible_host=vx-2
    [web_server_3]
    web3 ansible_host=vx-3

    [zabbix_server]
    zabbix ansible_host=zabbix

    [elastic_server]
    elasticsearch ansible_host=elasticsearch

    [kibana_server]
    kibana ansible_host=kibana

    [bastion_server]
    bastion ansible_host=bastion

    [all:vars]
    ansible_user=amd48
    ansible_ssh_key_file=/home/amd48/.ssh/id_ed25519.pub
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -p 22 -W %h:%p -q amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'

    # ssh -J amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} amd48@zabbix 
    # ssh -J amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} amd48@kibana
    # ssh -J amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} amd48@elasticsearch

    EOT
  filename = "../dplm-ans/hosts.ini"
}