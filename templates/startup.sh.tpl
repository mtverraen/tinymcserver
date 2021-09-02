#!/bin/bash

gsutil -m rsync -x ".*\.log\.gz$" -r ${bucket} /var/minecraft

docker run -d --name mc \
  -p ${minecraft_port}:${minecraft_port} \
  -p ${rcon_port}:${rcon_port} \
  -v /var/minecraft:/data \
  -e EULA=TRUE \
  -e VERSION=${minecraft_version} \
  -e MEMORY=3G \
  -e SERVER_NAME=${server_name} \ 
  -e WHITELIST=${whitelist} \
  -e OPS=${ops} \
  -e CF_SERVER_MOD="permaserver-3.1.zip" \
  -e TYPE="CURSEFORGE" \
  itzg/minecraft-server:latest