###Overview

Provisioner.rb is a helper for Vagrantfiles that provides simplistic Chef- or Puppet-like 
provisioning on a vm.  Currently, only provisioning on OS X is supported.

This is an example of a complete Vagrantfile that uses Provisioner.rb:

```Ruby
#
# A list of constants to improve legibility and keep things DRY.
#
VAGRANTFILE_API_VERSION   = "2"
BOX                       = "OSX109"
PROVIDER_NAME             = "vmware_fusion"
PROJECT_NAME              = "dev-env-CoffeeScript-node"
VM_NAME                   = PROJECT_NAME
HOST_HOME_DIR             = { host: "~/", guest: "/.vagrant_host_home" }
PROJECT_GITHUB_URL        = "https://github.com/milewgit/#{PROJECT_NAME}.git"
PROJECT_VM_DIR            = "/Users/vagrant/Documents/#{PROJECT_NAME}"
PROVISIONER_URL           = "https://raw.githubusercontent.com/milewgit/vm-provisioner/master/Provisioner.rb"

#
# Provisioner provides a DSL to make Vagrantfile provisioning instructions 
# easier to write and read.  The instructions are run in the order specified.
#
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Setup    :Box, BOX
    Setup    :Provider, PROVIDER_NAME, VM_NAME
    Setup    :SyncedFolder, HOST_HOME_DIR                 # easy way to copy gpg keys and git config from host to vm
    Install  :OsxCommandLineToolsMavericks                # needed by git
    Install  :Gpg                                         # needed to sign git commits
    Install  :Git                                         # source is on github
    Install  :Node                                        # used to run coffeescript compiler, tests under node.js
    Install  :TextMate
    Git      :Clone, PROJECT_GITHUB_URL, PROJECT_VM_DIR
    Npm      :Install, PROJECT_VM_DIR
    Reboot   :Vm
  end
end

#
# A simple bootstrap function: Provisioner.rb is downloaded from github and 
# then called to perform the provisioning instructions in &block.
#
def with(vagrant_config, &block)
  require "open-uri"
  File.write "Provisioner.rb", open(PROVISIONER_URL).read
  require_relative "Provisioner"
  Provisioner.provision(vagrant_config, &block)
end
```



<br>
###Provisioning Commands

**Setup :Box, BOX_NAME**

Same as:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  vagrant_config.vm.box = box'
end
```


<br>
**Setup :Provider, PROVIDER_NAME, VM_NAME**

Same as:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  vagrant_config().vm.provider(provider) do |vb|
    vb.name = vm_name
    vb.gui = true
  end
end
```


<br>
**Setup :SyncedFolder, { host: HOST_DIR, guest: GUEST_DIR }**

Same as:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  require "fileutils"
  FileUtils.mkdir_p(HOST_DIR)
  vagrant_config.vm.synced_folder HOST_DIR, GUEST_DIR
end
```


<br>
**Install :Something**

Install :Something on the vm.  The following are supported:

```
Install :OsxCommandLineToolsMountainLion
Install :OsxCommandLineToolsMavericks
Install :Gpg
Install :Git
Install :GitHubForMac
Install :Node
Install :TextMate
Install :Homebrew
Install :Ruby192
Install :Ruby                   # Note: you must Install :Homebrew first
Install :Rails3019
Install :Bundler
Install :Python3
Install :Virtualenv
```


<br>
**Git :Clone, URL, PROJECT_VM_DIR**

Runs 'git clone' on the vm.  For example:

```Ruby
Git :Clone, "https://github.com/me/MyProject.git", "/Users/vagrant/Documents/MyProject"
```

This is the same as doing:

```
$ git clone https://github.com/me/MyProject.git /Users/vagrant/Documents/MyProject
```

You might use this to install a project stored in github, for example, onto the vm.
Note that you must first install git.  For example:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Install :Git
    Git :Clone, "https://github.com/me/MyProject.git", "/Users/vagrant/Documents/MyProject"
  end
end
```


<br>
**Npm :Install, PROJECT_VM_DIR**

Runs 'npm install' in PROJECT_VM_DIR on the vm.  For example:

```
Npm :Install, "/Users/vagrant/Documents/MyProject"
```

This is the same as doing:

```
$ cd /Users/vagrant/Documents/MyProject
$ npm install
```

You would do this to have npm install any dependencies listed in in a node project's package.json file.
Note that you must first install node and the project's source code, which presumably includes package.json.
For example:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Install :Git
    Install :Node
    Git :Clone, "https://github.com/me/MyProject.git", "/Users/vagrant/Documents/MyProject"
    Npm :Install, "/Users/vagrant/Documents/MyProject"
  end
end
```


<br>
**Bundle :Install, PROJECT_VM_DIR**

Runs 'bundle install' in PROJECT_VM_DIR on the vm.  For example:

```
Bundle :Install, "/Users/vagrant/Documents/MyProject"
```

This is the same as doing:

```
$ cd /Users/vagrant/Documents/MyProject
$ bundle install
```

You would do this to have bundler install any dependencies listed in a Ruby project's Gemfile.  Note
that you must first install Ruby and the project's source code, which presumably includes the Gemfile.  
For example:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Install :Git
    Install :Homebrew       # needed by 'Install :Ruby'
    Install :Ruby
    Git :Clone, "https://github.com/me/MyProject.git", "/Users/vagrant/Documents/MyProject"
    Bundle :Install, "/Users/vagrant/Documents/MyProject"
  end
end
```


<br>
**Virtualenv :Create, PROJECT_VM_DIR**

Runs 'virtualenv --no-site-packages --python=`which python3` env' in PROJECT_VM_DIR on the vm.
For example:

```
Virtualenv :Create, "/Users/vagrant/Documents/MyProject"
```

This is the same as doing:

```
$ cd /Users/vagrant/Documents/MyProject
$ virtualenv --no-site-packages --python=`which python3` env
```

You would use this to create a new python environment in your project directory.  Note that
you must first install Python3, Virtualenv, and the project's source code, which presumably 
includes requirements.txt.  For example:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Install :Git
    Install :Python3
    Install :Virtualenv
    Virtualenv :Create, "/Users/vagrant/Documents/MyProject"
  end
end
```


<br>
**Pip :Install, PROJECT_VM_DIR**

Runs 'pip install --requirements.txt' in PROJECT_VM_DIR on the vm.  For example:

```
Pip :Install, "/Users/vagrant/Documents/MyProject"
```

This is the same as doing:

```
$ cd /Users/vagrant/Documents/MyProject
$ bin/pip install -r requirements.txt
```

You would do this to have pip install any dependencies listed in requirements.txt.  Note that
you must first install Python3, Virtualenv, and the project's source code, which presumably 
includes requirements.txt.  For example:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Install :Git
    Install :Python3
    Install :Virtualenv
    Virtualenv :Create, "/Users/vagrant/Documents/MyProject"
    Pip :Install, "/Users/vagrant/Documents/MyProject"
  end
end
```


<br>
**Reboot :Vm**

Reboots the vm which may be useful on some operating systems after installing software.  For
example:

```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Reboot :Vm
  end
end
```



<br>
###Creating a new Provisioning Command
  
To provide a new provisioning command, for example:

```
Echo :Message, "This message is displayed on the terminal where 'vagrant up' is run."
```

open up Provisioner.rb and add the following:

```
module Provision
  module Echo
    module Message
      def osx(message)
        say message
      end
    end
  end
end
```

'say' is a helper function available to #osx that prints a message on the terminal.



<br>
###Helper Functions

**#vagrant_config()**

Return the vagrant_config object that was passed to Provisioner.provision() and 
which is typically the vagrant_config object that Vagrant passes to its #configure
method:

```Ruby
BOX = "OSX109"
...

Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
  with vagrant_config do
    Setup :Box, BOX
    ...
  end
end

def with(vagrant_config, &block)
  ...
  Provisioner.provision(vagrant_config, &block)
end
```

You might use it like this:

```
module Provision
  module Setup
    module Box
      def osx(box)
        vagrant_config().vm.box = box
      end
    end
  end
end
```

<br>
**#say(message)**

Print a message on the terminal that 'vagrant up' was launched from.  The message is
wrapped with a line of dashes on either side so that it stands out.  For example,
this code:

```Ruby
module Provision
  module Install
    module TextMate
      def osx
        say "Installing TextMate"
        install_tar 'https://api.textmate.org/downloads/release'
      end
    end
  end
end
```

will result in something similar to this output on the terminal:

```
--------------- Installing TextMate ---------------
[default] Running provisioner: shell...
[default] Running: inline script
[default] Running provisioner: shell...
[default] Running: inline script
```


<br>
**#install_dmg(url_of_dmg_file)**

Download the dmg file at the specified URL and install it on the vm.  For example:

```
module Provision
  module Install
    module OsxCommandLineTools
      def osx
        install_dmg 'https://s3.amazonaws.com/OHSNAP/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg'
      end
    end
  end
end
```

Note: when you do 'vagrant up', install_dmg will first check to see if the dmg
file is in a local cache kept on the host machine (in the same directory as the
Vagrantfile) and only download it if it is not already there.


<br>
**#install_pkg(url_of_pkg_file)**

Download the pkg file at the specified URL and install it on the vm.  For example:

```
module Provision
  module Install
    module Node
      def osx
        install_pkg 'http://nodejs.org/dist/v0.10.26/node-v0.10.26.pkg'
      end
    end
  end
end
```

Note: when you do 'vagrant up', install_pkg will first check to see if the pkg
file is in a local cache kept on the host machine (in the same directory as the
Vagrantfile) and only download it if it is not already there.


<br>
**#install_tar(url_of_tar_file)**

Download the tar file at the specified URL and expand it into the /Applications 
directory on the vm.  For example:

```
module Provision
  module Install
    module TextMate
      def osx
        say "Installing TextMate"
        install_tar 'https://api.textmate.org/downloads/release'
      end
    end
  end
end
```

Note: when you do 'vagrant up', install_tar will first check to see if the tar
file is in a local cache kept on the host machine (in the same directory as the
Vagrantfile) and only download it if it is not already there.


<br>
**#install_zip(url_of_zip_file)**

Download the zip file at the specified URL and expand it into the /Applications 
directory on the vm.  For example:

```
module Provision
  module Install
    module GitHubForMac
      def osx
        say "Installing GitHub for Mac"
        install_zip 'https://central.github.com/mac/latest'
      end
    end
  end
end
```

Note: when you do 'vagrant up', install_tar will first check to see if the zip
file is in a local cache kept on the host machine (in the same directory as the
Vagrantfile) and only download it if it is not already there.


<br>
**#run_script(script_code)**

Run shell script code on the vm.  For example:

```
module Provision
  module Npm
    module Install
      def osx(project_vm_dir)
        run_script <<-"EOF"
          ( cd "#{project_vm_dir}" && exec npm install )
        EOF
      end
    end
  end
end
```
