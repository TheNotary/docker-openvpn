DOCKER_IMAGE_NAME=openvpn
DATA_VOL=ovpn-data

build:
	docker build -t ${USER}/${DOCKER_IMAGE_NAME} .

# You only need to run this command once after you've built the container
# it's interactive and will result in the production of a CLIENTNAME.ovpn key
# to be transfered to the client.  Notice udp://VPN.SERVERNAME.COM should 
# point to the server hosting openvpn server
configure:
	(docker rm ovpn-data && echo "Removed old data, please run command again") || \
	docker run --name ${DATA_VOL} -v /etc/openvpn busybox && \
	docker run --volumes-from ${DATA_VOL} --rm ${USER}/${DOCKER_IMAGE_NAME} ovpn_genconfig -u udp://VPN.SERVERNAME.COM && \
	docker run --volumes-from ${DATA_VOL} --rm -it ${USER}/${DOCKER_IMAGE_NAME} ovpn_initpki && \
  docker run --volumes-from ${DATA_VOL} --rm -it ${USER}/${DOCKER_IMAGE_NAME} easyrsa build-client-full CLIENTNAME nopass && \
  docker run --volumes-from ${DATA_VOL} --rm ${USER}/${DOCKER_IMAGE_NAME} ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

# to get this to work, I think you need to manually edit the CLIENTNAME 
# section to something unique for each seperate key you deploy from the server.
# I didn't double check this section so I may have misdone something so check
# this work...
genclientkey:
	docker run --volumes-from ${DATA_VOL} --rm -it ${USER}/${DOCKER_IMAGE_NAME} easyrsa build-client-full CLIENTNAME nopass && \
	docker run --volumes-from ${DATA_VOL} --rm ${USER}/${DOCKER_IMAGE_NAME} ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

# Run this command to 
run:
	docker run \
  --volumes-from ${DATA_VOL} -d -p 1194:1194/udp --cap-add=NET_ADMIN ${USER}/${DOCKER_IMAGE_NAME}

console:
	docker run -it \
  ${USER}/${DOCKER_IMAGE_NAME} bash

.PHONY: build
