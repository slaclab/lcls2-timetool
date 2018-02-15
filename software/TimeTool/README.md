# slaclab/lcls2-pcie-apps/software/TimeTool

# Before you clone the GIT repository

1) Create a github account:

> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)

> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account

> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github (one time step per Unix profile)

``` 
$ git lfs install 
```

5) Verify that you have git version 2.13.0 (or later) in the $PATH 

```
$ git version
git version 2.13.0
```

6) Verify that you have git-lfs version 2.1.1 (or later) in the $PATH  

```
$ git-lfs version
git-lfs/2.1.1
```

Note: If you need a newer version of git or git-lfs, here's a AFS $PATH for one:

> /afs/slac/g/reseng/git/git/bin

# Clone the GIT repository

``` $ git clone --recursive git@github.com:slaclab/lcls2-pcie-apps```

# How to build the firmware

> Setup your Xilinx Vivado:

>> If you are on the SLAC AFS network:

```$ source lcls2-pcie-apps/firmware/setup_slac.csh```

>> Else you will need to install Vivado and install the Xilinx Licensing

> Go to the firmware's target directory:

```$ cd lcls2-pcie-apps/firmware/targets/TimeToolKcu1500```

> Build the firmware

```$ make```

> Optional: Open up the project in GUI mode to view the firmware build results

```$ make gui```

Note: For more information about the firmware build system, please refer to this presentation:

> https://docs.google.com/presentation/d/1kvzXiByE8WISo40Xd573DdR7dQU4BpDQGwEgNyeJjTI/edit?usp=sharing

# How to program the KCU1500 via JTAG
> https://docs.google.com/presentation/d/1VVfkIWN9M_czZiaXhK4iFp-Drj_yc64smbzpSwZ61Cg/edit?usp=sharing

# How to load the driver

```
# Clone the driver github repo:
$ git clone --recursive git@github.com:slaclab/aes-stream-drivers

# Go to the driver directory
$ cd aes-stream-drivers/data_dev/driver/

# Build the driver
$ make

# Execute load script as sudo
$ sudo /sbin/insmod ./datadev.ko 

# Check for the loaded device
$ cat /proc/data_dev0

```