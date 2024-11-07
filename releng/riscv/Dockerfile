FROM riscv64/ubuntu:latest

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    software-properties-common \
    ca-certificates \
    lsb-release \
    build-essential \
    libboost-all-dev \
    libssl-dev \
    libgtk-3-dev \
    libglu1-mesa-dev \
    libgtk-3-dev \
    libgtk-4-dev \
    openssh-server \
    unzip \
    zip \
    tigervnc-standalone-server \
    locales \
    mesa-vulkan-drivers \
    mesa-utils

# Deactivate SSH authentication with password
RUN sed -Ei 's/^ *#? *PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
RUN sed -Ei 's/^ *#? *ForwardX11.*/ForwardX11 yes/g' /etc/ssh/sshd_config
RUN sed -Ei 's/^ *#? *X11UseLocalhost.*/X11UseLocalhost yes/g' /etc/ssh/sshd_config
RUN sed -Ei 's/^ *#? *AddressFamily any/AddressFamily inet/g' /etc/ssh/sshd_config
RUN sed -Ei 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Create necessary directories for sshd
RUN mkdir -p /run/sshd

# Install OpenJDK 21 (Temurin)
RUN mkdir -p /opt/java && \
    wget -q https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.3%2B9/OpenJDK21U-jdk_riscv64_linux_hotspot_21.0.3_9.tar.gz -O temurin.tar.gz && \
    tar -xzf temurin.tar.gz -C /opt/java --strip-components=1 && \
    ln -s /opt/java/bin/java /usr/bin/java && \
    rm temurin.tar.gz

# Install Maven
RUN wget https://downloads.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz -O maven.tar.gz && \
    tar -xzf maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.9 /opt/maven && \
    rm maven.tar.gz

# Install ant
RUN wget -q -O /tmp/ant.zip 'https://archive.apache.org/dist/ant/binaries/apache-ant-1.10.5-bin.zip'
RUN wget -q -O /tmp/ant-contrib.tgz  https://sourceforge.net/projects/ant-contrib/files/ant-contrib/ant-contrib-1.0b2/ant-contrib-1.0b2-bin.tar.gz
RUN ln -s /usr/local/apache-ant-1.10.5/bin/ant /usr/bin/ant
RUN unzip -q -d /usr/local /tmp/ant.zip
RUN tar xpfz /tmp/ant-contrib.tgz -C /usr/local/apache-ant-1.10.5/lib --strip-components=2 ant-contrib/lib/ant-contrib.jar
RUN /usr/sbin/locale-gen en_US.utf8

# Remove text/plain file associations
RUN sed -i -E 's%#*(.*text/plain.*)%#\1%g' /usr/share/applications/*

RUN useradd -s /bin/bash -m -d /home/jenkins jenkins \
  && mkdir /home/jenkins/.ssh \
  && touch /home/jenkins/.ssh/authorized_keys \
  && ssh-keyscan -t rsa github.com projects-storage.eclipse.org > /home/jenkins/.ssh/known_hosts \
  && chown -R jenkins:jenkins /home/jenkins/.ssh \
  && chmod -R "g=,o=" /home/jenkins/.ssh 

COPY entrypoint.sh .
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

EXPOSE 22
