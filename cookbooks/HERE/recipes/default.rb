#
# Cookbook:: HERE
# Recipe:: default
#
# Copyright:: 2024, The Authors, All Rights Reserved.

execute 'updating yum servers' do
    command <<-EOF
        sudo sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
        sudo sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
        sudo sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo
        sudo yum clean all
        sudo yum makecache
    EOF
    not_if 'cat /etc/yum.repos.d/CentOS-*.repo | grep "vault.centos.org"'
    action :run
end

package 'Installing system packages' do
    package_name %w(nano wget sed rpm unzip cloud-utils-growpart epel-release)
    action :install
end

package 'Installing cronolog from epel' do
    package_name %w(epel-release cronolog)
    action :install
end

# setting timezone
execute 'set time zone' do
    command 'sudo timedatectl set-timezone America/Los_Angeles'
    not_if 'timedatectl | grep "Time zone: America/Los_Angeles"'
end

## vbox hard drive is set to 200 GB in the Vagrant file
execute 'grow partition to fill allocated vbox space' do
    command <<-EOF
        sudo growpart /dev/sda 1
        sudo file -sL /dev/sda1
        sudo xfs_growfs /
    EOF
    action :run
    not_if "lsblk -no SIZE /dev/sda1 | grep 'G' | awk '{if ($1+0 >= 200) exit 0; else exit 1}'"
end

package 'installing java 8 - jdk-8u301-linux-x64' do
    package_name 'jdk-8u301-linux-x64'
    source '/vagrant/here_pre-reqs/jdk-8u301-linux-x64.rpm'    # Path to the local RPM file
    options '-vv'        # Additional options passed to the underlying RPM command
    action :install
end

## Install Tomcat - copy file locally
# remote_file '/opt/apache-tomcat-8.5.28.tar' do
#     source 'file:///vagrant/here_pre-reqs/apache-tomcat-8.5.28.tar'
#     owner 'root'
#     group 'root'
#     mode '0755'
#     action :create
# end

directory '/opt/tomcat' do
    # owner 'navteq'  # at this point correct users dont exist yet.
    # group 'navteq'  # at this point correct users dont exist yet.
    mode '0755'
    action :create
end

execute 'extract_tomcat' do
    command 'tar -zxvf /vagrant/here_pre-reqs/apache-tomcat-8.5.28.tar -C /opt/tomcat  --strip-components=1'
    # optimization - untar with permissions already set to a+r
    # command 'umask 022 && tar -zxvf /vagrant/here_pre-reqs/apache-tomcat-8.5.28.tar -C /opt/tomcat  --strip-components=1'
    not_if { ::File.directory?('/opt/tomcat') && ::File.size?('/opt/tomcat/bin/catalina.sh') }
end

#### updating path for Java and Tomcat - via line cookbook
append_if_no_line 'update profile for JAVA_HOME' do
    sensitive false
    path '/etc/profile'
    line 'JAVA_HOME=/usr/java/jdk1.8.0_301-amd64'
end

append_if_no_line 'update profile for CATALINA_HOME' do
    sensitive false
    path '/etc/profile'
    line 'CATALINA_HOME=/opt/tomcat'
end

replace_or_add 'update profile path' do
    sensitive false
    path '/etc/profile'
    pattern '^export PATH=.*ORION.*\$PATH'
    line 'export PATH=$JAVA_HOME/bin:$CATALINA_HOME:ORION:$PATH'
end

#### Updating Limits file
append_if_no_line 'setting soft limit' do
    sensitive false
    path '/etc/security/limits.conf'
    line 'navteq soft nofile 16348'
end

append_if_no_line 'setting hard limit' do
    sensitive false
    path '/etc/security/limits.conf'
    line 'navteq hard nofile 16348'
end

#### Preparing and Installing Nav Base
## creating empty folder to avoid RPM failure. Base installer will update permissions.
directory '/var/opt/Navteq' do
    action :create
    owner 'navteq'
    group 'navteq'
end

## creating empty folder to avoid RPM failure. Base installer will update permissions.
directory '/opt/Navteq' do
    action :create
    owner 'navteq'
    group 'navteq'
end

## Installing NVT Base RPM
## Note: this install fails to create navteq home folders, so it's done above.
package 'installing nvt-base' do
    package_name 'nvt-base-gc'
    source '/vagrant/here_bits/nvt-base-gc-2.1.0-8.el6.noarch.rpm'
    options '-vv'
    action :install
    # sudo rpm -ihvv /vagrant/here_bits/nvt-base-gc-2.1.0-8.el6.noarch.rpm    # manual command for reference
    # action :nothing      # <----- done manually for testing
end


#### Preparing and installing NVT Search components
package 'installing search6 code' do
    package_name 'nvt-search-search6-aggregation-service-code'
    source '/vagrant/here_bits/nvt-search-search6-aggregation-service-code-6.2.255.1-1.noarch.rpm'
    options '-vv'
    action :install
    # sudo rpm -ihvv nvvt-search-search6-aggregation-servicecode-6.2.255.1-1.noarch.rpm    # manual command for reference
    # action :nothing      # <----- done manually for testing
end

package 'installing search6 config' do
    package_name 'nvt-search-search6-aggregation-service-config-msp-cust'
    source '/vagrant/here_bits/nvt-search-search6-aggregation-service-config-msp-cust-6.2.255.1-1.noarch.rpm'
    options '-vv'
    action :install
    # sudo rpm -ihvv nvt-search-search6-aggregation-service-config-msp-cust-6.2.255.1-1.noarch.rpm    # manual command for reference
    # action :nothing      # <----- done manually for testing
end

## modify NVT Search config to update location of tomcat - manual for now 
## note: (if default 'apache-tomcat-8.5.28' folder name is used, this wont be needed)
# template '/etc/opt/Navteq/search-search6-aggregationservice-6.2.255.1.conf'
# or
# execute 'sed'

# <<< ?? Missing step ?? >>>
# modify /etc/opt/Navteq/m2...conf with similar updates to above

#### Updating permissions
## update tomcat directory permissions
directory '/opt/tomcat' do
    owner 'navteq'
    group 'navteq'
    mode '0755'
    recursive true
    action :create
end

execute 'update folder permissions' do
    command <<-EOF
    sudo chown -R navteq:navteq /opt/tomcat
    sudo chown -R navteq:navteq /etc/opt/Navteq/
    sudo chown -R navteq:navteq /var/opt/Navteq/
    sudo chown -R navteq:navteq /opt/Navteq/
    # sudo chmod -R a+r /opt/tomcat
    sudo chmod -R 755 /opt/tomcat
    sudo chmod -R 755 /etc/opt/Navteq/
    sudo chmod -R 755 /var/opt/Navteq/
    sudo chmod -R 755 /opt/Navteq/
    EOF
    action :run
    not_if 'find /var/opt/Navteq -not -user navteq -or -not -group navteq'
end

## Creating tomcat configuration
template '/etc/systemd/system/tomcat.service' do
    source 'tomcat.service.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    notifies :run, 'execute[reload Tomcat]', :immediate
    # notifies :enable, 'service[tomcat]', :immediate
    # notifies :start, 'service[tomcat]', :immediate
end

execute 'reload Tomcat' do
    command 'systemctl daemon-reload'
    action :nothing
end

service 'tomcat' do
    # action [:enable, :start]
    action :nothing
end


# /opt/tomcat/conf/server.xml
# insert in <Host> block: 
# <Value className="org.apache.catalina.valves.RemoteAddrValve" allow=".*" />

# enable external access
# /opt/tomcat/webapps/host-manager/META-INF/context.xml
# add .* (or your ip 10.* for virtual box) to RemoteAddrValve so it looks like this:
# allow="127\.\d+\.\d+\.\d+|::1|.*|0:0:0:0:0:0:0:1"

# enable external access
# /opt/tomcat/webapps/manager/META-INF/context.xml
# add .* (or your ip 10.* for virtual box) to RemoteAddrValve so it looks like this:
# allow="127\.\d+\.\d+\.\d+|::1|.*|0:0:0:0:0:0:0:1"

# create Tomcat users
# file: /opt/tomcat/conf/tomcat-users.xml
# add within <tomcat-users> block:
# <role rolename="admin-gui"/>
# <role rolename="manager-gui"/>
# <user username="tomcat" password="s3cret" roles="manager-gui,admin-gui,manager-jmx,manager-status"/>


## prepping for Map Data
## Creating folder 
directory '/var/opt/Navteq/share/search' do
    owner 'navteq'
    group 'navteq'
    # mode '0755'
    recursive true
    action :create
end


directory '/var/opt/Navteq/share/search/geocoder/' do
    owner 'navteq'
    group 'navteq'
    # mode '0755'
    recursive true
    action :create
end

execute 'untar RGC map data' do
    user 'navteq'
    command 'tar -xvzf /vagrant/here_bits/RGC_2024Q1.007.RR.20240919.tgz -C /var/opt/Navteq/share/search/geocoder/'
    live_stream true
    action :nothing
    not_if { ::File.exist?('/var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919/engine.xml') }
end

execute 'untar FGC map data' do
    user 'navteq'
    command 'tar -xvzf /vagrant/here_bits/FGC_2024Q1.007.RR.20240919.tgz -C /var/opt/Navteq/share/search/geocoder/'
    live_stream true
    action :nothing
    not_if { ::File.exist?('/var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919/engine.xml') }
end

execute 'untar UMD map data' do
    user 'navteq'
    command 'tar -xvzf /vagrant/here_bits/UDM_2024Q1.007.RR.20240919.tgz -C /var/opt/Navteq/share/search/geocoder/'
    live_stream true
    action :nothing
    not_if { ::File.exist?('/var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919/engine.xml') }
end

directory '/var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919' do
    owner 'navteq'
    group 'navteq'
    action :create
end

directory '/var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919' do
    owner 'navteq'
    group 'navteq'
    action :create
end

directory '/var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919' do
    owner 'navteq'
    group 'navteq'
    action :create
end




#############################   END

## Removing granular config until everything is running.
## recursively apply tomcat permissions
# execute 'recursive_read_permission' do
#     command 'chmod -R a+r /opt/tomcat'
#     action :run
#     # Guard to run only if any files within /opt/tomcat do not have the correct permissions
#     not_if "find /opt/tomcat ! -perm -004 -print -quit | grep -vq ."
# end


## Removing in favor of them being created by the navteq base package
# group 'nvtinstall' do
#     members 'members'
#     action :create
#     gid '498'
# end

# group 'navteq' do
#     members 'members'
#     action :create
#     gid '499'
# end

# user 'nvtinstall' do
#     comment 'comment'
#     uid '498'
#     home 'home_folder'
##     system yes # not sure if this is real. -r flag
#     action :create
# end

# user 'navteq' do
#     comment 'comment'
#     uid '499'
#     home 'home_folder'
#     action :create
# end

# # Apache Tomcat 8 or 9 servlet container (8.5.28 or 9.0.10 recommended)
# # https://supermarket.chef.io/cookbooks/tomcat
# tomcat_install 'tomcat' do
#     version '9.0.10'
#     verify_checksum false
#     install_path '/opt/tomcat' # using default for now
# #     create_user true
# #     create_group true
# end
# tomcat_service 'tomcat' do
#     action [:create]
# end
# tomcat_service 'tomcat' do
#     action [:enable, :start]
# end
# # Apache Tomcat 8 or 9


# Java as JRE or JDK. (version 8 only)
# 	Note: Only from Java.com. Do not use OpenJava or any other Java implementation.
# 	Note: have an up to date time zone database for Java
# 		Timezone data can be updated without having to upgrade JRE

# node.normal["java"]["jdk_version"] = "8"
# node.normal["java"]["install_flavor"] = "oracle"
# node.normal['java']['jdk']['7']['x86_64']['url'] = "http://localmirror/jdk-7u21-linux-x64.tar.gz"
# node.normal['java']['jdk']['7']['x86_64']['checksum'] = "thechecksum"    

### Java cookbook version 8 // https://supermarket.chef.io/cookbooks/java/versions/8.0.0
# include_recipe 'java'

# later versions of cookbook went to custom resources
# java 'install oracle java' do
#     source 'file:///vagrant/here_pre-reqs'
#     install_flavor 'oracle'
#     version '8'
# end


# Java - Update timezone database for the specific version of JRE in use (Java Runtime Environment).
# Java includes this and seems to work fine. Skipping


## Debugging RPM installer
    # Install in extra detailed mode:
# sudo RPM_DEBUG_LEVEL=8 rpm -ivvh --trace nvt-base-gc-2.1.0-8.el6.noarch.rpm &> rpm_install_debug.log
    # Install in extra detailed mode and skipping scripts (bad as scripts are needed)
# sudo RPM_DEBUG_LEVEL=8 rpm -ivh --noscripts --test --trace nvt-base-gc-2.1.0-8.el6.noarch.rpm
    # figuring out what pre and post install scripts do.
# rpm -qp --scripts nvt-base-gc-2.1.0-8.el6.noarch.rpm
    # more RPM debugging. See every system call RPM does.
# sudo strace -f -o rpm_debug_trace.log rpm -ivvh nvt-base-gc-2.1.0-8.el6.noarch.rpm
    # SELinux permission denied messages and convert them to rules
# sudo ausearch -m AVC -ts recent | audit2allow
    # temporarily changes the SELinux mode to permissive mode. (defined in /etc/selinux/config)
# sudo setenforce 0
    # various logs
# sudo tail -f /var/log/messages
# /var/log/audit/audit.log
# /var/log/syslog
# /opt/tomcat/logs/
# /var/log/tomcat/


# RPM debugging flow
# 1: test integrity of the RPM
# sudo rpm -K nvt-base-gc-2.1.0-8.el6.noarch.rpm

# 2: test dependecies
# sudo rpm -ivvh --test nvt-base-gc-2.1.0-8.el6.noarch.rpm

# 3: Sniplet inspection
# rpm -qp --scripts nvt-base-gc-2.1.0-8.el6.noarch.rpm

# 4 install in detailed mode - debug level rpm installer
# sudo RPM_DEBUG_LEVEL=8 rpm -ivvh nvt-base-gc-2.1.0-8.el6.noarch.rpm # <<----

# 5: system call debug level (captures permission issues)
# super duper detailed
# sudo strace -f -o rpm_debug_trace.log rpm -ivh nvt-base-gc-2.1.0-8.el6.noarch.rpm

# Changing user home after user has already been created.
# sudo usermod -d /opt/apache-tomcat-8.5.28 navteq


# impersonating a user as opposed to sudo su
# sudo -u navteq -i


# troubleshooting disk size and growing mounted disk
# sudo yum install -y cloud-utils-growpart
# sudo growpart /dev/sda 1
# sudo pvresize /dev/sda1
# sudo lvextend -L 200G /dev/mapper/VolGroup-lv_root
# sudo resize2fs /dev/mapper/VolGroup-lv_root

## validate disk (extra)
# set PATH=%PATH%;"C:\Program Files\Oracle\VirtualBox"
# VBoxManage showhdinfo "C:\Users\alvin\VirtualBox VMs\HERE-geocache-karups_default_1731383688330_93272\box-disk001.vmdk"


#### NVT Config RPM observations:
# /etc/cron.daily/nvt-logrotate.sh
# /etc/opt/Navteq/me2repository-6.2.255.1.conf
# /etc/opt/Navteq/search-search6-aggregation-service-6.2.255.1.conf
# /etc/opt/Navteq/search-search6-aggregation-service-6.2.255.1/conf/Catalina

# /opt/Navteq/share/search-search6-aggregation-service-6.2.255.1

# validate /etc/nvt-services.conf

# logs:
# service: /var/opt/Navteq/log/search-search6-aggregation-service-6.2.255.1/
# tomcat: /opt/tomcat/logs

# starting / stopping services
# sudo /opt/Navteq/bin/search-search6-aggregationservice-6.2.255.1 status

# validation:
# http://localhost:8080/6.2/version.txt
# http://localhost:8080/6.2/isalive

# thoughts:
# maybe /etc/opt/Navteq/search-search6-aggregation-service-6.2.255.1/conf/server.xml is not setup right

# do we need to chance tomcat location here: /etc/opt/Navteq/me2repository-6.2.255.1.conf
# do we need to modify search/server.xml somewhere (page ~28) to enable connector