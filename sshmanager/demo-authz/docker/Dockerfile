FROM ubuntu:latest

RUN apt-get update && apt-get install -y openssh-server cron unzip vim-tiny
RUN mkdir /run/sshd /usr/local/share/ca-certificates/extra /etc/skel/.ssh
RUN touch /etc/skel/.ssh/authorized_keys && chmod 644 /etc/skel/.ssh/authorized_keys
COPY src/sshd_config /etc/ssh/sshd_config
COPY src/ssh_config /etc/ssh/ssh_config
ADD src/root-ca-bundle.pem /usr/share/ca-certificates/extra/root-ca-bundle.pem
RUN echo "extra/root-ca-bundle.pem" >> /etc/ca-certificates.conf && /usr/sbin/update-ca-certificates
RUN /usr/sbin/useradd -m -o -u 0 -s /bin/bash ansible 
RUN echo 'ansible:password99!' | /usr/sbin/chpasswd
RUN echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYgHQvrZhyPx1lkVrSRM3fmWnuFhM3MeztbHUNcBf7W ansible@everywhere' > /home/ansible/.ssh/authorized_keys 
COPY src/crontab /etc/crontab
RUN chmod 0644 /etc/crontab
RUN crontab /etc/crontab

EXPOSE 22
CMD [ "/usr/sbin/cron", "-f" ]