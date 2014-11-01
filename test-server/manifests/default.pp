# Install Docker which is used to run the example web application container
include docker
# Allow the daemon to access the Docker registry in the other machine with insecure HTTP connection
file_line { "docker_registry_patch":
  path  => "/etc/init/docker.conf",
  line  => "        exec \"\$DOCKER\" -d --insecure-registry 192.168.42.101:5000 \$DOCKER_OPTS",
  match => "exec \"\\\$DOCKER\" -d .*\\\$DOCKER_OPTS"
}

# Install example web application and run the Docker container
docker::image { "192.168.42.101:5000/example-app": }
docker::run { "example-app":
  image   => "192.168.42.101:5000/example-app",
  ports   => "8080:8080",
  volumes => "/var/example-app:/var/example-app"
}
# Create the configuration file for the example web application
file { "/var/example-app":
  ensure => directory,
  owner  => "root",
  group  => "root"
}
file { "/var/example-app/example.properties":
  ensure => file,
  owner  => "root",
  group  => "root",
  content => "message=Hello perfect world"
}

# Ensure that the Vagrant user is member of the Docker group
user { "vagrant":
  name   => "vagrant",
  ensure => present,
  groups => ["adm", "cdrom", "sudo", "dip", "plugdev", "lpadmin", "sambashare", "docker"]
}
