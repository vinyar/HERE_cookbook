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
    package_name %w(nano wget sed rpm unzip cloud-utils-growpart)
    action :install
end

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

## Install Tomcat - pull down file locally
# remote_file '/opt/apache-tomcat-8.5.28.tar' do
#     source 'file:///vagrant/here_pre-reqs/apache-tomcat-8.5.28.tar'
#     owner 'root'
#     group 'root'
#     mode '0755'
#     action :create
# end

directory '/opt/tomcat' do
    # owner 'root'  # at this point correct users dont exist yet.
    # group 'root'  # at this point correct users dont exist yet.
    mode '0755'
    action :create
end

execute 'extract_tomcat' do
    command 'tar -zxvf /vagrant/here_pre-reqs/apache-tomcat-8.5.28.tar -C /opt/tomcat  --strip-components=1'
    not_if { ::File.directory?('/opt/tomcat') && ::File.size?('/opt/tomcat/bin/catalina.sh') }
end

# line cookbook
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

# append_if_no_line 'setting initial tokenized path management' do
#     sensitive false
#     path '/etc/profile'
#     line 'export PATH=$ORION:$PATH'
# end

replace_or_add 'update profile path' do
    sensitive false
    path '/etc/profile'
    pattern '^export PATH=.*ORION.*\$PATH'
    line 'export PATH=$JAVA_HOME/bin:$CATALINA_HOME:ORION:$PATH'
end

### Updating Limits file
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
## creating empty folder to avoid RPM failure. Base will update permissions.
directory '/var/opt/Navteq' do
    action :create
end

## creating empty folder to avoid RPM failure. Base will update permissions.
directory '/opt/Navteq' do
    action :create
end

## Installing Base RPM
## Note: this install fails to create navteq home folders, so it's done above.
package 'installing nvt-base' do
    package_name 'nvt-base-gc-2.1.0-8.el6'
    source '/vagrant/here_bits/nvt-base-gc-2.1.0-8.el6.noarch.rpm'
    # sudo rpm -ihvv /vagrant/here_bits/nvt-base-gc-2.1.0-8.el6.noarch.rpm
    options '-vv'
    # action :install
    action :nothing
end

## Validating just in case (can be a test later)
directory '/var/opt/Navteq' do
    owner 'navteq'
    group 'navteq'
    # mode '0755'
    recursive true
    action :nothing
end

directory '/var/opt/Navteq/share/search' do
    owner 'navteq'
    group 'navteq'
    # mode '0755'
    recursive true
    action :create
end


package 'installing search-search6-aggregation-service' do
    package_name 'nvt-search-search6-aggregation-service-code-6.2.255.1-1.noarch'
    source '/vagrant/here_bits/nvvt-search-search6-aggregation-servicecode-6.2.255.1-1.noarch.rpm'
    # sudo rpm -ihv nvvt-search-search6-aggregation-servicecode-6.2.255.1-1.noarch.rpm
    options '-vv'
    # action :install
    action :nothing
end




## prepping for Map Data
directory '/var/opt/Navteq/share/search/geocoder/' do
    owner 'navteq'
    group 'navteq'
    # mode '0755'
    recursive true
    action :create
end

execute 'untar map data' do
    command 'tar -xvzf /vagrant/here_bits/RGC_2024Q1.007.RR.20240919.tgz -C /var/opt/Navteq/share/search/geocoder/'
    action :nothing
end






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
#   random parameters below
#     source ??
#     install_flavor 'oracle'
#     version '8'
# end

## package // service approach
# -- or can just download file -- assuming i can get past password page
# -- or host file locally -- 
# https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html
# from Java.com - https://www.java.com/en/download/linux_manual.jsp


# Java - Update timezone database for the specific version of JRE in use (Java Runtime Environment).
# Cronolog  (recommended: cronolog-1.6.2)
# 	Default configuration is fine

# Sed (system app - located at /usr/bin)
# Rpm (scripts use rpm installer)

# sudo RPM_DEBUG_LEVEL=8 rpm -ivvh --trace nvt-base-gc-2.1.0-8.el6.noarch.rpm &> rpm_install_debug.log
# sudo RPM_DEBUG_LEVEL=8 rpm -ivh --noscripts --test --trace nvt-base-gc-2.1.0-8.el6.noarch.rpm
# rpm -qp --scripts nvt-base-gc-2.1.0-8.el6.noarch.rpm
# sudo ausearch -m AVC -ts recent | audit2allow
# sudo setenforce 0
# sudo tail -f /var/log/messages
# /var/log/audit/audit.log
# /var/log/syslog
# sudo strace -f -o rpm_debug_trace.log rpm -ivh nvt-base-gc-2.1.0-8.el6.noarch.rpm



# 1: test integrity of the RPM
# sudo rpm -K nvt-base-gc-2.1.0-8.el6.noarch.rpm

# 2: test dependecies
# sudo rpm -ivvh --test nvt-base-gc-2.1.0-8.el6.noarch.rpm

# 3: Sniplet inspection
# rpm -qp --scripts nvt-base-gc-2.1.0-8.el6.noarch.rpm

# 4 install in detailed mode - debug level rpm installer
# sudo RPM_DEBUG_LEVEL=8 rpm -ivvh nvt-base-gc-2.1.0-8.el6.noarch.rpm # <<----

# 5: every system call debug level
# captures permission issues
# super duper mega detailed to the point of being unnecessary
# sudo strace -f -o rpm_debug_trace.log rpm -ivh nvt-base-gc-2.1.0-8.el6.noarch.rpm


# sudo rpm -ihvv nvt-search-search6-aggregation-servicecode-6.2.255.1-1.noarch.rpm

# not done
# sudo chown -R navteq:navteq /etc/opt/Navteq/
# sudo chown -R navteq:navteq /opt/Navteq/

# sudo useradd -g navteq -s /bin/false -d /opt/tomcat navteq
# sudo usermod -d /opt/apache-tomcat-8.5.28 navteq

# meta-inf = /opt/apache-tomcat-8.5.28/webapps/host-manager/META-INF
# set allow to 127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|.*
# or
# 10.0.2.2 for vagrant IP

#untar
# sudo -u navteq -i
#tar -xvzf RGC_2024Q1.007.RR.20240919.tgz -C /var/opt/Navteq/share/search/geocoder/

# Looks like the OS i am using has OS drive set to 40 GB max
# drive needs to be expanded
# sudo resize2fs /dev/sdX (/dev/sda1)

# sudo growpart /dev/sda 1
# sudo pvresize /dev/sda1
# sudo lvextend -L 200G /dev/mapper/VolGroup-lv_root
# sudo resize2fs /dev/mapper/VolGroup-lv_root


## validate disk (extra)
# set PATH=%PATH%;"C:\Program Files\Oracle\VirtualBox"
# VBoxManage showhdinfo "C:\Users\alvin\VirtualBox VMs\HERE-geocache-karups_default_1731383688330_93272\box-disk001.vmdk"
# sudo yum install -y cloud-utils-growpart

############## Add to exec or vagrant init script:
# sudo growpart /dev/sda 1
# sudo file -sL /dev/sda1
# sudo xfs_growfs /





