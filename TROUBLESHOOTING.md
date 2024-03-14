# MTLS Conflict on Host (Raspberry OS, Rasbian)

If you are already running Samba/Avahi on your Docker host (or you're wanting to run this on your NAS),
you should be aware that using --net=host will cause a conflict with the Samba/Avahi install.

Raspberry Pi users: be aware that there is already an mDNS responder running on the stock Raspberry Pi OS
image that will conflict with the mDNS responderin the container.

I've added a way to instruct the container to use the external host avahi by mounting `/external/avahi`
more infos about it here: https://github.com/ServerContainers/samba#volumes
this way the container will not start the avahi daemon/mtls service and place the service file into the mounted folder.

More comments/infos: https://github.com/ServerContainers/samba/issues/79


# Problems with macOS and Windows / Docker Desktop

You might run into troubles on macOS (confirmed) and maybe even Windows (I suspect there might me similar issues).

It seems to me, that the filesystem mounts from the host to the container e.g. samba have problems with permissons etc.

One user couldn't delete files on the share he mounted from his macbook. I retried this on a macbook and wasn't even able to create files.

More comments/infos: https://github.com/ServerContainers/samba/issues/125 
