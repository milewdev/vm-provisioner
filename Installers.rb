require "fileutils"


class Installers

    def initialize(vagrant_config)
      @vagrant_config = vagrant_config
    end

    def run(&block)
      instance_eval(&block)
    end

    def select_box(box)
      @vagrant_config.vm.box = box
    end

    def setup_provider(provider, vm_name)
      @vagrant_config.vm.provider(provider) do |vb|
        vb.name = vm_name
        vb.gui = true
      end
    end

    def setup_forwarded_port(forwarded_port)
      @vagrant_config.vm.network "forwarded_port", guest: forwarded_port[:guest], host: forwarded_port[:host]
    end

    def setup_synced_folder(synced_folder)
      create_if_missing(synced_folder[:host])
      @vagrant_config.vm.synced_folder synced_folder[:host], synced_folder[:guest]
    end

    def install_osx_command_line_tools
      say "Installing OS X command line tools"
      install_dmg 'https://s3.amazonaws.com/OHSNAP/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg',
        'Command Line Developer Tools',
        'Command Line Tools (OS X 10.9).pkg'
    end

    def install_gpg
      say "Installing gpg, gpg-agent, and copying gpg keys from vm host"
      install_dmg 'https://releases.gpgtools.org/GPG%20Suite%20-%202013.10.22.dmg',
        'GPG Suite',
        'Install.pkg'
      run_script <<-'EOF'
        sudo rm -rf /Users/vagrant/.gnupg
        sudo rsync -r --exclude '.gnupg/S.gpg-agent' /.vagrant_host_home/.gnupg /Users/vagrant
        sudo chown -R vagrant /Users/vagrant/.gnupg
      EOF
    end

    def install_git
      say "Installing git and copying .gitconfig from vm host"
      install_dmg 'https://git-osx-installer.googlecode.com/files/git-1.8.4.2-intel-universal-snow-leopard.dmg',
        'Git 1.8.4.2 Snow Leopard Intel Universal',
        'git-1.8.4.2-intel-universal-snow-leopard.pkg'
      run_script "cp /.vagrant_host_home/.gitconfig /Users/vagrant/.gitconfig"
    end

    def install_node
      say "Installing nodejs"
      install_pkg 'http://nodejs.org/dist/v0.10.26/node-v0.10.26.pkg'
    end

    def install_homebrew
      say "Installing homebrew"
      run_script 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    end

    def install_bundler
      say "Installing bundler"
      run_script "sudo gem install bundler"
    end
    
    def install_ruby
       say "Installing Ruby"
       run_script "brew install ruby"
    end
    
    def install_python3
      say "Installing python3"
      install_dmg 'https://www.python.org/ftp/python/3.4.1/python-3.4.1-macosx10.6.dmg',
        'Python 3.4.1',
        'Python.mpkg'
    end
    
    def install_virtualenv
      say "Installing Python's virtualenv"
      url = "https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.11.6.tar.gz"
      cache_dir = derive_cache_dir(url)
      download url, cache_dir, "virtualenv-1.11.6.tar.gz"
      run_script <<-"EOF"
        tar xvfz #{cache_dir[:guest_path]}/virtualenv-1.11.6.tar.gz
        pushd virtualenv-1.11.6
        sudo python setup.py install
        popd
        sudo rm -rf virtualenv-1.11.6
      EOF
    end

    def install_editor
      say "Installing editor (TextMate)"
      install_tar 'https://api.textmate.org/downloads/release'
    end

    def install_project_source_code(project_source_url, project_vm_path)
      say "Installing project source code"
      run_script "git clone #{project_source_url} #{project_vm_path}"
    end

    def npm_install(project_vm_path)
      say "Run npm install"
      run_script "( cd #{project_vm_path} && exec npm install )"
    end
    
    def bundle_install(project_vm_path)
      say "Run bundle install"
      run_script "( cd #{project_vm_path} && exec sudo bundle install )"
    end
    
    def pip_install(project_vm_path)
      say "Run pip install -r requirements.txt"
      run_script "( cd #{project_vm_path} && exec bin/pip install -r requirements.txt )"
    end
    
    def virtualenv(project_vm_path)
      say "Run virtualenv"
      run_script <<-"EOF"
        pushd #{project_vm_path}
        virtualenv --no-site-packages --python=`which python3` env
        popd
      EOF
    end

    def reboot_vm
      say "Rebooting"
      run_script "sudo reboot"
    end

  private

    def create_if_missing(folder)
      folder = File.expand_path(folder)
      FileUtils.mkdir_p(folder) unless File.exist?(folder)
    end

    def install_dmg(url, path, pkg)
      cache_dir = derive_cache_dir(url)
      download(url, cache_dir, "install.dmg")
      run_dmg_installer(cache_dir, path, pkg)
    end

    def install_tar(url)
      cache_dir = derive_cache_dir(url)
      download(url, cache_dir, "install.tar")
      run_tar_installer(cache_dir)
    end

    def install_pkg(url)
      cache_dir = derive_cache_dir(url)
      download(url, cache_dir, "install.pkg")
      run_pkg_installer(cache_dir)
    end

    # The two cache paths point to the same physical directory, but one is used
    # to access it from the host, the other from the guest vm.
    def derive_cache_dir(url)
      url_dir = url2dir(url)
      host_path = File.join(SYNCED_DOWNLOAD_CACHE_FOLDER[:host], url_dir)
      guest_path = File.join(SYNCED_DOWNLOAD_CACHE_FOLDER[:guest], url_dir)
      {host_path: host_path, guest_path: guest_path}
    end

    # Test for file in the cache (via host_cache_dir) when this Vagrantfile runs,
    # but download the file (if not in the cache) to the cache (via guest_cache_dir)
    # when Vagrant runs the provisioning scripts on the vm.
    def download(url, cache_dir, filename)
      run_script "curl -L --create-dirs -o #{cache_dir[:guest_path]}/#{filename} #{url}" unless File.exist?("#{cache_dir[:host_path]}/#{filename}")
    end

    def run_dmg_installer(cache_dir, path, pkg)
      path = '/Volumes/' + escape_shell_special_chars(path)
      pkg = escape_shell_special_chars(pkg)
      run_script <<-"EOF"
        hdiutil attach #{cache_dir[:guest_path]}/install.dmg
        sudo installer -pkg #{path}/#{pkg} -target /
        hdiutil detach #{path}
      EOF
    end

    def run_tar_installer(cache_dir)
      run_script "sudo tar -x -C /Applications -f #{cache_dir[:guest_path]}/install.tar"
    end
    
    def run_pkg_installer(cache_dir)
      run_script "sudo installer -pkg #{cache_dir[:guest_path]}/install.pkg -target /"
    end

    # 'http://company.com/file2014.dmg' => 'http3A2F2Fcompany2Ecom2Ffile20142Edmg'
    def url2dir(url)
      url.gsub( /[^a-zA-Z0-9]/ ) { |s| sprintf('%2X', s.ord) }
    end

    def say(message)
      run_script "echo '--------------- #{message} ---------------'"
    end

    def run_script(script)
      @vagrant_config.vm.provision :shell, privileged: false, inline: script
    end

    # 'my product (v1)' => 'my\ product\ \(v1\)'
    def escape_shell_special_chars(string)
      string.gsub(/([ ()])/, '\\\\\1')
    end

end
