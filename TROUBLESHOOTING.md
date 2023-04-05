# MTLS Conflict on Host (Raspberry OS, Rasbian)

If you are already running Samba/Avahi on your Docker host (or you're wanting to run this on your NAS),
you should be aware that using --net=host will cause a conflict with the Samba/Avahi install.

Raspberry Pi users: be aware that there is already an mDNS responder running on the stock Raspberry Pi OS
image that will conflict with the mDNS responderin the container.

I've added a way to instruct the container to use the external host avahi by mounting `/external/avahi`
more infos about it here: https://github.com/ServerContainers/samba#volumes
this way the container will not start the avahi daemon/mtls service and place the service file into the mounted folder.

More comments/infos: https://github.com/ServerContainers/samba/issues/79
