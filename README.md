# Skwr - Kubernetes is great, but sometimes it's too much

Skwr (pronounced 'square') is a framework to manage applications bundled in a single docker container on a single node. Current features include:

* containers deployed as systemd services (logs available through journalctl, auto-restart in case of failure)
* containers automatically updated (including a newer base image)

The original goal of this project is to be able to manage one's own router, where each service (DNS, DHCP, etc) is a container, and centralize all of the common configuration/tooling.
