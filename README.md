# still under construction

# samba
4.6.2 samba - freshly complied from official stable releases on debian:jessie

# Source Code
Check the following link for a new version: https://download.samba.org/pub/samba/stable/

## Environment variables and defaults

### Samba

* __ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new user account with the given username and the env value as password

to restrict access of volumes you can add the following to your samba volume config:

    valid users = alice; invalid users = bob;

* __SAMBA\_CONF\_WORKGROUP__
    * default: _WORKGROUP_

* __SAMBA\_CONF\_SERVER\_STRING__
    * default: _file server_

* __SAMBA\_CONF\_MAP_TO_GUEST__
    * default: _Bad User_

* __SAMBA\_VOLUME\_CONFIG\_myconfigname__
    * adds a new samba volume configuration
    * multiple variables/confgurations possible by adding unique configname to SAMBA_VOLUME_CONFIG_
    * examples
        * "[My Share]; path=/shares/myshare; guest ok = no; read only = no; browseable = yes"
        * "[Guest Share]; path=/shares/guests; guest ok = yes; read only = no; browseable = yes"

# Links
* https://wiki.samba.org/index.php/Samba_AD_DC_Port_Usage
* https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server
* https://www.samba.org/samba/docs/man/manpages-3/smb.conf.5.html
