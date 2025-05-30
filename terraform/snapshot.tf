#Create a new Compute Snapshot Schedule with retention period.

resource "yandex_compute_snapshot_schedule" "vox_snap" {
  schedule_policy {
    expression = "0 0 ? * *"
  }

  retention_period = "168h"

  snapshot_spec {
    description = "retention-snapshot"
  }

  disk_ids = [
    "${yandex_compute_instance.bastion.boot_disk.0.disk_id}", 
    "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}",
    "${yandex_compute_instance.kibana.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elasticsearch.boot_disk.0.disk_id}", ]

    #"${yandex_compute_instance_group.vx_instance.index.boot_disk.0.disk_id}", ] 
    #"${yandex_compute_instance_group.vx-1.boot_disk.0.disk_id}", ]
    #"${yandex_compute_instance_group.vx-2.boot_disk.0.disk_id}", ]
    #"${yandex_compute_instance_group.vx-3.boot_disk.0.disk_id}", ]
}