# AOSP setup
[中文](./README_CN.md)  
Quick start my aosp sync up
```
git clone https://github.com/stuartore/aosp-setup.git && cd aosp-setup
./aosp.sh
```

### Custom
```
./aosp.sh ${ROM_manifest_url}

# example
./aosp.sh https://github.com/xxxxxxx/manifest.git
```
### Mirror
```
# set github & aosp mirror for synchonization
./aosp.sh --mirror

# keep mirror when sync source
./aosp.sh -k
./aosp.sh --keep-mirror
```

### Auto Build
```
./aosp.sh --auto_build {brand}/{device_code}

# example
./aosp.sh --auto_build xiaomi/psyche
```
> Debug: Still uer to fix error & mannual handle


# Get script status
Get script status on Wechat，[Click me](https://wxpusher.zjiecode.com/wxuser/?type=1&id=83609#/follow).

+ LineageOS
+ ArrowOS
+ Pixel Experience
+ RisingOS
+ Crdroid
+ AlphaDroid
+ Evolution-X
+ Project-Elixir
+ Paranoid Android (AOSPA)
+ PixysOS
+ SuperiorOS
+ PixelPlusUI
