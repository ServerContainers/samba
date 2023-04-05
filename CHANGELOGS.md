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
