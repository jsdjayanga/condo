# The Condo
The ***"Condo"*** helps you manage your build environments


Have you come across situations where your build tools suddenly stop working after you update the operating system? Do you want a simple way of setting up your build environment each time you change or format your machine?

The Condo provides answers to the above questions. It uses docker images based build environments and gives you a simple set of commands to spin up, stop, and clean the build environments.

###Prerequisite
Docker command-line tool

###How to install
Just run the below simple command
```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jsdjayanga/condo/main/scripts/install.sh)"
```

#####The installation script will install the following.
1. Copy condo.sh, json.sh and unintall.sh scripts to /usr/local/Condo/
2. Copy the condo.json file to ~/.condo/
3. Create a symlink in /usr/local/bin/condo for easy execution

###Configuration
1. The configuration file resides in the ~/.condo/ directory
2. The "name" and "image" are the two mandatory configurations for an environment

```json
    {
        "name": "devj11",
        "image": "jsdjayanga/build-environments:bej11-v1"
    }
```

3. You can easily mount your working directory to the build-environment via additional-arguments

```json
    {
        "name": "devj11",
        "image": "jsdjayanga/devj11:0.1",
        "additional-arguments": "--mount type=bind,source=/home/<your-username>/Work,target=/home/ubuntu/Work"
    }
```

4. You can add any of your favorite docker images as a build environment by simple adding a new configuration section similar to below
```json
    {
        "name": "mygoenv",
        "image": "golang:1.15.6"
    }
```

5. If you are developing in Java and want your local maven repository to be accessible in the build-environment, simply add mount information in the "additional-arguments".

```json
    {
        "name": "devj11",
        "image": "jsdjayanga/devj11:0.1",
        "additional-arguments": "--mount type=bind,source=/home/<your-username>/Work,target=/home/ubuntu/Work --mount type=bind,source=/home/<your-username>/.m2,target=/home/ubuntu/.m2"
    }
```

###Commands

1. List build environments
```bash
    condo list
```

2. Run a build environment, condo \<build-envionment-name\>
```bash
    condo devj11
```

3. Stop a build environment condo stop \<build-envionment-name\>
```bash
    condo stop devj11
```

3. Clean a build environment condo clean \<build-envionment-name\>
```bash
    condo clean devj11
```



###Uninstall
Simply run the following command to uninstall the Condo
```bash
    /bin/bash /usr/local/Condo/uninstall.sh
```


###License
- Apache-2.0
