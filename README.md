# samba - (ghcr.io/servercontainers/samba) [x86 + arm]

samba on alpine

with timemachine, zeroconf (`avahi`) and WSD (Web Services for Devices) (`wsdd2`) support.

Note that there are issues regarding UID/GID Mapping on Docker Desktop - see: https://github.com/ServerContainers/samba/issues/125

## IMPORTANT!

__New Registry:__ `ghcr.io/servercontainers/samba`

In March 2023 - Docker informed me that they are going to remove my 
organizations `servercontainers` and `desktopcontainers` unless 
I'm upgrading to a pro plan.

I'm not going to do that. It's more of a professionally done hobby then a
professional job I'm earning money with.

In order to avoid bad actors taking over my org. names and publishing potenial
backdoored containers, I'd recommend to switch over to my new github registry: `ghcr.io/servercontainers`.

## Build & Variants

You can specify `DOCKER_REGISTRY` environment variable (for example `my.registry.tld`)
and use the build script to build the main container and it's variants for _x86_64, arm64 and arm_

You'll find all images tagged like `a3.15.0-s4.15.2` which means `a<alpine version>-s<samba version>`.
This way you can pin your installation/configuration to a certain version. or easily roll back if you experience any problems.

To build a `latest` tag run `./build.sh release`

For builds without specified registry you can use the `generate-variants.sh` script to generate 
variations of this container and build the repos yourself.

_all of those variants are automatically build and generated in one go_

- `latest` or `a<alpine version>-s<samba version>`
    - main version of this repo
    - includes everything (smbd, avahi, wsdd2)
    - not all services need to start/run -> use ENV variables to disable optional services
- `smbd-only-latest` or `smbd-only-a<alpine version>-s<samba version>`
    - this will only include smbd and my scripts - no avahi, wsdd2 installed
- `smbd-avahi-latest` or `smbd-avahi-a<alpine version>-s<samba version>`
    - this will only include smbd, my scripts and avahi
    - optional service can still be disabled using ENV variables
- `smbd-wsdd2-latest` or `smbd-wsdd2-a<alpine version>-s<samba version>`
    - this will only include smbd, my scripts and wsdd2
    - optional service can still be disabled using ENV variables

## Changelogs

* 2025-09-02
    * improved `[global]` setting `vfs objects = streams_xattr`
        * `streams_xattr` is needed for macOS / iOS integration
        * fixed broken vfs objects fruit configuration
        * see: https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html
        * more about that bug: https://github.com/ServerContainers/samba/issues/125
        * general cleanup of global fruit configuration
        * bug #125 reopened
    * added new environment variable `DISABLE_FRUIT_DEFAULTS` to disable all fruit extention
        * a way to hopefully fix https://github.com/ServerContainers/samba/issues/125
        * negative effects for macOS / iOS / iPadOS clients etc. use safely if you don't use these devices
        * should make this container work on special underlaying filesystems
        * default not set
* 2025-08-08
    * Update: WARNING the following statement was wrong! - it broke the fruit configuration
    * removed `[global]` setting `vfs objects = streams_xattr`
        * people seem to have more problems with it than it helps
        * more infos about this setting: `https://www.samba.org/samba/docs/current/man-html/vfs_streams_xattr.8.html`
        * to restore the old configuration add `vfs objects = catia fruit streams_xattr` to each share
        * this should fix bug #125 - maybe other bugs as well
* 2024-09-22
    * fixed filename handling for names with special chars
        * `mangled names = no; dos charset = CP850; unix charset = UTF-8`
    * added new environment variable to `FAIL_FAST` on user/group creation/errors/conflicts (#139)
* 2024-07-05
    * improved github workflow - don't fail if it just skipped the build.
    * sign images with cosign
* 2024-05-27
    * added `.dockerignore` to exlcude unnecessary files and history
* 2024-05-23
    * updated github actions (see pull #131)
    * fixed broken build/version
* 2024-04-16
    * added `tzdata` package to support setting the timezone using an env
        * e.g. `TZ=Europe/Berlin`
* 2024-03-22
    * merged pull request which fixed avahi on smbd-only and smbd-wsdd2 variants
        * solution was to just deactivate the avahi service and not remove the config folder
* 2024-03-11
    * patch `host-name` in `/etc/avahi/avahi-daemon.conf` if `AVAHI_NAME` env is set
    * fixed build - overwrite `latest` tag if there was a commit within last hour
        * the tagged version will remain unchanged to avoid problems for pinned container versions.
* 2024-01-08
    * multiline config for shares available
        * optional
        * better readability
        * merged important parts from pull request #60 by hand
* 2024-01-04
    * fix for disabled nmbd #118
* 2023-12-01
    * made `nmbd` optional use `NETBIOS_DISABLE=true` to disable nmbd
* 2023-10-08
    * fixed avahi service config - `</service-group>` error (Issue #107)
* 2023-09-24
    * added `nmbd` service and increase compatibility
    * print `smb.conf` on initialization to make `testparm -s` problems visible
    * updated github build to fail if build/version combination already exists as tag
* 2023-09-16
    * implemented working version of pull #87
    * fixed avahi model which now works without a single timemachine share
    * avahi will now be configured without timemachine
* 2023-08-07
    * create all groups, than create all users, and after that add users to groups - this gives a more clear and clean way to add users to different groups
* 2023-07-29
    * added `vfs objects = catia fruit streams_xattr` to global config to improve macos compatibility - closes issue #93

__older changelogs__ -> [CHANGELOGS.md](CHANGELOGS.md)


## Info

This is a Samba Server Container running on `_/alpine`.

## Troubleshooting

If you experience Problems, take a look at this file: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Environment variables and defaults

### Samba

*  __DISABLE\_FRUIT\_DEFAULTS__
    * _optional_
    * default not set - set to any value to enable
    * will reduce all settings which help apple devices (tags, metadata, timmachine etc.)
    * will fail if timemachine is enabled
    * try this, if you have troubles with your shares
        * you experience the same problems as in this bug https://github.com/ServerContainers/samba/issues/125
        * might work on proxmox, if underlaying shares are not a normal filesystems etc.

*  __SAMBA\_GLOBAL\_STANZA__
    * _optional_
    * default not set
    * use it to manage multiple global settings in one place
    * separate multiple settings/lines using `;` which will be automatically translated to `\n`

*  __SAMBA\_GLOBAL\_CONFIG\_someuniquevalue__
    * add any global samba config to `smb.conf`
    * example value: `key = value`
    * important if the SAMBA key contains a ` ` space replace it with `_SPACE_`
        * e.g. `foo_SPACE_bar`
    * important if the SAMBA key contains a `:` space replace it with `_COLON_`
        * e.g. `foo_COLON_bar`

* __ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new user account with the given username and the env value as password or samba hash
        * either you add a simple plaintext password as value (can't start with `:`username`:[0-9]*:` or it will be detected as hash)
        * to add a samba hash e.g. `user:1002:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-5FE1F7DF:` (user: `user` / password: `password`) add the line from `/var/lib/samba/private/smbpasswd`
        * create hash using this command `docker run -ti --rm --entrypoint create-hash.sh ghcr.io/servercontainers/samba`
        * see `docker-compose.yml` user `foo` for an example how it's used/configured.
        * the hashing script needs an all lowercase username - it will therefore automatically lowercase given username
    * to restrict access of volumes you can add the following to your samba volume config:
        * `valid users = alice; invalid users = bob;`

* __UID\_username__
    * optional
    * specify the `uid` explicitly for each user account.
    * the `username` part must match to a specified `ACCOUNT_username` environment variable

* __GROUP\_groupname__
    * optional
    * value will be `gid`
    * example: `GROUP_devops=1500` will create group `devops` with id `1500`
    * do not use for the default user groups e.g. `GROUP_bob=1000` - those groups are automatically created for the user

* __GROUPS\_username__
    * optional
    * additional groups for the user
    * to create groups look at `GROUP_groupname` or mount/inject /etc/groups file (can cause problems)
    * the `username` part must match to a specified `ACCOUNT_username` environment variable
    * one or more groups to add separated by a `,`
    * example: `GROUPS_johndoe=musican,devops`

* __MODEL__
    * _optional_ model value of avahi samba service
    * _default:_ `TimeCapsule`
    * some available options are `Xserve`, `PowerBook`, `PowerMac`, `Macmini`, `iMac`, `MacBook`, `MacBookPro`, `MacBookAir`, `MacPro`, `MacPro6,1`, `MacPro7,1` (Tower), `MacPro7,1@ECOLOR=226,226,224` (Rack), `TimeCapsule`, `AppleTV1,1` and `AirPort`.

* __FAIL\_FAST__
    * _optional_ currently only fails fast if there are conflicts/errors during user/group creation
    * default not set - set to any value to enable

* __AVAHI\_NAME__
    * _optional_ name of avahi samba service
    * _default:_ _hostname_

* __AVAHI\_DISABLE__
    * _optional_
    * default not set - set to any value to disable avahi Service

* __SAMBA\_CONF\_SERVER\_ROLE__
    * default: _standalone server_
    * note: `$` is an invalid symbol in this env

* __SAMBA\_CONF\_LOG\_LEVEL__
    * default: _1_

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
    * multiline support -> look into `docker-compose.yml` for example
    * separate multiple lines using `;` which will be automatically translated to `\n`
    * if your path variable ends with `%U` e.g. `path = /shares/homes/%U;` multi user mode gets activated and each user gets their own subdirectory for their own share. (great for timemachine - every user get's his own personal share)
    * for timemachine only add `fruit:time machine = yes` and all other needed settings are automatically added
        * you can also use `fruit:time machine max size = 500G;` to limit max size of time machine volume

* __WSDD2\_DISABLE__
    * _optional_
    * default not set - set to any value to disable wsdd2 Service
* __WSDD2\_PARAMETERS__
    * _optional_ specify parameters for wsdd2
    * default not set - wsdd2 starts without any parameters
    * e.g. `-l`

* __NETBIOS\_DISABLE__
    * _optional_
    * default not set - set to any value to disable `nmbd`
    * _not recommended_ - you should know that you want it disabled

### Volumes

* __your shares__
    * by default I recommend mounting all shares beneath `/shares` and configure them using the `path` property

* __/external/avahi__
    * mount your avahi service folder e.g. `/etc/avahi/services/` to this spot
    * the container now maintains the service file `samba.service` for you - __it will be overwritten!__
    * when mounted, the internal avahi daemon will be disabled


## Some helpful indepth informations about TimeMachine and Avahi / Zeroconf 

### General Infos

- Samba
    - https://github.com/willtho89/docker-samba-timemachine/
    - https://github.com/sp00ls/SambaConfigs very interessting multi user timemachine setup
    - https://wiki.samba.org/index.php/Configure_Samba_to_Work_Better_with_Mac_OS_X
    - https://serverfault.com/questions/1010822/samba4-issues-with-time-machine-cannot-create-new-backup-on-samba-share

- Avahi
    - https://openwrt.org/docs/guide-user/services/nas/samba_configuration#zeroconf_advertising
    - http://samba.sourceforge.net/wiki/index.php/Bonjour_record_adisk_adVF_values
    - https://linux.die.net/man/5/avahi.service


You can't proxy the zeroconf inside the container to the outside, since this would need routing and forwarding to your internal docker0 interface from outside.
So you need to use the `network=host` mode to enable zeroconf from within the container

You can just expose the needed Port 548 to the docker hosts port and install avahi.
After that just add a new service which fits to your config.

### My personal TimeMachine recommendation

If you have a more sophisticated network setup (vpn, different networks etc.) you might want to avoid using zeroconfig + avahi in combination with TimeMachine.

Zeroconf limits you to the autodiscovered mdns names (`$AVAHI_NAME` + `.local`). So whenever your mac can't pic up this zeroconf configuration TimeMachine will not backup your machine.
This is not bad in a normal guy's personal homenetwork. Here it would backup everytime the user is at home and has all devices (and his backup nas) in one LAN.

To overcome this issue, I'd suggest to connect your NAS/Samba Server manually using `Finder` -> Go -> Connect to Server (or shortcut `⌘k`).
Enter the FQDN or IP of the server and the path to your timemachine share you want to connect to and establish the connection.

Once the connection is established, you can open `Settings` -> TimeMachine and add/choose this newly connected share as your place to store your backups. You'll notice that it now shows the FQDN or IP you choose.
If you already used this NAS but with zeroconf it should detect that there are already backups for your mac and asks/continues using them - so a full backup shouldn't be required if you switch your connection method.

After you made this more explicit network configuration it will backup as soon as your device is reachable - so if a connection via VPN or cause of network cascading is possible. this way you can backup from any network as long as routing works :)

## Windows 10 Network Discovery

For the Windows 10 Network Discovery the `hostname` of the container is used.
If you use `network_mode: host` then it's the docker-host `hostname`.

If you use any other `network_mode` and want to avoid the autogenerated cryptic hostname of the container, you can specify
a explicit hostname using: `hostname: my-samba-containers-hostname`

- WSD
    - https://devanswers.co/discover-ubuntu-machines-samba-shares-windows-10-network/
    - https://github.com/Netgear/wsdd2

Note: _This `wsdd2` service seems to need `CAP_NET_ADMIN` as a capability. (more info: https://github.com/ServerContainers/samba/issues/50)_
```
    cap_add:
      - CAP_NET_ADMIN
```
