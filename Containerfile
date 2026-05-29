FROM docker.io/library/archlinux:latest

# 1. Update the system and install systemd + basic tools
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm systemd dbus sudo cifs-utils sshfs openssh imagemagick rsync  && \
    pacman -Scc --noconfirm

# 2. Inform systemd that it is running inside an OCI container
ENV container=podman

# 3. Clean up unnecessary systemd services that cause issues in containers
RUN rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    rm -f /lib/systemd/system/plymouth*; \
    rm -f /lib/systemd/system/systemd-update-utmp*
COPY filesync.* /etc/systemd/system/

COPY syncscript.sh /usr/local/bin/syncscript

RUN chmod +x /usr/local/bin/syncscript
RUN useradd -m -s /bin/bash vnaftp

# 2. Set the password to 'Password1'
RUN echo "vnaftp:Password1" | chpasswd

RUN systemctl enable sshd \
    && systemctl enable filesync.timer



