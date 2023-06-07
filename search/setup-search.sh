#!/bin/bash

# The gpgcheck is disable here because for some reason, Elastic is still using SHA1 signatures and 
# RHEL9/Rocky9 want sha2 .... There's probably another answer to this problem. One that looks at the 
# Linux release and decides how to handle it based on that.
#
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat << EOF > /etc/yum.repos.d/elastic.repo
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=0
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md

[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=0
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
# Install Kibana and elasticsearch
dnf -y  install --enablerepo=elasticsearch elasticsearch kibana jq java-11-openjdk

copy elasticsearch.yml /etc/elasticsearch/

# start elastic search
systemctl enable elasticsearch --now 
# Elastic creates a superuser password and it shows in the dnf.rpm.log
ELSUPASS=$(awk /"The generated password for the elastic built-in superuser is"/'{print $NF}' /var/log/dnf.rpm.log )

# Enable and start kibana
systemctl enable kibana --now

# Enroll kibana with elastic.
KENROLL=$(/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)
/usr/share/kibana/bin/kibana-setup --enrollment-token "$KENROLL"

# Need this to access kibana, but should not be left open.
# In fact, for this implementation, kibana only needs to be run during management of the site.
# It might be better to leave it closed, and access it via ssh tunnel.
# ssh -L 5601:localhost:5601 <server hostname> 
firewall-cmd --add-port 5601/tcp

#elastic enterprise search 



# Display Cluster Info and password
curl -k -u "elastic:${ELSUPASS}" https://localhost:9200  | jq .
echo "Elastic Superuser password: $ELSUPASS"

# Elastic UI 
# https://docs.elastic.co/search-ui/tutorials/elasticsearch

