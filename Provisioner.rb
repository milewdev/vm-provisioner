#
# Please view the README file prior to reading this source code.
#


#
# Files that are downloaded by provisioning steps, such as dmg and pkg files,
# are stored by Provisioner.rb in a cache on the host machine.  In general, this 
# speeds up all but the first 'vagrant up'.  
#
# However, vagrant will run all statements in the Vagrantfile for all vagrant commands, 
# including, say, 'up' and 'destroy', but we only want to do downloads when running the 
# 'up' command.  This means we must do downloads via the Vagrant 'provision :shell'
# command rather than directly via Ruby code in the Vagrantfile.  To that end, we
# create a cache directory on the host, so that it does not vanish when we do a
# 'vagrant destroy', but make it available to the vm so that files can be downloaded
# to it and read from it.
#
# Caveat: not all downloaded files are cached.  For example, dependencies installed via
# using 'bundle install', 'npm install', or 'pip install' are not cached.
#
CACHE_ROOT_DIR = { host: "provisioning_cache", guest: "/.provisioning_cache" }


#
# DSL provisioning statements in the Vagrantfile look like:
#
#     Install :Git
#     Git :Clone, project_github_url, project_vm_dir
#
# and are implemented in this file as:
#
#     module Provision
#       module Install
#         module Git
#           def osx
#             # script code to install git on OS X goes here
#           end
#         end
#       end
#     end
#
#     module Provision
#       module Git
#         module Clone
#           def osx(project_github_url, project_vm_dir)
#             # script code to run 'git clone' on OS X goes here
#           end
#         end
#       end
#     end
#
# The Provision module is only used as a namespace to prevent name collisions with
# whatever modules happen to be in the Ruby root namespace (e.g. :Object, :Module, 
# :Class, :BasicObject, etc.); however, it has the unfortunate effect of adding 
# another level of nesting, which increases complexity.
#
module Provision
  module Setup
    
    # Setup :Box, "OSX109"
    module Box
      def osx(box)
        vagrant_config().vm.box = box
      end
    end
  
    # Setup :Provider, "vmware_fusion", "MyProjectDevEnv"
    module Provider
      def osx(provider, vm_name)
        vagrant_config().vm.provider(provider) do |vb|
          vb.name = vm_name
          vb.gui = true
        end
      end
    end
  
    # Setup :SyncedFolder, { host: "~/", guest: "/.vagrant_host_home" }
    module SyncedFolder
      def osx(synced_folder)
        require "fileutils"
        FileUtils.mkdir_p(File.expand_path(synced_folder[:host]))
        vagrant_config().vm.synced_folder synced_folder[:host], synced_folder[:guest]
      end
    end
  
    # Setup :ForwardedPort, { guest: 4000, host: 4000 }
    module ForwardedPort
      def osx(forwarded_port)
        vagrant_config().vm.network "forwarded_port", guest: forwarded_port[:guest], host: forwarded_port[:host]
      end
    end
  
  end
end


module Provision
  module Install
    
    # TODO: add version numbers?  e.g. Install :Git, 1.2.3
    
    # Install :OsxCommandLineToolsMountainLion
    module OsxCommandLineToolsMountainLion
      def osx
        say "Installing OS X Command Line Tools for Mountain Lion"
        install_dmg 'http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_mountain_lion_april_2013.dmg'
      end
    end

    # Install :OsxCommandLineToolsMavericks
    module OsxCommandLineToolsMavericks
      def osx
        say "Installing OS X Command Line Tools for Mavericks"
        install_dmg 'https://s3.amazonaws.com/OHSNAP/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg'
      end
    end

    # Install :OsxCommandLineTools
    module OsxCommandLineTools
      def osx
        say "Installing OS X Command Line Tools (WARNING: deprecated; use 'Install :OsxCommandLineToolsMavericks' instead)"
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
    
    # Install :GitHubForMac
    module GitHubForMac
      def osx
        say "Installing GitHub for Mac"
        install_zip 'https://central.github.com/mac/latest'
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
        run_script <<-EOF
          ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
          echo export PATH='/usr/local/bin:$PATH' >> ~/.bash_profile
          brew update
          brew tap homebrew/versions
          brew tap homebrew/dupes
        EOF
      end
    end
    
    # Install :ITerm2
    module ITerm2
      def osx
        say "Installing iTerm2"
        install_zip "https://iterm2.com/downloads/stable/iTerm2_v2_0.zip"
      end
    end
    
    # Install :HerokuToolbelt
    module HerokuToolbelt
      def osx
        say "Installing Heroku Toolbelt"
        install_pkg "https://toolbelt.heroku.com/download/osx"
      end
    end
    
    # Install :Qt
    module Qt
      def osx(*args)
        say "Installing Qt"
        run_script "brew install qt"
      end
    end
    
    # Install :PhantomJS
    module PhantomJS
      def osx(*args)
        say "Installing PhantomJS"
        run_script "brew install phantomjs"
      end
    end
    
    # Install :Rails [ "4.1.4" ]
    module Rails
      def osx(*args)
        version = args[0] || "4.1.4"
        say "Installing Rails #{version}"
        run_script "gem install --no-rdoc --no-ri rails -v #{version}"
      end
    end

    # Install :Bundler [ "1.6.4" ]
    module Bundler
      def osx(*args)
        version = args[0] || "1.6.4"
        say "Installing Bundler"
        run_script "gem install --no-rdoc --no-ri bundler -v #{version}"
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
    
    # Install :PostgreSQL [ "92" ]
    module PostgreSQL
      def osx(*args)
        version = args[0] || ""         # blank version defaults to latest version
        say "Installing PostgreSQL"
        run_script <<-"EOF"
           brew install postgresql#{version}
           rm -rf /usr/local/var/postgres/
           initdb /usr/local/var/postgres -E UTF8
           mkdir -p ~/Library/LaunchAgents
           ln -sfv /usr/local/opt/postgresql92/*.plist ~/Library/LaunchAgents
        EOF
      end
    end

    # Install :Ruby [ "2.1.2" ]
    module Ruby
      def osx(*args)
        version = args[0] || "2.1.2"
        say "Installing Ruby #{version}"
        run_script <<-"EOF"
          brew install apple-gcc42
          brew install rbenv
          brew install ruby-build
          rbenv install #{version}
          rbenv global #{version}
          rbenv rehash
          echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.bash_profile
        EOF
      end
    end

  end
end


module Provision
  module Git
    
    # Git :Clone, "https://github.com/milewgit/#{PROJECT_NAME}.git", "/Users/vagrant/Documents/MyProjectDevEnv"
    module Clone
      def osx(project_github_url, project_vm_dir)
        say "Installing project source code"
        run_script <<-"EOF"
          git clone "#{project_github_url}" "#{project_vm_dir}"
        EOF
      end
    end
  end
end


module Provision
  module Npm
    
    # Npm :Install, "/Users/vagrant/Documents/MyProjectDevEnv"
    module Install
      def osx(project_vm_dir)
        say "Running npm install"
        run_script <<-"EOF"
          ( cd "#{project_vm_dir}" && exec npm install )
        EOF
      end
    end
  end
end


module Provision
  module Bundle
    
    # Bundle :Install, "/Users/vagrant/Documents/MyProjectDevEnv"
    module Install
      def osx(project_vm_dir)
        say "Running bundle install"
        run_script <<-"EOF"
          ( cd "#{project_vm_dir}" && exec bundle install )
        EOF
      end
    end
  end
end


module Provision
  module Pip
    
    # Pip :Install, "/Users/vagrant/Documents/MyProjectDevEnv" 
    # TODO: add requirements file name parameter (default requirements.txt)?
    module Install
      def osx(project_vm_dir)
        say "Running pip install -r requirements.txt"
        run_script <<-"EOF"
          ( cd "#{project_vm_dir}" && exec bin/pip install -r requirements.txt )
        EOF
      end
    end
  end
end


module Provision
  module Virtualenv
    
    # Virtualenv :Create, "/Users/vagrant/Documents/MyProjectDevEnv"
    # TODO: add env name parameter?
    # TODO: add python version parameter?
    module Create
      def osx(project_vm_dir)
        say "Running virtualenv"
        run_script <<-"EOF"
          pushd "#{project_vm_dir}"
          virtualenv --no-site-packages --python=`which python3` env
          popd
        EOF
      end
    end
  end
end


module Provision
  module Run
    
    # Run :Shell, "/Users/vagrant/Documents/MyProjectDevEnv", "bin/rake db:setup"
    module Shell
      def osx(dir, command)
        say "Running shell command: #{command}"
        run_script <<-"EOF"
          pushd "#{dir}"
          #{command}
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


#
# Provisioner is responsible for mapping the provisioning DSL statements
# into calls to appropriate methods in the Provision namespace.  For example, 
# "Install :Git" is mapped to a call to Provision::Install::Git#osx.
#
class Provisioner
  
    def self.provision(vagrant_config, &block)
      Provisioner.new(vagrant_config).send(:run, &block)    # use #send because #run is private
    end
  
  private
  
    def initialize(vagrant_config)
      @cache_root_dir = CACHE_ROOT_DIR
      @tools = OSXTools.new(vagrant_config, @cache_root_dir)
    end

    def run(&block)
      Setup :SyncedFolder, @cache_root_dir                  # allow guest vm to access files cached on the host
      instance_eval(&block)
    end
  
    # Given 'Git :Clone, "https://github...", "/Users/..."', then subject_name is 'Git', 
    # action_name is 'Clone', and *args is [ "https://github...", "/Users/..." ]. This is 
    # then mapped to Provision::subject::action#osx_method, i.e. Provision::Git::Clone#osx.
    # #osx is invoked in the context of @tools so that #osx can make use of any of @tools'
    # helper methods.
    def method_missing(subject_name, action_name, *args, &block)
      subject = get_subject(subject_name)
      action = get_action(subject, action_name)
      osx_method = get_osx_method(subject, action)
      osx_method.bind(@tools).call(*args, &block)
    end
    
    def get_subject(subject_name)
      raise_unknown_subject(subject_name) if Provision.constants.grep(subject_name).length == 0
      Provision.const_get(subject_name)
    end
    
    def get_action(subject, action_name)
      raise_no_action_specified(subject) if action_name.nil?
      raise_unknown_action(subject, action_name) if subject.constants.grep(action_name).length == 0
      subject.const_get(action_name)
    end
    
    def get_osx_method(subject, action)
      raise_no_osx_method_found(subject, action) unless action.method_defined?(:osx)
      action.instance_method(:osx)
    end
    
    def raise_unknown_subject(subject_name)
      raise "Unknown subject '#{subject_name}' (no module #{subject_name} found within module Provision)" 
    end
    
    def raise_no_action_specified(subject_name)
      raise "No action specified for subject '#{subject_name} (try something like: #{subject_name} :some_action)" 
    end
    
    def raise_unknown_action(subject, action_name)
      raise "Unknown action '#{action_name}' (no module #{action_name} found within module Provision::#{subject})" 
    end
    
    def raise_no_osx_method_found(subject, action)
      raise "No osx() method found in Provision::#{subject}::#{action}"
    end

end


#
# These are tools specific to OS X for helping with provisioning.  For example,
# there are methods for installing various kinds of packages (dmg, pkg, tar),
# running script code, and displaying messages.
#
# Note: this class also manages the cache, which seems like it should be extracted
# to its own class.  However, the cache downloads files using a command that is
# specific to the OS (e.g. curl for OS X, and presumably *nix as well), so there
# is a circular dependency.  Right now the code is short enough to survive the
# multiple responsibilities but this should be refactored if the code grows.
#
class OSXTools

    def initialize(vagrant_config, cache_root_dir)
      @vagrant_config = vagrant_config
      @cache_root_dir = cache_root_dir
    end
    
    def vagrant_config
      @vagrant_config
    end

    def install_dmg(url_of_dmg_file)
      cache_dir = derive_cache_dir(url_of_dmg_file)
      download_to_cache(url_of_dmg_file, cache_dir, "install.dmg")
      run_script <<-"EOF"
        hdiutil detach "/Volumes/_vm_provisioning_" > /dev/null 2>&1
        hdiutil attach "#{cache_dir[:guest_path]}/install.dmg" -mountpoint "/Volumes/_vm_provisioning_"
        sudo installer -pkg "`ls /Volumes/_vm_provisioning_/*.*pkg`" -target /
        hdiutil detach "/Volumes/_vm_provisioning_"
      EOF
    end

    def install_pkg(url_of_pkg_file)
      cache_dir = derive_cache_dir(url_of_pkg_file)
      download_to_cache(url_of_pkg_file, cache_dir, "install.pkg")
      run_script <<-"EOF"
        sudo installer -pkg "#{cache_dir[:guest_path]}/install.pkg" -target /
      EOF
    end

    def install_tar(url_of_tar_file)
      cache_dir = derive_cache_dir(url_of_tar_file)
      download_to_cache(url_of_tar_file, cache_dir, "install.tar")
      run_script <<-"EOF"
        sudo tar -x -C /Applications -f "#{cache_dir[:guest_path]}/install.tar"
      EOF
    end
    
    def install_zip(url_of_zip_file)
      cache_dir = derive_cache_dir(url_of_zip_file)
      download_to_cache(url_of_zip_file, cache_dir, "install.zip")
      run_script <<-"EOF"
        unzip -qq -d /Applications "#{cache_dir[:guest_path]}/install.zip"
      EOF
    end
  
    # TODO: need to escape single and double quotes in 'message' arg
    def say(message)
      run_script "echo '--------------- #{message} ---------------'"
    end

    def run_script(script_code)
      vagrant_config().vm.provision :shell, privileged: false, inline: script_code
    end

  private

    # Download a file and store it in the cache on the host machine if it is not
    # already there.  For reasons discussed in the comments near the top of this
    # file, we test for the presence of the file right now, but we use Vagrant's 
    # 'provision :shell' to download the file when Vagrant actually provisions
    # the vm.
    def download_to_cache(url, cache_dir, filename)
      if not File.exist?(File.join(cache_dir[:host_path], filename))
        run_script <<-"EOF"
          curl -L --create-dirs -o "#{ File.join(cache_dir[:guest_path], filename) }" "#{url}"
        EOF
      end
    end

    # The two cache paths point to the same physical directory, but one is used
    # to access it from the host, the other from the guest vm.
    def derive_cache_dir(url)
      url_dir = url2dir(url)
      host_path = File.join(@cache_root_dir[:host], url_dir)
      guest_path = File.join(@cache_root_dir[:guest], url_dir)
      {host_path: host_path, guest_path: guest_path}
    end

    # 'http://company.com/file2014.dmg' => 'http3A2F2Fcompany2Ecom2Ffile20142Edmg'
    def url2dir(url)
      url.gsub( /[^a-zA-Z0-9]/ ) { |s| sprintf('%2X', s.ord) }
    end

end
