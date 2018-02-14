
  <img src="https://www.softfire.eu/wp-content/uploads/SoftFIRE_Logo_Fireball-300x300.png" width="120"/>

  Copyright © 2016-2018 [SoftFIRE](https://www.softfire.eu/) and [TU Berlin](http://www.av.tu-berlin.de/next_generation_networks/).
  Licensed under [Apache v2 License](http://www.apache.org/licenses/LICENSE-2.0).

# bootstrap

The installation, update and clean script for the SoftFIRE middleware are provided in this project.

# How to install the SoftFIRE middleware

The SoftFIRE Middleware already provides a set of bash functions that will help you in case you want to install your _private_ SoftFIRE Middleware. There are two options:

* _**codeinstall**_: install the code of all the managers and the python package of the SDK. This procedure is meant to be for development purposes
* _**install**_: install the code of all the managers and the python package of the SDK. This procedure is meant to be for production purposes


##### Note: The SoftFIRE Middleware is OS independent, however the bootstrap procedure assumes that the underlying OS is Debian based.


## Prerequisites

Both procedures needs to have git installed

```bash
$-> sudo apt install git
```

and to run:

```bash
$-> git clone https://github.com/softfire-eu/bootstrap.git
```

for instance in your home directory. After the clone, you should have a folder called bootstrap containing:

```sh
bootstrap
├── LICENSE
├── README.md
├── bootstrap.sh
└── generate_cork_files.py
```

Then cd into the directory and run the bootstrap commands:


```text
$-> cd bootstrap
$-> ./bootstrap.sh

./bootstrap.sh <action>

actions:    [install|update|clean|start|stop|codestart|codeupdate|codeinstall|purge]

install:      install the SoftFIRE Middleware python packages
update:       update the SoftFIRE Middleware python packages
clean:        clean the SoftFIRE Middleware
start:        start the SoftFIRE Middleware via python packages
stop:         stop the SoftFIRE Middleware
codeinstall:  install the SoftFIRE Middleware source code
codeupdate:   update the SoftFIRE Middleware source code
codestart:    start the SoftFIRE Middleware via source code
purge:        completely remove the SoftFIRE Middleware
```

## Install the source code

For installing the source code just run:

```sh
$-> ./bootstrap.sh codeinstall
```

## Install the python packages

For installing the python packages just run:

```sh
$-> ./bootstrap.sh install

```

## What's happening?

After running these commands the script will:

1. install the debian packages required
1. creating the configuration folders
1. downloading the source code or installing python packages of all the managers (depending on what installation procedure you chose)
1. downloading configuration files

## Start the Middleware

If everything went well, you are able to start the SoftFIRE Middleware by running

```sh
$-> ./bootstrap.sh codestart
```

in case you installed via source code, or

```sh
$-> ./bootstrap.sh start
```

in case you installed via python packages.

In both cases, a tmux session will run in background and you can check the output by attaching to it:

```sh
tmux a
```


## Issue tracker

Issues and bug reports should be posted to the GitHub Issue Tracker of this project.

# What is SoftFIRE?

SoftFIRE provides a set of technologies for building a federated experimental platform aimed at the construction and experimentation of services and functionalities built on top of NFV and SDN technologies.
The platform is a loose federation of already existing testbed owned and operated by distinct organizations for purposes of research and development.

SoftFIRE has three main objectives: supporting interoperability, programming and security of the federated testbed.
Supporting the programmability of the platform is then a major goal and it is the focus of the SoftFIRE’s Second Open Call.

## Licensing and distribution
Copyright © [2016-2018] SoftFIRE project

Licensed under the Apache License, Version 2.0 (the "License");

you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

<!---
 Script for open external links in a new tab
-->
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.js"></script>
<script type="text/javascript" charset="utf-8">
      // Creating custom :external selector
      $.expr[':'].external = function(obj){
          return !obj.href.match(/^mailto\:/)
                  && (obj.hostname != location.hostname);
      };
      $(function(){
        $('a:external').addClass('external');
        $(".external").attr('target','_blank');
      })
</script>
