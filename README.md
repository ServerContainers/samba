# samba - (servercontainers/samba) [x86 + arm]

samba on alpine

## Changelogs

* 2020-11-08
    * fixed samba user creation
    * custom avahi service name
* 2020-11-05
    * multiarch build
    * rewrite from debian to alpine
    * enhanced timemachine support

## Info

This is a Samba Server Container running on `_/alpine`.

## Environment variables and defaults

### Samba

*  __SAMBA\_GLOBAL\_CONFIG\_someuniquevalue__
    * add any global samba config to `smb.conf`
    * example value: `key = value`

* __ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new user account with the given username and the env value as password
    * to restrict access of volumes you can add the following to your samba volume config:
        * `valid users = alice; invalid users = bob;`

* __MODEL__
    * _optional_ model value of avahi samba service
    * _default:_ `TimeCapsule`
    * some available options are Xserve, PowerBook, PowerMac, Macmini, iMac, MacBook, MacBookPro, MacBookAir, MacPro, MacPro6,1, TimeCapsule, AppleTV1,1 and AirPort.

* __AVAHI\_NAME__
    * _optional_ name of avahi samba service
    * _default:_ _hostname_

* __SAMBA\_CONF\_WORKGROUP__
    * default: _WORKGROUP_

* __SAMBA\_CONF\_SERVER\_STRING__
    * default: _Samba Server_

* __SAMBA\_CONF\_MAP_TO_GUEST__
    * default: _Bad User_

* __SAMBA\_VOLUME\_CONFIG\_myconfigname__
    * adds a new samba volume configuration
    * multiple variables/confgurations possible by adding unique configname to SAMBA_VOLUME_CONFIG_
    * take a look at https://wiki.samba.org/index.php/Configure_Samba_to_Work_Better_with_Mac_OS_X -> EXPLANATION OF VOLUME PARAMETERS
    * for timemachine only add `fruit:time machine = yes` and all other needed settings are automatically added
        * you can also use `fruit:time machine max size = 500G;` to limit max size of time machine volume

### Volumes

* __your shares__
    * by default I recommend mounting all shares beneath `/shares` and configure them using the `path` property
    * the file `.samba-volume-uuid` gets created and should not be removed - especially on timemachine volumes it stores the uuid of the volume

* __/external/avahi__
    * mount your avahi service folder e.g. `/etc/avahi/services/` to this spot
    * the container now maintains the service file `samba.service` for you - __it will be overwritten!__
    * when mounted, the internal avahi daemon will be disabled


## Some helpful indepth informations about TimeMachine and Avahi / Zeroconf 

### General Infos

- Samba
    - https://github.com/willtho89/docker-samba-timemachine/
    - https://wiki.samba.org/index.php/Configure_Samba_to_Work_Better_with_Mac_OS_X

- Avahi
    - https://openwrt.org/docs/guide-user/services/nas/samba_configuration#zeroconf_advertising
    - http://samba.sourceforge.net/wiki/index.php/Bonjour_record_adisk_adVF_values
    - https://linux.die.net/man/5/avahi.service


You can't proxy the zeroconf inside the container to the outside, since this would need routing and forwarding to your internal docker0 interface from outside.
So you need to use the `network=host` mode to enable zeroconf from within the container

You can just expose the needed Port 548 to the docker hosts port and install avahi.
After that just add a new service which fits to your config.

