Vagrant.configure("2") do |config|

config.vm.box = "generic/rocky9"

nodes = {
"jenkins" => { ip: "192.168.56.203", ram: 4096, cpu: 2 },
"awx"     => { ip: "192.168.56.204", ram: 8192, cpu: 2 },
"docker"  => { ip: "192.168.56.205", ram: 2048, cpu: 1 },
"ansible" => { ip: "192.168.56.206", ram: 2048, cpu: 1 },
"tomcat"  => { ip: "192.168.56.207", ram: 2048, cpu: 1 }
}

nodes.each do |name, specs|

```
config.vm.define name do |node|

  node.vm.hostname = name

  node.vm.network "private_network", ip: specs[:ip]

  node.vm.provider "virtualbox" do |vb|
    vb.name   = name
    vb.memory = specs[:ram]
    vb.cpus   = specs[:cpu]
  end

  node.vm.provision "shell", inline: <<-SHELL

    dnf update -y

    hostnamectl set-hostname #{name}

    echo "root:root" | chpasswd

    id jack >/dev/null 2>&1 || useradd -m jack
    echo "jack:root" | chpasswd

    usermod -aG wheel jack

    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel

    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

    systemctl restart sshd
```

cat > /etc/hosts << EOF
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.56.203 jenkins.example.com jenkins
192.168.56.204 awx.example.com awx
192.168.56.205 docker.example.com docker
192.168.56.206 ansible.example.com ansible
192.168.56.207 tomcat.example.com tomcat

127.0.1.1 #{name}.example.com #{name}
EOF

```
  SHELL

end
```

end
end
