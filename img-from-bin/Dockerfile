FROM docker.io/library/ubuntu:20.04

RUN useradd -m -u 1000 -U -s /bin/sh -d /node node && \
	mkdir -p /node/.local/share/node && \
	chown -R node:node /node/.local && \
	ln -s /node/.local/share/node /data && \
	rm -rf /usr/bin /usr/sbin

USER node
EXPOSE 30333 9933 9944
VOLUME ["/data"]

COPY ./kilt-parachain-with-log /usr/local/bin/node-executable

ENTRYPOINT ["/usr/local/bin/node-executable"]
CMD ["--help"]
