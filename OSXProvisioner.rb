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


#
# everything you can use with OSXProvisioner
#
module Dsl

  def install_bower(version = nil)
    npm_install 'bower', version
  end

  def install_bundler(version)
    gem_install 'bundler', version
  end

  def bundle_install
    say "running 'bundle install'"
    run_script "bundle install"
  end

  def install_foundation(version = nil)
    gem_install 'foundation', version
  end

  def install_git
    say "Installing git and copying .gitconfig from vm host"
    dmg_install 'https://git-osx-installer.googlecode.com/files/git-1.8.4.2-intel-universal-snow-leopard.dmg'
    copy_host_file_to_vm "~/.gitconfig", ".gitconfig"
  end

  #
  # git_clone "https://github.com/me/my_project.git", "/Users/vagrant/Documents/my_project"
  #
  def git_clone(source_url, vm_dir)
    say "git clone #{source_url} #{vm_dir}"
    run_script "git clone \"#{source_url}\" \"#{vm_dir}\""
  end

  def install_github_for_mac
    say "Installing GitHub for Mac"
    zip_install 'https://central.github.com/mac/latest'
  end

  def install_gpg
    say "Installing gpg, gpg-agent, and copying gpg keys from vm host"
    dmg_install 'https://releases.gpgtools.org/GPG%20Suite%20-%202013.10.22.dmg'
    run_script 'sudo chown -R vagrant ~/.gnupg'
    copy_host_file_to_vm "~/.gnupg/pubring.gpg", ".gnupg/pubring.gpg"
    copy_host_file_to_vm "~/.gnupg/secring.gpg", ".gnupg/secring.gpg"
    copy_host_file_to_vm "~/.gnupg/trustdb.gpg", ".gnupg/trustdb.gpg"
    copy_host_file_to_vm "~/.gnupg/pubring.gpg~", ".gnupg/pubring.gpg~"
    copy_host_file_to_vm "~/.gnupg/random_seed", ".gnupg/random_seed"
  end

  def install_grunt_cli(version = nil)
    npm_install 'grunt-cli', version
  end

  def install_heroku_toolbelt
    say "Installing Heroku Toolbelt"
    pkg_install "https://toolbelt.heroku.com/download/osx"
  end

  def install_homebrew
    say "Installing Homebrew"
    run_script <<-EOF
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      echo export PATH='/usr/local/bin:$PATH' >> ~/.bash_profile
      brew update
      brew tap homebrew/versions
      brew tap homebrew/dupes
    EOF
  end

  def install_iterm2
    say "Installing iTerm2"
    zip_install "https://iterm2.com/downloads/stable/iTerm2_v2_0.zip"
  end

  def install_osx_command_line_tools_mountain_lion
    say "Installing OS X Command Line Tools for Mountain Lion"
    dmg_install 'http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_mountain_lion_april_2013.dmg'
  end

  def install_osx_command_line_tools_mavericks
    say "Installing OS X Command Line Tools for Mavericks"
    dmg_install 'https://s3.amazonaws.com/OHSNAP/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg'
  end

  def install_node
    say "Installing nodejs"
    pkg_install 'http://nodejs.org/dist/v0.10.26/node-v0.10.26.pkg'
  end

  def install_phantomjs
    say "Installing PhantomJS"
    run_script "brew install phantomjs"
  end

  def install_postgresql(version = nil)
    version ||= ''                        # blank version defaults to latest version
    say "Installing PostgreSQL"
    run_script <<-"EOF"
       brew install postgresql#{version}
       rm -rf /usr/local/var/postgres/
       initdb /usr/local/var/postgres -E UTF8
       mkdir -p ~/Library/LaunchAgents
       ln -sfv /usr/local/opt/postgresql92/*.plist ~/Library/LaunchAgents
    EOF
  end

  def install_python3
    say "Installing Python3"
    dmg_install 'https://www.python.org/ftp/python/3.4.1/python-3.4.1-macosx10.6.dmg'
  end

  def pip_install
    say "Running pip install -r requirements.txt"
    run_script "bin/pip install -r requirements.txt"
  end

  def virtualenv_create
    say "Running virtualenv"
    run_script "virtualenv --no-site-packages --python=`which python3` env"
  end

  def install_qt
    say "Installing Qt"
    run_script "brew install qt"
  end

  def install_rails(version = nil)
    gem_install 'rails', version
  end

  def install_ruby(version = nil)
    version ||= '2.1.2'                   # TODO: use latest instead
    say "Installing Ruby (#{version})"
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

  def install_textmate
    say "Installing TextMate"
    tar_install 'https://api.textmate.org/downloads/release'
  end

  def install_virtualenv
    say "Installing Python's virtualenv"
    url = "https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.11.6.tar.gz"
    vm_pathname = download_to_cache(url, "virtualenv-1.11.6.tar.gz")
    run_script <<-"EOF"
      tar xvfz "#{vm_pathname}"
      pushd virtualenv-1.11.6
      sudo python setup.py install
      popd
      sudo rm -rf virtualenv-1.11.6
    EOF
  end

  #
  # run commands in a directory
  #
  #   cd '~/Documents/my_project' do
  #     bundle_install
  #     ...
  #   end
  #
  def cd(vm_dir, &block)
    run_in_directory = vm_dir
    block.call()
  ensure
    run_in_directory = run_in_directory_default()
  end

  def reboot_vm
    say "Rebooting"
    run_script "sudo reboot"
  end

end


#
# These are tools specific to OS X for helping with provisioning.  For example,
# there are methods for installing various kinds of packages (dmg, pkg, tar),
# running script code, and displaying messages.
#
# Note: this class also manages the cache, which seems like it should be
# extracted to its own class.  However, the cache downloads files using a
# command that is specific to the OS (e.g. curl for OS X, and presumably *nix
# as well), so there is a circular dependency.  Right now the code is short
# enough to survive the multiple responsibilities but this should be refactored
# if the code grows.
#
module Helpers

  private

    def npm_install(product = nil, version = nil)
      if product.nil?
        say "running 'npm install'"
        run_script "npm install"
      else
        version ||= 'latest'
        say "installing #{product} (#{version})"
        run_script "npm install #{product}@#{version}"
      end
    end

    def gem_install(product, version)
      if version.nil?
        say "installing #{product} (latest)"
        run_script "gem install --no-rdoc --no-ri #{product}"
      else
        say "installing #{product} (#{version})"
        run_script "gem install --no-rdoc --no-ri #{product} -v #{version}"
      end
    end

    def dmg_install(url_of_dmg_file)
      vm_pathname = download_to_cache(url_of_dmg_file, "install.dmg")
      run_script <<-"EOF"
        hdiutil detach "/Volumes/_vm_provisioning_" > /dev/null 2>&1
        hdiutil attach "#{vm_pathname}" -mountpoint "/Volumes/_vm_provisioning_"
        sudo installer -pkg "`ls /Volumes/_vm_provisioning_/*.*pkg`" -target /
        hdiutil detach "/Volumes/_vm_provisioning_"
      EOF
    end

    def pkg_install(url_of_pkg_file)
      vm_pathname = download_to_cache(url_of_pkg_file, "install.pkg")
      run_script <<-"EOF"
        sudo installer -pkg "#{vm_pathname}" -target /
      EOF
    end

    def tar_install(url_of_tar_file)
      vm_pathname = download_to_cache(url_of_tar_file, "install.tar")
      run_script <<-"EOF"
        sudo tar -x -C /Applications -f "#{vm_pathname}"
      EOF
    end

    def zip_install(url_of_zip_file)
      vm_pathname = download_to_cache(url_of_zip_file, "install.zip")
      run_script <<-"EOF"
        unzip -qq -d /Applications "#{vm_pathname}"
      EOF
    end

    def copy_host_file_to_vm(host_path, vm_path)
      vagrant_config().vm.provision :file, source: host_path, destination: vm_path
    end

    # TODO: need to escape single and double quotes in 'message' arg
    def say(message)
      run_script "echo '--------------- #{message} ---------------'"
    end

    def run_script(script_code)
      vagrant_config().vm.provision :shell, privileged: false, inline: <<-"EOF"
        pushd #{run_in_directory()} > /dev/null
        #{script_code}
        popd > /dev/null
      EOF
    end

    #
    # Download a file and store it in the cache on the host machine if it is not
    # already there.  For reasons discussed in the comments near the top of this
    # file, we test for the presence of the file right now, but we use Vagrant's
    # 'provision :shell' to download the file when Vagrant actually provisions
    # the vm.
    #
    def download_to_cache(url, filename)
      pathname = cache.derive_cache_dir(url, filename)
      run_script <<-"EOF"
        [ ! -f #{pathname} ] && curl -L --create-dirs -o "#{pathname}" "#{url}"
      EOF
      pathname
    end

end


#
#
#
class OSXProvisioner

  include Dsl
  include Helpers

  #
  # TODO: describe this convenience method
  #
  def self.provision(vagrant_config, &block)
    OSXProvisioner.new(vagrant_config).run(&block)
  end

  def initialize(vagrant_config)
    @vagrant_config = vagrant_config
  end

  def run(&block)
    instance_eval(&block)
  end

  def cache
    @cache ||= Cache.new(vagrant_config())
  end

  def vagrant_config
    @vagrant_config
  end

  def run_in_directory
    @run_in_directory ||= run_in_directory_default()
  end

  def run_in_directory=(directory)
    @run_in_directory = directory
  end

  def run_in_directory_default
    '.'
  end

end


#
#
#
class Cache

    def initialize(vagrant_config)
      create_cache_dir()
      sync_cache_dir(vagrant_config)
    end

    def derive_cache_dir(url, filename)     # TODO: rename to derive_cache_dir_on_vm or something similar?
      File.join(cache_vm_dir(), url2dir(url), filename)
    end

  private

    def cache_host_dir
      'cache'
    end

    def cache_vm_dir
      '/.cache'
    end

    def create_cache_dir
      require "fileutils"
      FileUtils.mkdir_p(cache_host_dir())
    end

    def sync_cache_dir(vagrant_config)    # TODO: rename to sync_cache_dir_with_host or something similar?
      vagrant_config.vm.synced_folder cache_host_dir(), cache_vm_dir()
    end

    #
    # 'http://company.com/file2014.dmg' => 'http3A2F2Fcompany2Ecom2Ffile20142Edmg'
    #
    def url2dir(url)
      url.gsub( /[^a-zA-Z0-9]/ ) { |s| sprintf('%2X', s.ord) }
    end

end
