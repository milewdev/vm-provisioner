Overview
========

Provisioner.rb is a helper for Vagrantfiles that provides simplistic Chef- or Puppet-like 
provisioning on a vm.  Currently, only provisioning on OS X is supported.

This is an example of a complete Vagrantfile that uses Provisioner.rb:

```
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
  PROVISIONER_URL           = "https://raw.githubusercontent.com/milewgit/vm-installers/master/Provisioner.rb"

  #
  # Provisioner provides a DSL to make Vagrantfile provisioning instructions 
  # easier to write and read.
  #
  Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant_config|
    with vagrant_config do
      Setup    :Box, BOX
      Setup    :Provider, PROVIDER_NAME, VM_NAME
      Setup    :SyncedFolder, HOST_HOME_DIR                 # easy way to copy gpg keys and git config from host to vm
      Install  :OsxCommandLineTools                         # needed by git
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

  
Existing Provisioning Commands
==============================

*Setup :Box, BOX_NAME*

*Setup :Provider, PROVIDER_NAME, VM_NAME*

*Setup :SyncedFolder, { host: HOST_DIR, guest: GUEST_DIR }*

*Install*

*Git :Clone, URL, PROJECT_VM_DIR*

*Npm :Install, PROJECT_VM_DIR*

*Bundle :Install, PROJECT_VM_DIR*

*Pip :Install, PROJECT_VM_DIR*

*Virtualenv, :Create, PROJECT_VM_DIR*

*Reboot :Vm*


Creating a new Provisioning Command
===================================
  
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

#say is a helper function available to #osx that prints a message on the 'vagrant up' terminal.


Helper Functions
================

*#vagrant_config*

*#say(message)*

*#install_dmg(url_of_dmg_file)*

*#install_pkg(url_of_pkg_file)*

*#install_tar(url_of_tar_file)*

*#run_script(script_code)*
