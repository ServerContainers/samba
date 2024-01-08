* 2023-05-17
    * removed `fruit:advertise_fullsync` which doesn't exist
* 2023-04-20
    * added `testparm -s` to check config before starting - closes issue #81
    * removed `socket options`, let the systems negotiate
* 2023-04-11
    * fixed pid bug on container restarts
* 2023-03-20
    * github action to build container
    * implemented ghcr.io as new registry
* 2023-03-15
    * switched from docker hub to a build-yourself container
* 2023-02-06
    * fixed capitalization of username while hashing - convert to lowercase
* 2022-12-05
    * fixed `SAMBA_GLOBAL_CONFIG_...` with colon in the key.
* 2022-05-31
    * support for `server role` as ENV parameter
* 2022-01-31
    * support for global settings via stanza (similar to volume config)
* 2022-01-28
    * removed old `chmod 777, chown nodboy:nogroup` statements on multi user shares
* 2022-01-20
    * fixed healthcheck for container `avahi`
* 2022-01-08
    * better build script
* 2021-12-30
    * fix for disabling `wsdd2`
    * verbose execution of service start
    * log to `stdout`
    * fixed connection issues by pinning alpine to `3.14`
    * made `avahi` optional
    * new build process and variants
* 2021-12-25
    * multi user shares for all volumes possible
    * removed bash to same some space
    * improved `docker-compose.yml`
    * improved healthcheck
    * improved logging
* 2021-12-24
    * start `smbd` with `--foreground` parameter
    * fix for loglevel settings - it works now
    * new examples for shared shares in `docker-compose.yml`
    * start `wsdd2` after 10 seconds
* 2021-12-02
    * made `wsdd2` service optional
    * updated version
* 2021-09-27
    * added support for `wsdd2` parameterization
* 2021-08-30
    * added support for groups
* 2021-08-27
    * removed old multi arch build dockerfiles - `builx is used`
    * added `wsdd2` for service discovery on windows
* 2021-08-23
    * fixed `SAMBA_GLOBAL_CONFIG_...` missing key.
* 2021-08-08
    * added env to contorl `log level` - default value `1` 
    * fixed `SAMBA_GLOBAL_CONFIG_...` with spaces in the key.
* 2021-03-16
    * added support for specifing the `uid` for each `ACCOUNT_` using `UID_username=1234214` env.
* 2021-03-09
    * updated healthcheck to work with external avahi server
* 2020-12-22
    * added support for samba password hashes instead of just plaintext passwords
* 2020-12-10
    * added Timemachine Multiuser Support (samba config path needs to end with `%U`)
* 2020-12-09
    * bug fix: `</service-group>` gets removed with multiple timemachine volumes
* 2020-11-08
    * fixed samba user creation
    * custom avahi service name
* 2020-11-05
    * multiarch build
    * rewrite from debian to alpine
    * enhanced timemachine support
