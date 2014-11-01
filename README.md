Automatic deployment with Jenkins and Docker
============================================

This is a small demo project that illustrates how automatic deployment of Java web applications can be simplified by using [Docker](https://www.docker.com/) images and a private Docker registry.

Overview
--------

The first goal is to have a running Jenkins build server with a build job that retrieves an example Java web application project from a local Git bare repository, executes a Maven build, creates a ready-to-run Docker image for that application and pushes the image to a private Docker registry running on the same machine.

The second goal is to have a running test machine which pulls the example web application's Docker image from the private registry and starts a Docker container that runs the application.

Most of the tasks to accomplish these goals have been automated using Vagrant and Puppet, so you won't be hacking a lot of commands on the Unix shell. The following sections will guide you through the installation process and explain each step.

Directory structure:

    /
    +- build-server
        +- manifests/default.pp     ( Puppet manifest to set up the build server )
        +- modules/...              ( Puppet modules required by the default manifest )
        +- Vagrantfile              ( Vagrant project file to set up the build server machine )
    +- example-app.git              ( Git bare repository containing the example webapp )
    +- test-server
        +- manifests/default.pp     ( Puppet manifest to set up the test server )
        +- modules/...              ( Puppet modules required by the default manifest )
        +- Vagrantfile              ( Vagrant project file to set up the test server machine )

Prerequisites
-------------

Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/) because the project will use this infrastructure to build the two virtual machines.

Setting up the build server
---------------------------

1.  Open a command line console and go to the `/build-server` directory of the project.
2.  Run the command `vagrant up`.
    This will take some time since Vagrant has to download the Ubuntu image, Puppet needs to install Docker and Docker finally must download the Registry image.
    Don't be confused if there are quite a lot of errors during the first Puppet run. This is because the dependencies between the resources are not declared within the Puppet manifest.
3.  Run `vagrant provision` at least two times to start Puppet provisioning again.
    This ensures that all changes are applied as soon as their dependencies are installed appropriately. In the final run there should be no more errors.
4.  Run the command `vagrant reload` to restart the virtual machine.
    This is required to start the Docker deamon with the new configuration allowing plain HTTP access to the private registry.
5.  Once the machine is up again, open a web browser in your host operating system and go to the address: http://192.168.42.101:8080/
    If everything works you should see the welcome page of the Jenkins build server.
6.  Navigate to the Jenkins system configuration or go to: http://192.168.42.101:8080/configure
7.  Add a **JDK** installation and set the following configuration:
    - Name: Default
    - Automatic installation: Off
    - JAVA_HOME: `/usr/lib/jvm/java-7-openjdk-amd64`
8.  Add a **Maven** installation and set the following configuration:
    - Name: Default
    - Automatic installation: Off
    - MAVEN_HOME: `/opt/apache-maven-3.2.3`
9.  Save the system settings.
10. Create a new Jenkins job to build the example web application Maven project.
11. Select **Git** as the Source-Code-Management system and set the following configuration:
    - Repository URL: `/var/git-repositories/example-app.git`
12. Add a post-build step **Docker build and publish** and set the following configuration:
    - Repository Name: `localhost:5000/example-app`
13. Save the job settings.
14. Start the build job.
    Jenkins will now perform a Maven build of the web application, create a ready-to-run Docker image containing the application and push that image to the private Docker registry. Be patient, this may take some time on the first run.

Setting up the test environment
-------------------------------

1.  Open a command line console and go to the `/test-server` directory of the project.
2.  Run the command `vagrant up`.
    Again, this will take a minute to create and start the virtual machine.
    As with the build server configuration there will be a lot of errors in the first Puppet run. Don't be concerned...
3.  Run `vagrant provision` to start another Puppet run.
    This ensures that the Docker daemon is configured to allow plain HTTP access to the private registry on the build server. Nevertheless, you will get the following provisioning error:
    
    *Error: Invalid registry endpoint https://192.168.42.101:5000/v1/: Get https://192.168.42.101:5000/v1/_ping: EOF. If this private registry supports only HTTP or HTTPS with an unknown CA certificate, please add `--insecure-registry 192.168.42.101:5000` to the daemon's arguments. In the case of HTTPS, if you have access to the registry's CA certificate, no need for the flag; simply place the CA certificate at /etc/docker/certs.d/192.168.42.101:5000/ca.crt*
    
    But don't be frustrated, the next step will take care of that. :-)
4.  Run the command `vagrant reload` to restart the virtual machine.
    The Docker daemon is now run with the new configuration allowing unencrypted access to the private Docker registry.
5.  Run `vagrant provision` again to start another Puppet run.
    This time there should be no errors and the image of the example web application is pulled from the registry.
6.  Open a web browser in your host operating system and go to the address: http://192.168.42.102:8080/
    You should see the welcome page of the example web application.

Playing a little bit
--------------------

You can see the automated deployment in action by doing some changes to the web application like this:

1.  Clone the Git repository of the example web application.
2.  Make some changes to the application, maybe add some HTML to the welcome page `/src/main/webapp/WEB-INF/view/welcome.jsp`.
3.  Commit and push your changes to the bare repository.
4.  Run the Jenkins build job one more time. This produces a new Docker image for the web application and pushes it to the private registry.
5.  Run the provisioning of the test server one more time. This will pull the new image from the registry and start a Docker container with the new application version.

Some more words about the example application:

It's a Spring MVC application which simply displays a welcome page with a configurable text. The Dockerfile of the project ensures that the application is deployed in the root context of the Tomcat server. Moreover, it links the directory `/var/example-app` as a volume into the container and configures the web application to use it as home directory. The application expects to find a configuration file `example.properties` in this home location. On the test machine this file is generated by the Puppet manifest.

Using a volume for configuration directories has the advantage that all files are stored in the file system of the host operating system and are simply linked into the Docker container. They remain untouched even when the container is removed or a new version is started - no need to create a separate image for each configuration.

Enjoy. :-)
