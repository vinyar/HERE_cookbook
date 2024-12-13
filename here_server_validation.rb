control 'apache up and running' do
  title 'Validate Apache Server Endpoints responding'

  # Define the server and endpoints
  # server_ip = '127.0.0.1' # Replace with the appropriate IP if needed
  # base_url = "http://#{server_ip}:8080/6.2"
  base_url = "http://localhost:8080/6.2"

  # Test the /isalive endpoint
  describe http("#{base_url}/isalive", method: 'GET') do
    its('status') { should cmp 200 } # Ensure HTTP 200 OK response
    its('body') { should match /excelRulesProvider/ } # Optional: Validate response content
  end

  # Test the /version endpoint
  describe http("#{base_url}/version", method: 'GET') do
    its('status') { should cmp 200 } # Ensure HTTP 200 OK response
    its('body') { should match /JLAM241Q0|MEX/ } # Optional: Validate response content
  end
end

control 'service configuration validation' do
  impact 0.7
  title 'service and folders configuration'
  desc 'An optional description ...'
  
  describe directory('/var/opt/Navteq/share/search/geocoder') do
    it { should exist }
    it { should be_directory }
    its('owner') { should eq 'navteq' }
    its('group') { should eq 'navteq' }
  end

  describe file('/etc/opt/Navteq/search-search6-aggregation-service-6.2.255.1.conf') do
    its('content') { should match(/^if \[ -d "\/opt\/tomcat" \]; then$/) }
    its('content') { should match(/^\s*CATALINA_HOME="\/opt\/tomcat"$/) }
    its('content') { should match(/^else$/) }
    its('content') { should match(/^\s*CATALINA_HOME="\/usr\/share\/tomcat8"$/) }
    its('content') { should match(/^fi$/) }
  end

  describe command("grep -A 4 'if.*tomcat' /etc/opt/Navteq/search-search6-aggregation-service-6.2.255.1.conf") do
    its('stdout') { should include('CATALINA_HOME') }
    its('exit_status') { should eq 0 }
  end

  describe group('navteq') do
    it { should exist }
  end

  describe user('navteq') do
    it { should exist }
    its('group') { should eq 'navteq' }
    its('home') { should eq '/opt/tomcat' }
    its('shell') { should eq '/bin/false' }
  end

  %w[
    /etc/opt/Navteq
    /var/opt/Navteq
    /opt/Navteq
    /opt/tomcat
  ].each do |dir|
    describe directory(dir) do
      it { should exist }
      it { should be_directory }
      its('owner') { should eq 'navteq' }
      its('group') { should eq 'navteq' }
      its('mode') { should cmp '0755' }
    end
  end    
end

control 'geocoder-map-data-configuration' do
  impact 1.0
  title 'Validate GeoCoder map data configuration'
  desc 'Ensure the GeoCoder map data directories are correctly configured with proper ownership and expected size'

  describe directory('/var/opt/Navteq/share/search/geocoder') do
    it { should exist }
    it { should be_directory }
    its('owner') { should eq 'navteq' }
    its('group') { should eq 'navteq' }
  end

  %w[
    /var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919
    /var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919
    /var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919
  ].each do |subdir|
    describe directory(subdir) do
      it { should exist }
      it { should be_directory }
      its('owner') { should eq 'navteq' }
      its('group') { should eq 'navteq' }
    end
  end

  %w[
    /var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919.tgz
    /var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919.tgz
    /var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919.tgz
  ].each do |file|
    describe file(file) do
      it { should_not exist }
    end
  end

  { "/var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919" => 65,
    "/var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919" => 44,
    "/var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919" => 94 }.each do |path, expected_size|
    describe command("du -s #{path} | cut -f1") do
      let(:size_in_gb) { subject.stdout.to_i / 1024 / 1024 }
      it "should be within +/- 5 GB of #{expected_size} GB" do
        expect(size_in_gb).to be_between(expected_size - 5, expected_size + 5)
      end
    end
  end
end

control 'nvt-service-validation' do
  impact 1.0
  title 'Validate Navteq Services'
  desc 'Ensure Navteq services are listed, running, and log files are correctly configured'

  describe command('systemctl list-units | grep nvt') do
    its('stdout') { should match(/nvt-services.service/) }
    its('stdout') { should match(/active/) }
  end

  describe command('/opt/Navteq/bin/search-search6-aggregation-service-6.2.255.1 status') do
    its('stdout') { should match(/Status of search-search6-aggregation-service-6.2.255.1:/) }
    its('stdout') { should match(/PID \d+ \(process watcher\) running/) }
    its('stdout') { should match(/PID \d+ \(search-search6-aggregation-service-6.2.255.1\) running/) }
  end

  %w[
    me2repository-6.2.255.1*@*.log
    search-search6-aggregation-service-6.2.255.1*@*.log
  ].each do |pattern|
    describe command("find /var/opt/Navteq/log/search-search6-aggregation-service-6.2.255.1 -type f -name '#{pattern}'") do
      its('stdout') { should_not be_empty }
    end

    describe command("find /var/opt/Navteq/log/search-search6-aggregation-service-6.2.255.1 -type f -name '#{pattern}' -exec stat -c '%U %G' {} \;") do
      its('stdout') { should match(/navteq navteq/) }
    end
  end
end


control 'OS level validation' do
  title 'Foundational pre-reqs'

  %w{
  s3fs-fuse
  epel-release
  awscli
  wget
  unzip
  jdk1.8.x86_64
  nvt-base-gc
  nvt-search-search6-aggregation-service-code
  nvt-search-search6-aggregation-service-config-msp-cust
  }.each do |package|

    describe package(package) do
      it { should be_installed }
    end
  end

  describe os_env('PATH') do
    its('content') { should match %r{/usr/java/jdk1.8.0_301-amd64/bin} }
  end

  describe file('/etc/profile') do
    its('content') { should match %r{/usr/java/jdk1.8.0_301-amd64} }
    its('content') { should match %r{/usr/java/jdk1.8.0_301-amd64} }
  end

  describe file('/etc/environment') do
    its('content') { should match %r{JAVA_HOME=/usr/java/jdk1.8.0_301-amd64} }
  end

  describe group('tomcat') do
    it { should exist }
  end

  describe user('tomcat') do
    it { should exist }
    its('group') { should eq 'tomcat' }
    its('home') { should eq '/opt/tomcat' }
    its('shell') { should eq '/bin/nologin' }
  end

  describe file('/opt/tomcat') do
    it { should exist }
    it { should be_directory }
    its('owner') { should eq 'navteq' }
    its('group') { should eq 'navteq' }
  end

  describe command('find /opt/tomcat/bin -type f -name "*.sh" -perm /u+x') do
    its('stdout') { should_not be_empty }
    its('exit_status') { should eq 0 }
  end

  describe file('/etc/systemd/system/tomcat.service') do
    it { should exist }
    its('content') { should match(/^Environment=JAVA_HOME=\/usr\/java\/jdk1\.8\.0_301-amd64$/) }
    its('content') { should match(/^User=navteq$/) }
    its('content') { should match(/^Group=navteq$/) }
    its('content') { should match(/^ExecStart=\/opt\/tomcat\/bin\/startup\.sh$/) } # This ensures Tomcat starts correctly
  end

  describe file('/etc/profile') do
    its('content') { should match(/^export JAVA_HOME=\/usr\/java\/jdk1\.8\.0_301-amd64$/) }
    its('content') { should match(/^export PATH=\$JAVA_HOME\/bin:\$PATH$/) }
    its('content') { should match(/^export CATALINA_HOME=\/opt\/tomcat$/) }
  end

  describe file('/etc/security/limits.conf') do
    its('content') { should match(/^navteq\s+soft\s+nofile\s+16348$/) }
    its('content') { should match(/^navteq\s+hard\s+nofile\s+16348$/) }
  end
end

control 'geocoder-map-data-configuration' do
  impact 1.0
  title 'Validate GeoCoder map data configuration'
  desc 'Ensure the GeoCoder map data directories are correctly configured with proper ownership and expected size'

  describe directory('/var/opt/Navteq/share/search/geocoder') do
    it { should exist }
    it { should be_directory }
    its('owner') { should eq 'navteq' }
    its('group') { should eq 'navteq' }
  end

  %w[
    /var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919
    /var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919
    /var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919
  ].each do |subdir|
    describe directory(subdir) do
      it { should exist }
      it { should be_directory }
      its('owner') { should eq 'navteq' }
      its('group') { should eq 'navteq' }
    end
  end

  %w[
    /var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919.tgz
    /var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919.tgz
    /var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919.tgz
  ].each do |file|
    describe file(file) do
      it { should_not exist }
    end
  end

  { "/var/opt/Navteq/share/search/geocoder/FGC_2024Q1.007.RR.20240919" => 65,
    "/var/opt/Navteq/share/search/geocoder/RGC_2024Q1.007.RR.20240919" => 44,
    "/var/opt/Navteq/share/search/geocoder/UDM_2024Q1.007.RR.20240919" => 94 }.each do |path, expected_size|
    describe command("du -s #{path} | cut -f1") do
      let(:size_in_gb) { subject.stdout.to_i / 1024 / 1024 }
      it "should be within +/- 5 GB of #{expected_size} GB" do
        expect(size_in_gb).to be_between(expected_size - 5, expected_size + 5)
      end
    end
  end
end



control 'base system configuration validation' do
  title 'Basic system level validation'

  # checking system architecture
  describe os.arch do
    it { should eq 'x86_64' }
  end

  # checking number of processors
  describe command('nproc'), desc: '--> Alex Alex Alex <--' do
    its('stdout.to_i') { should be >= 8 }
  end

  # checking total memory
  describe file('/proc/meminfo'), '--> Alex Alex Alex <--' do
    it 'should have at least 60 GB of memory' do
      mem_total = subject.content.match(/MemTotal:\s+(\d+)/)[1].to_i
      expect(mem_total).to be >= (60 * 1024) # 60 GB in KB
    end
  end

  # Check available storage for root mount
  describe command("df --output=avail --block-size=1G / | tail -1") do
    its('stdout.to_i') { should be >= 50 } # Available storage >= 50 GB
  end

  # Check total storage for the drive containing /var/opt/Navteq/log/search-search6-aggregation-service-6.2.255.1
  describe command("df --output=size --block-size=1G /var/opt/Navteq/log/search-search6-aggregation-service-6.2.255.1 | tail -1") do
    its('stdout.to_i') { should be >= 400 } # Total storage > 400 GB
  end

  # Check storage for the drive containing the directory
  directory_path = '/var/opt/Navteq/log/search-search6-aggregation-service-6.2.255.1'

  # # Validate the mount point of the directory (if expected to be mounted)
  # describe mount(directory_path) do
  #   it { should be_mounted }
  # end

  # Validate storage associated with the directory's filesystem
  describe filesystem(directory_path) do
    it 'should have total storage > 300 GB' do
      expect(subject.size_kb / (1024 * 1024)).to be > 300 # Convert KB to GB
    end

    it 'should have available storage >= 50 GB' do
      expect(subject.free_kb / (1024 * 1024)).to be >= 50 # Convert KB to GB
    end
  end
end



# Bugs:
# describe command("df --total --block-size=1G | grep total") do
#   it 'should have total storage > 300 GB' do
#     total_storage = subject.stdout.match(/total\s+(\d+)\s+/)[1].to_i
#     expect(total_storage).to be > 300
#   end

#   it 'should have available storage >= 50 GB' do
#     available_storage = subject.stdout.match(/total\s+\d+\s+\d+\s+(\d+)\s+/)[1].to_i
#     expect(available_storage).to be >= 50
#   end

#   describe command("df --output=avail --block-size=1G / | tail -1", redact_regex: /d.*/) do
#     its('stdout.to_i') { should be >= 50 } # Available storage >= 50 GB
#   end

  # describe command("df --output=avail --block-size=1G / | tail -1") do
  #   its('stdout.to_i') { should be >= 50 } # Available storage >= 50 GB
  # end

