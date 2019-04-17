FROM debian:stretch-slim

ENV FETCH_DEPS 'ca-certificates wget apt-transport-https'

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		gnupg \
		dirmngr \
		${FETCH_DEPS} \
	; \
	rm -rf /var/lib/apt/lists/*

# Install aws cli to fetch secrets
# TODO: Fix this by creating a common-base image in house VSKS-1941
RUN apt-get update && \
    apt-get -y install python python-pip curl unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    pip install pyyaml requests

# The lastest release of snoopy is 2.4.6, which was created on 09/24/2016. However this release is not
# compatible with gcc 7.3.0 installed in photon:3.0. Thus we choose to use the git commit with fix for this
# issue to build the snoopy. The commit is 360bb18e16ceaca16a22b94be9e17fd5f2184c01, which was created on 12/27/2018.
#
#
# sed -i 's/SNOOPY_INSTALL_CONFIGURE_SYSCONFDIR=\"--sysconfdir=\/etc\"/SNOOPY_INSTALL_CONFIGURE_SYSCONFDIR=\"--sysconfdir=\/etc\/snoopy\"/g' snoopy-install.sh && \
# is to modify the installation script snoopy-install.sh to set the config file for snoopy to be placed in the folder /etc/snoopy.
#
# sed -i '/^;output = file:\/var\/log\/snoopy.log/i output = file:\/var\/log\/snoopy\/snoopy.log' /etc/snoopy/snoopy.ini
# is to insert the following line into /etc/snoopy/snoopy.ini in order to output logs to /var/log/snoopy/snoopy.log
# ============================================
# output = file:/var/log/snoopy/snoopy.log
# ============================================
#
# sed -i '/^;message_format = \"useless static log entry that gets logged on every program execution\"/i message_format = "[time:%{datetime} uid:%{uid} username:%{username} sid:%{sid} tty:%{tty} cwd:%{cwd} filename:%{filename}]: %{cmdline}"' /etc/snoopy/snoopy.ini
# is to insert the following line into /etc/snoopy/snoopy.ini in order to set up the format of the output logs
# ============================================
# message_format = "[time:%{datetime} uid:%{uid} username:%{username} sid:%{sid} tty:%{tty} cwd:%{cwd} filename:%{filename}]: %{cmdline}"
# ============================================
#
# sed -i '/^;filter_chain = \"\"/i filter_chain = "exclude_spawns_of:cron"' /etc/snoopy/snoopy.ini && \
# is to insert the following line into /etc/snoopy/snoopy.ini in order to omit the logging of the descendant processes of cron
# ============================================
# filter_chain = "exclude_spawns_of:cron"
# ============================================
# Please refer to https://github.com/a2o/snoopy/blob/master/etc/snoopy.ini.in for details about configuration of snoopy
RUN apt-get update && \
    apt-get install -y libtool-bin && \
    rm -f snoopy-install.sh && \
    wget -O snoopy-install.sh https://github.com/a2o/snoopy/raw/install/doc/install/bin/snoopy-install.sh && \
    sed -i 's/SNOOPY_INSTALL_CONFIGURE_SYSCONFDIR=\"--sysconfdir=\/etc\"/SNOOPY_INSTALL_CONFIGURE_SYSCONFDIR=\"--sysconfdir=\/etc\/snoopy\"/g' snoopy-install.sh && \
    chmod 755 snoopy-install.sh && \
    ./snoopy-install.sh git-360bb18e16ceaca16a22b94be9e17fd5f2184c01 && \
    snoopy-enable && \
    mkdir /var/log/snoopy && \
    sed -i '/^;output = file:\/var\/log\/snoopy.log/i output = file:\/var\/log\/snoopy\/snoopy.log' /etc/snoopy/snoopy.ini && \
    sed -i '/^;message_format = \"useless static log entry that gets logged on every program execution\"/i message_format = "[time:%{datetime} uid:%{uid} username:%{username} sid:%{sid} tty:%{tty} cwd:%{cwd} filename:%{filename}]: %{cmdline}"' /etc/snoopy/snoopy.ini && \
    sed -i '/^;filter_chain = \"\"/i filter_chain = "exclude_spawns_of:cron,python"' /etc/snoopy/snoopy.ini && \
    touch /var/log/snoopy/snoopy.log

RUN apt-get update && \
    apt-get -y install vim

COPY *.py /
COPY snoopy.ini /etc/snoopy/snoopy.ini

ENTRYPOINT ["python", "/main.py"]
