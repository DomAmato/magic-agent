FROM ubuntu:bionic

RUN apt-get update && \
    apt-get install -yy \
        freeradius \
        freeradius-config \
        freeradius-common \
        python \
        python3 \
        python-pip \
        python3-pip \
	libssl-dev \
	libgmp3-dev \
	libffi6 \
	libffi-dev \
	libtool \
	autoconf \
	pkg-config

RUN pip install future

# Set the install location for the agent
ENV MAGIC_LOC /usr/app/agent
WORKDIR ${MAGIC_LOC}

# Copy all the files we actually need to run the agents
COPY magic magic
COPY requirements.txt .
COPY setup.py .
COPY version.txt .
COPY MANIFEST.in .
COPY conf/user-config.hjson magic/gateway/config

# Install, note the when this installs it installs it to the python dist-packages
# thats why we need the manifest
RUN pip3 install .

# Move the resources into place
RUN mv ./magic/resources/inner-tunnel /etc/freeradius/3.0/sites-enabled/inner-tunnel
RUN mv ./magic/resources/python-magic /etc/freeradius/3.0/mods-enabled/python-magic
RUN sed -i "s@MAGIC_LOC@"${MAGIC_LOC}"@g" /etc/freeradius/3.0/mods-enabled/python-magic
RUN mv ./magic/resources/eap /etc/freeradius/3.0/mods-enabled/eap
RUN mv ./magic/resources/clients.conf /etc/freeradius/3.0/clients.conf

COPY run.sh /run.sh
COPY ssl/* /etc/freeradius/3.0/certs/

EXPOSE 5000/tcp 1812/udp 1813/udp

# Add Tini
ENV TINI_VERSION v0.18.0
ARG ARCH=amd64
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${ARCH} /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--"]
CMD ["/run.sh", "gateway", "start"] # Set default command
