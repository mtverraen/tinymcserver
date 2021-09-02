
locals {
  startup_script = templatefile("${path.module}/templates/startup.sh.tpl", {
    bucket            = google_storage_bucket.bucket.url
    minecraft_version = var.minecraft_version
    minecraft_port    = var.minecraft_port
    rcon_port         = var.rcon_port
    server_name       = var.server_name
    whitelist         = var.whitelisted_players
    ops               = var.ops
  })

  shutdown_script = templatefile("${path.module}/templates/shutdown.sh.tpl", {
    bucket = google_storage_bucket.bucket.url
  })

  startup = "docker run -d --name valhelsia -p 25565:25565 -v /var/minecraft:/data -e TYPE=CURSEFORGE -e CF_SERVER_MOD='https://media.forgecdn.net/files/3432/276/Valhelsia+3-3.4.2a-SERVER.zip' -e EULA=TRUE -e MEMORY=6G -e SERVER_NAME=${var.server_name} -e MOTD=${var.motd} -e VERSION=1.16.5 -e WHITELIST=${var.whitelisted_players} -e OPS=${var.ops} -e LEVEL=redo itzg/minecraft-server:java8"
}

resource "random_string" "id" {
  length  = 8
  special = false
  upper   = false
}

/*
  GCP utils
*/
resource "google_service_account" "service_account" {
  account_id = "mcserver"
}

resource "google_storage_bucket" "bucket" {
  name     = "minecraft-${random_string.id.result}"
  location = var.bucket_location
}

resource "google_compute_disk" "disk" {
  name  = "minecraft-disk"
  type  = "pd-standard"
  image = "cos-cloud/cos-stable"
  size  = var.disk_size_gb
}

resource "google_compute_network" "network" {
  name = "minecraft-network"
}

resource "google_compute_address" "address" {
  name = "minecraft-address"
}


resource "google_compute_firewall" "firewall" {
  name        = "minecraft-firewall"
  network     = google_compute_network.network.id
  target_tags = ["minecraft"]

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = [22, var.minecraft_port, var.rcon_port]
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_instance" "server" {
  name         = "minecraft-server"
  machine_type = "e2-standard-4"
  tags         = ["minecraft"]

  allow_stopping_for_update = true

  metadata = {
    # Run itzg/minecraft-server docker image on startup
    # The instructions of https://hub.docker.com/r/itzg/minecraft-server/ are applicable
    # For instance, Ssh into the instance and you can run
    #  docker logs mc
    #  docker exec -i mc rcon-cli
    # Once in rcon-cli you can "op <player_id>" to make someone an operator (admin)
    # Use 'sudo journalctl -u google-startup-scripts.service' to retrieve the startup script output

    # startup-script  = local.startup_script
    startup-script  = local.startup
    shutdown-script = local.shutdown_script
  }

  boot_disk {
    source      = google_compute_disk.disk.id
    auto_delete = false
  }

  network_interface {
    network = google_compute_network.network.id
    access_config {
      nat_ip = google_compute_address.address.address
    }
  }

  scheduling {
    preemptible       = false # Closes within 24 hours (sometimes sooner)
    automatic_restart = false
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
}
