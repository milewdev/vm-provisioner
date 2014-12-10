#
# class variables and initialization
#
class Provisioner

    def self.provision(vagrant_config, &block)
      Provisioner.new(vagrant_config).send(:run, &block)
    end

  private

    def initialize(vagrant_config)
      @vagrant_config = vagrant_config
      @run_in_directory = @run_in_directory_default = '.'
    end

    def run(&block)
      instance_eval(&block)
    end

end


#
# helper methods
#
class Provisioner

  private

    def dmg_install(url_of_dmg_file)
      run_script <<-"EOF"
        curl -L -o install.dmg #{url_of_dmg_file}
        hdiutil detach "/Volumes/_vm_provisioning_" > /dev/null 2>&1
        hdiutil attach install.dmg -mountpoint "/Volumes/_vm_provisioning_"
        if ls -d /Volumes/_vm_provisioning_/*.*pkg &> /dev/null; then
          sudo installer -pkg "`ls -d /Volumes/_vm_provisioning_/*.*pkg`" -target /
        elif ls -d /Volumes/_vm_provisioning_/*.app &> /dev/null; then
          sudo cp -R "`ls -d /Volumes/_vm_provisioning_/*.app`" /Applications
        fi
        hdiutil detach "/Volumes/_vm_provisioning_"
        rm -f install.dmg
      EOF
    end

    def pkg_install(url_of_pkg_file)
      run_script <<-"EOF"
        curl -L -o install.pkg #{url_of_pkg_file}
        sudo installer -pkg install.pkg -target /
        rm -f install.pkg
      EOF
    end

    def tar_install(url_of_tar_file)
      run_script <<-"EOF"
        curl -L -o install.tar #{url_of_tar_file}
        sudo tar -x -C /Applications -f install.tar
        rm -f install.tar
      EOF
    end

    def zip_install(url_of_zip_file)
      run_script <<-"EOF"
        curl -L -o install.zip #{url_of_zip_file}
        unzip -qq -d /Applications install.zip
        rm -f install.zip
      EOF
    end

    def copy_host_file_to_vm(host_path, vm_path)
      @vagrant_config.vm.provision :file, source: host_path, destination: vm_path
    end

    def say(message)
      message = message.gsub(/(['"><|()])/, '\\\\\1')   # '"><|  =>  \'\"\>\<\|
      run_script "echo --------------- #{message} ---------------"
    end

    def run_script(script_code)
      @vagrant_config.vm.provision :shell, privileged: false, inline: <<-"EOF"
        pushd #{@run_in_directory} > /dev/null
        #{script_code}
        popd > /dev/null
      EOF
    end

end


#
# provisioning dsl
#
class Provisioner

  def install_atom
    say "Installing atom editor"
    zip_install 'https://atom.io/download/mac'
  end

  def install_bundler
    say "Installing bundler"
    run_script 'gem install bundler'
  end

  def bundle_install
    say "Running 'bundle install'"
    run_script "bundle install"
  end

  def install_chrome
    say "Installing google chrome browser"
    dmg_install "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
  end

  def install_firefox
    say "Installing Mozilla firefox browser"
    dmg_install "https://download-installer.cdn.mozilla.net/pub/firefox/releases/33.0/mac/en-US/Firefox%2033.0.dmg"
  end

  def install_git(version = '2.0.1')
    say "Installing git and copying .gitconfig from vm host"
    dmg_install "http://sourceforge.net/projects/git-osx-installer/files/git-#{version}-intel-universal-snow-leopard.dmg/download?use_mirror=autoselect"
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

  def install_node(version = 'v0.10.32')
    say "Installing nodejs"
    pkg_install "http://nodejs.org/dist/#{version}/node-#{version}.pkg"
  end

  def npm_install
    say "Running 'npm install'"
    run_script "npm install"
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
    version = "1.11.6"
    directory = "virtualenv-#{version}"
    filename = "virtualenv-#{version}.tar.gz"
    url = "https://pypi.python.org/packages/source/v/virtualenv/#{filename}"
    run_script <<-"EOF"
      curl -L -o #{filename} #{url}
      tar xvfz #{filename}
      pushd #{directory}
      sudo python setup.py install
      popd
      sudo rm -rf #{directory}
      rm -f #{filename}
    EOF
  end

  def add_to_path(path)
    say "Adding '#{path}' to path"
    run_script <<-"EOF"
      echo 'export PATH=#{path}:$PATH' >> ~/.bash_profile
    EOF
  end

  #
  # Run commands in a specific directory.  For example:
  #
  # Vagrant.configure('2') do |vagrant_config|
  #   install_homebrew
  #   install_ruby
  #   install_bundler
  #   with vagrant_config do
  #     git_clone 'https://github.com/me/my_project.git', '~/Documents/my_project'
  #     cd '~/Documents/my_project' do
  #       bundle_install
  #     end
  #   end
  # end
  #
  def cd(vm_dir, &block)
    @run_in_directory = vm_dir
    block.call()
  ensure
    @run_in_directory = @run_in_directory_default
  end

  def reboot_vm
    say "Rebooting"
    run_script "sudo reboot"
  end

end
