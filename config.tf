resource "digitalocean_spaces_bucket" "repo-2" {
    name   = "repo-2"
    region = "ams3"
    force_destroy = true

    provisioner "local-exec" {
        
        command = "sed \"/access_key/c access_key = ${file (var.s3_access_id)} \" .s3cfg.template > .s3cfg"
    }
    provisioner "local-exec" {
        command = "sed -i \"/secret_key/c secret_key = ${file (var.s3_secret_key)}\" .s3cfg"
    }
    provisioner "local-exec" {
        command = "sed -i \"/host_bucket/c host_bucket = ${var.s3-name}.ams3.digitaloceanspaces.com\" .s3cfg"
    }
}

resource "digitalocean_droplet" "Build-server" {
    image = "ubuntu-18-04-x64"
    name = "Build"
    region = "fra1"
    size = "s-1vcpu-1gb"
     ssh_keys = [
      var.ssh_fingerprint
    ]
    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.pvt_key)
        timeout = "2m"
    }
    provisioner "remote-exec" {
        inline = [
            "export PATH=$PATH:/usr/bin",
            # install maven
            "sudo apt update",
            "sudo apt -y install maven",
            "sudo apt -y install s3cmd",
            "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
            "cd boxfuse-sample-java-war-hello",
            "mvn package"
        ]
    }
    provisioner "local-exec" {
            command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} ./.s3cfg root@${self.ipv4_address}:~/"
    }
    provisioner "remote-exec" {
        inline = [
            "s3cmd put ~/boxfuse-sample-java-war-hello/target/*.war s3://${var.s3-name}"
        ]
    }
}

resource "digitalocean_droplet" "Product-server" {
    image = "ubuntu-18-04-x64"
    name = "Production"
    region = "fra1"
    size = "s-1vcpu-1gb"
     ssh_keys = [
      var.ssh_fingerprint
    ]
    depends_on = [digitalocean_droplet.Build-server]

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.pvt_key)
        timeout = "2m"
    }
    provisioner "local-exec" {
            command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} ./.s3cfg root@${self.ipv4_address}:~/"
    }
    provisioner "remote-exec" {
        inline = [
            "export PATH=$PATH:/usr/bin",
            # install tomcat8
            "sudo apt update",
            "sudo apt -y install s3cmd",
            "sudo apt -y install tomcat8",
            "rm -rf /var/lib/tomcat8/webapps/*",
            "s3cmd get s3://${var.s3-name}/hello-1.0.war  /var/lib/tomcat8/webapps/ROOT.war",
            "service tomcat8 restart"
        ]
    }
}