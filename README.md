# bbb-kas

This project sets up a Yocto environment for BeagleBone Black using **kas**. It organizes the build system with a custom folder structure, ensuring better dependency management and reuse of downloads and sstate across multiple builds.

---

### BeagleBone Black Yocto Layer

For the BeagleBone Black (BBB) layer, I utilized the [meta-bbb](https://github.com/jumpnow/meta-bbb) from the Jumpnow GitHub repository. This project includes all the necessary configuration and customization for the BBB.

---

### Folder Structure

I prefer the following custom structure for managing Yocto builds:

- `bitbake.downloads`
- `bitbake.sstate`
- `build`
- `kas`
- `layers`
- `scripts`
- `source`
- `tmp_backups`

---

### Kas Configuration

I use **kas** to manage the layers and dependencies for this project. Below is a snippet from my **kas** YAML file (`bbb.yml`). Modify the paths to match your environment:

```yaml
header:
  version: 1

machine: beaglebone
distro: poky
target: console-image

repos:
  poky:
    url: https://github.com/yoctoproject/poky.git
    branch: scarthgap
    path: "source/poky"
    layers:
      meta:
      meta-poky:
      meta-yocto-bsp:

  meta-openembedded:
    url: git://git.openembedded.org/meta-openembedded
    branch: scarthgap
    path: "layers/meta-openembedded"
    layers:
      meta-oe:
      meta-python:
      meta-networking:

  meta-bbb:
    url: https://github.com/jumpnow/meta-bbb.git
    branch: scarthgap
    path: "layers/meta-bbb"

  meta-security:
    url: git://git.yoctoproject.org/meta-security.git
    branch: scarthgap
    path: "layers/meta-security"

  meta-qt5:
    url: https://code.qt.io/yocto/meta-qt5.git
    branch: lts-5.15
    path: "layers/meta-qt5"
```

---

### Build Configuration

The following configurations are part of the local.conf settings required for the BeagleBone Black. Below is a snippet from my **kas** YAML file (`bbb.yml`).

`TMPDIR` will be used to determine the build directory . Modify the parameters and paths to match your environment:

```yaml
local_conf_header:
    meta-bbb: |
        DISTRO_FEATURES:append = " security systemd usrmerge"
        PACKAGE_CLASSES ?= "package_rpm"
        PATCHRESOLVE = "noop"
        BB_DISKMON_DIRS ??= "\
            STOPTASKS,${TMPDIR},1G,100K \
            STOPTASKS,${DL_DIR},1G,100K \
            STOPTASKS,${SSTATE_DIR},1G,100K \
            STOPTASKS,/tmp,100M,100K \
            HALT,${TMPDIR},100M,1K \
            HALT,${DL_DIR},100M,1K \
            HALT,${SSTATE_DIR},100M,1K \
            HALT,/tmp,10M,1K"

        PACKAGECONFIG:append:pn-qemu-system-native = " sdl"
        CONF_VERSION = "2"
        #TMPDIR = "kas_custom_bbb"
        DL_DIR ?= "${HOME}/workspace/embeddedlinux/yocto/bitbake.downloads"
        SSTATE_DIR ?= "${HOME}/workspace/embeddedlinux/yocto/bitbake.sstate"
        EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
        USER_CLASSES ?= "buildstats"
        DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
        VIRTUAL-RUNTIME_init_manager = "systemd"
        VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"
        KERNEL_FEATURES:append = " cfg/systemd.scc"
        ROOT_HOME = "/root"
```

---

### Build Instructions

1. Install **kas**:
  
  ```bash
  sudo apt install python3-pip
  pip install kas
  ```
  
2. make the environment:
  
  ```bash
  kas checkout kas/bbb.yml
  source source/poky/oe-init-build-env  build/
  ```
3. make the image:
  ```bash
  bitbake console-image
  ```  
4. View the generated files in:
  
  ```bash
  ls tmp/deploy/images/beaglebone/
  ```
  

---

### Preparing the SD Card

Use the following steps to format and prepare your SD card:

1. Find your SD card:
  
  ```bash
  lsblk  # Look for /dev/mmcblk--
  ```
  
2. Create partitions and move the files to SD card:
  
  ```bash
  layers/meta-bbb/scripts/mk2parts.sh
  ```
  
3. Prepare the environment for the boot and root partition scripts:
  
  ```bash
  sudo mkdir /media/card
  export OETMP="/home/mominux/workspace/yocto/build/custom_bbb/tmp"
  sudo apt install dosfstools mtools
  ```
  
4. Copy the boot partition files:
  
  ```bash
  layers/meta-bbb/scripts/copy_boot.sh mmcblk0
  ```
  
5. Copy the root filesystem files:
  
  ```bash
  layers/meta-bbb/scripts/copy_rootfs.sh mmcblk0
  ```
  

---

### Debugging via Serial Port

Insert the SD card into your BeagleBone Black and use the serial port to check logs:

```bash
sudo picocom -b 115200 /dev/ttyUSB0
```

---

That's it! You're ready to boot your BeagleBone Black.
