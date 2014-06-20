require "fileutils"


SYNCED_DOWNLOAD_CACHE_FOLDER = { host: "cache", guest: "/.vagrant_download_cache" }


module Provision
  module Setup
    
    # Setup :Box, "OSX109"
    module Box
      def osx(box)
        @vagrant_config.vm.box = box      # TODO: @vagrant_config should be a function call
      end
    end
  
    # Setup :Provider, "vmware_fusion", "MyProjectDevEnv"
    module Provider
      def osx(provider, vm_name)
        @vagrant_config.vm.provider(provider) do |vb|
          vb.name = vm_name
          vb.gui = true
        end
      end
    end
  
    # Setup :SyncedFolder, { host: "~/", guest: "/.vagrant_host_home" }
    module SyncedFolder
      def osx(synced_folder)
        create_if_missing(synced_folder[:host])
        @vagrant_config.vm.synced_folder synced_folder[:host], synced_folder[:guest]
      end
    end
  
    # Setup :ForwardedPort, { guest: 4000, host: 4000 }
    module ForwardedPort
      def osx(forwarded_port)
        @vagrant_config.vm.network "forwarded_port", guest: forwarded_port[:guest], host: forwarded_port[:host]
      end
    end
  
  end
end


module Provision
  module Install

    # Install :OsxCommandLineTools
    module OsxCommandLineTools
      def osx
        say "Installing OS X Command Line Tools"
        install_dmg 'https://s3.amazonaws.com/OHSNAP/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg'
      end
    end

    # Install :Gpg
    module Gpg
      def osx
        say "Installing gpg, gpg-agent, and copying gpg keys from vm host"
        install_dmg 'https://releases.gpgtools.org/GPG%20Suite%20-%202013.10.22.dmg'
        run_script <<-'EOF'
          sudo rm -rf /Users/vagrant/.gnupg
          sudo rsync -r --exclude '.gnupg/S.gpg-agent' /.vagrant_host_home/.gnupg /Users/vagrant
          sudo chown -R vagrant /Users/vagrant/.gnupg
        EOF
      end
    end
  
    # Install :Git
    module Git
      def osx
        say "Installing git and copying .gitconfig from vm host"
        install_dmg 'https://git-osx-installer.googlecode.com/files/git-1.8.4.2-intel-universal-snow-leopard.dmg'
        run_script "cp /.vagrant_host_home/.gitconfig /Users/vagrant/.gitconfig"
      end
    end

    # Install :Node
    module Node
      def osx
        say "Installing nodejs"
        install_pkg 'http://nodejs.org/dist/v0.10.26/node-v0.10.26.pkg'
      end
    end
  
    # Install :TextMate
    module TextMate
      def osx
        say "Installing TextMate"
        install_tar 'https://api.textmate.org/downloads/release'
      end
    end

    # Install :Homebrew
    module Homebrew
      def osx
        say "Installing Homebrew"
        run_script 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
      end
    end

    # Install :Bundler
    module Bundler
      def osx
        say "Installing Ruby's bundler"
        run_script "sudo gem install bundler"
      end
    end

    # Install :Ruby
    module Ruby
      def osx
        say "Installing Ruby"
        run_script "brew install ruby"
      end
    end

    # Install :Python3
    module Python3
      def osx
        say "Installing Python3"
        install_dmg 'https://www.python.org/ftp/python/3.4.1/python-3.4.1-macosx10.6.dmg'
      end
    end

    # Install :Virtualenv
    module Virtualenv
      def osx
        say "Installing Python's virtualenv"
        url = "https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.11.6.tar.gz"
        cache_dir = derive_cache_dir(url)
        download_to_cache(url, cache_dir, "virtualenv-1.11.6.tar.gz")
        run_script <<-"EOF"
          tar xvfz "#{cache_dir[:guest_path]}/virtualenv-1.11.6.tar.gz"
          pushd virtualenv-1.11.6
          sudo python setup.py install
          popd
          sudo rm -rf virtualenv-1.11.6
        EOF
      end
    end

  end
end


module Provision
  module Git
    
    # Git :Clone "https://github.com/milewgit/#{PROJECT_NAME}.git", "/Users/vagrant/Documents/MyProjectDevEnv"
    module Clone
      def osx(project_github_url, project_vm_path)
        say "Installing project source code"
        run_script <<-"EOF"
          git clone "#{project_github_url}" "#{project_vm_path}"
        EOF
      end
    end
  end
end


module Provision
  module Npm
    
    # Npm :Install "/Users/vagrant/Documents/MyProjectDevEnv"
    module Install
      def osx(project_vm_path)
        say "Running npm install"
        run_script <<-"EOF"
          ( cd "#{project_vm_path}" && exec npm install )
        EOF
      end
    end
  end
end


module Provision
  module Bundle
    
    # Bundle :Install, "/Users/vagrant/Documents/MyProjectDevEnv"
    module Install
      def osx(project_vm_path)
        say "Running bundle install"
        run_script <<-"EOF"
          ( cd "#{project_vm_path}" && exec sudo bundle install )
        EOF
      end
    end
  end
end


module Provision
  module Pip
    
    # Pip :Install, "/Users/vagrant/Documents/MyProjectDevEnv" 
    module Install
      def osx(project_vm_path)
        say "Running pip install -r requirements.txt"
        run_script <<-"EOF"
          ( cd "#{project_vm_path}" && exec bin/pip install -r requirements.txt )
        EOF
      end
    end
  end
end


module Provision
  module Virtualenv
    
    # Virtualenv :Create, "/Users/vagrant/Documents/MyProjectDevEnv"
    module Create
      def osx(project_vm_path)
        say "Running virtualenv"
        run_script <<-"EOF"
          pushd "#{project_vm_path}"
          virtualenv --no-site-packages --python=`which python3` env
          popd
        EOF
      end
    end
  end
end


module Provision
  module Reboot
    
    # Reboot :Vm
    module Vm
      def osx 
        say "Rebooting"
        run_script "sudo reboot"
      end
    end
  end
end


class Provisioner

    def initialize(vagrant_config)
      @tools = Tools.new(vagrant_config)
    end

    def provision(&block)
      Setup :SyncedFolder, SYNCED_DOWNLOAD_CACHE_FOLDER   # guest needs access to downloaded files cached on the host
      instance_eval(&block)
    end
  
    # TODO: refactor
    # TODO: check that osx() method exists
    # TODO: pass &block to osx() method
    def method_missing(method, action_name, *args, &block)
      raise "Unknown subject '#{method}' (no module #{method} found within module Provision)" unless Provision.constants.grep(method).length > 0
      raise "No action specified for subject '#{method} (try something like: #{method} :some_action)" if action_name.nil?
      subject = Provision.const_get(method)
      raise "Unknown action '#{action_name}' (no module #{action_name} found within module Provision::#{method})" unless subject.constants.grep(action_name).length > 0
      action = subject.const_get(action_name)
      action.instance_method(:osx).bind(@tools).call(*args)
    end

end


class Tools

    def initialize(vagrant_config)
      @vagrant_config = vagrant_config
    end

    def install_dmg(url)
      cache_dir = derive_cache_dir(url)
      download_to_cache(url, cache_dir, "install.dmg")
      run_script <<-"EOF"
        hdiutil detach "/Volumes/_vm_provisioning_" 2>&1 > /dev/null
        hdiutil attach "#{cache_dir[:guest_path]}/install.dmg" -mountpoint "/Volumes/_vm_provisioning_"
        sudo installer -pkg "`ls /Volumes/_vm_provisioning_/*.pkg`" -target /
        hdiutil detach "/Volumes/_vm_provisioning_"
      EOF
    end

    def install_tar(url)
      cache_dir = derive_cache_dir(url)
      download_to_cache(url, cache_dir, "install.tar")
      run_script <<-"EOF"
        sudo tar -x -C /Applications -f "#{cache_dir[:guest_path]}/install.tar"
      EOF
    end

    def install_pkg(url)
      cache_dir = derive_cache_dir(url)
      download_to_cache(url, cache_dir, "install.pkg")
      run_script <<-"EOF"
        sudo installer -pkg "#{cache_dir[:guest_path]}/install.pkg" -target /
      EOF
    end

    def create_if_missing(folder)
      folder = File.expand_path(folder)
      FileUtils.mkdir_p(folder) unless File.exist?(folder)
    end
  
    def say(message)
      run_script "echo '--------------- #{message} ---------------'"
    end

    def run_script(script)
      @vagrant_config.vm.provision :shell, privileged: false, inline: script
    end

  private

    # Test for file in the cache (via host_cache_dir) when this Vagrantfile runs,
    # but download the file (if not in the cache) to the cache (via guest_cache_dir)
    # when Vagrant runs the provisioning scripts on the vm.  Vagrant will run this
    # Vagrantfile for all tasks including those that do not provision, e.g. 
    # '$vargant destroy'.  By downloading the file via vm script rather than here,
    # we prevent doing a download for those vagrant tasks that do not need it, again
    # e.g. the destroy task.
    def download_to_cache(url, cache_dir, filename)
      if not File.exist?("#{cache_dir[:host_path]}/#{filename}")
        run_script <<-"EOF"
          curl -L --create-dirs -o "#{cache_dir[:guest_path]}/#{filename}" "#{url}"
        EOF
      end
    end

    # The two cache paths point to the same physical directory, but one is used
    # to access it from the host, the other from the guest vm.
    def derive_cache_dir(url)
      url_dir = url2dir(url)
      host_path = File.join(SYNCED_DOWNLOAD_CACHE_FOLDER[:host], url_dir)
      guest_path = File.join(SYNCED_DOWNLOAD_CACHE_FOLDER[:guest], url_dir)
      {host_path: host_path, guest_path: guest_path}
    end

    # 'http://company.com/file2014.dmg' => 'http3A2F2Fcompany2Ecom2Ffile20142Edmg'
    def url2dir(url)
      url.gsub( /[^a-zA-Z0-9]/ ) { |s| sprintf('%2X', s.ord) }
    end

    # 'my product (v1)' => 'my\ product\ \(v1\)'
    def escape_shell_special_chars(string)
      string.gsub(/([ ()])/, '\\\\\1')
    end

end
