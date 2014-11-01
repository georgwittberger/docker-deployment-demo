# Install Git (required by Jenkins to fetch projects from a Git repository)
include git

# Install Docker (required by Jenkins to build images and used to run the local Docker registry)
include docker
# Allow the daemon to access the local Docker registry with insecure HTTP connection
file_line { "docker_registry_patch":
  path  => "/etc/init/docker.conf",
  line  => "        exec \"\$DOCKER\" -d --insecure-registry localhost:5000 \$DOCKER_OPTS",
  match => "exec \"\\\$DOCKER\" -d .*\\\$DOCKER_OPTS"
}

# Install local Docker registry
docker::image { "registry": }
file { "/var/docker-registry":
  ensure => "directory",
  owner  => "root",
  group  => "root",
  mode   => 770
}
docker::run { "registry":
  image   => "registry",
  ports   => "5000:5000",
  env     => "STORAGE_PATH=/var/docker-registry",
  volumes => "/var/docker-registry:/var/docker-registry"
}

# Install Maven (required by Jenkins to build Maven projects)
class { "maven::maven":
  version => "3.2.3",
  repo => {
    url => "http://repo.maven.apache.org/maven2"
  }
}

# Install Jenkins build server
include jenkins
# Install the Git plugin for Jenkins and all required dependencies
jenkins::plugin {
  "credentials" : ;
}
jenkins::plugin {
  "ssh-credentials" : ;
}
jenkins::plugin {
  "git-client" : ;
}
jenkins::plugin {
  "scm-api" : ;
}
jenkins::plugin {
  "git" : ;
}
# Install the Docker plugin for Jenkins and all required dependencies
jenkins::plugin {
  "token-macro" : ;
}
jenkins::plugin {
  "docker-build-publish" : ;
}

# Ensure that the Vagrant user is member of the Docker group
user { "vagrant":
  name   => "vagrant",
  ensure => "present",
  groups => ["adm", "cdrom", "sudo", "dip", "plugdev", "lpadmin", "sambashare", "docker"]
}
# Ensure that the Jenkins user is member of the Docker group
user { "jenkins":
  name   => "jenkins",
  ensure => "present",
  groups => ["docker"]
}
