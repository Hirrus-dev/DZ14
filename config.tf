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
            "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
            "cd boxfuse-sample-java-war-hello",
            "mvn package"
        ]
    }
    provisioner "local-exec" {
            command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} root@${self.ipv4_address}:~/boxfuse-sample-java-war-hello/target/*.war ."
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
    provisioner "remote-exec" {
        inline = [
            "export PATH=$PATH:/usr/bin",
            # install maven
            "sudo apt update",
            "sudo apt -y install tomcat8",
            "rm -rf /var/lib/tomcat8/webapps/*"
        ]
    }
    provisioner "file" {
        source      = "hello-1.0.war"
        destination = "/var/lib/tomcat8/webapps/ROOT.war"
    }
    provisioner "remote-exec" {
        inline = [
            "service tomcat8 restart"
        ]
    }
}