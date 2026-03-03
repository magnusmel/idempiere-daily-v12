FROM ubuntu:24.04

LABEL maintainer="orlando.curieles@ingeint.com"

# Modern ENV syntax to resolve all previous warnings
ENV IDEMPIERE_VERSION=12 \
    IDEMPIERE_HOME=/opt/idempiere \
    IDEMPIERE_PLUGINS_HOME=/opt/idempiere/plugins \
    IDEMPIERE_LOGS_HOME=/opt/idempiere/log

# 1. Install system dependencies (including unzip for the build process)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nano postgresql-client openjdk-17-jdk unzip patch libc6 libstdc++6 libgcc1 && \
    rm -rf /var/lib/apt/lists/*

# 2. Setup user and structure (Stay as root for now)
RUN useradd -d $IDEMPIERE_HOME -m -s /bin/bash idempiere && \
    mkdir -p $IDEMPIERE_HOME && \
    ln -s $IDEMPIERE_HOME/idempiere-server.sh /usr/bin/idempiere

WORKDIR $IDEMPIERE_HOME

# 3. Handle the local ZIP file
COPY idempiereServer12Daily.gtk.linux.x86_64.zip /tmp/idempiere.zip

# This script finds the actual server folder inside the zip and moves it to $IDEMPIERE_HOME
RUN unzip -q /tmp/idempiere.zip -d /tmp/extracted && \
    SOURCE_DIR=$(find /tmp/extracted -type d -name "idempiere-server" | head -n 1) && \
    cp -R $SOURCE_DIR/* $IDEMPIERE_HOME/ && \
    rm -rf /tmp/extracted /tmp/idempiere.zip

# 4. Handle entrypoint and permissions
COPY docker-entrypoint.sh $IDEMPIERE_HOME/docker-entrypoint.sh
RUN chmod +x $IDEMPIERE_HOME/docker-entrypoint.sh && \
    chown -R idempiere:idempiere $IDEMPIERE_HOME

# Add this line before the "USER idempiere" instruction
RUN mkdir -p $IDEMPIERE_LOGS_HOME $IDEMPIERE_PLUGINS_HOME && \
    chown -R idempiere:idempiere $IDEMPIERE_HOME

# 5. Switch to unprivileged user for runtime security
USER idempiere

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["idempiere"]