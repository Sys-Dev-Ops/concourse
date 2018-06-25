# https://concourse-ci.org/install.html
# Refer to https://www.digitalocean.com/community/tutorials/how-to-install-concourse-ci-on-ubuntu-16-04
sudo apt-get update
apt-get install -y postgresql postgresql-contrib
su - postgres
createuser concourse
createdb --owner=concourse atc
exit
/usr/sbin/update-rc.d postgresql enable
service postgresql start
wget https://github.com/concourse/concourse/releases/download/v3.14.1/concourse_linux_amd64
wget https://github.com/concourse/concourse/releases/download/v3.14.1/fly_linux_amd64
chmod 755 ./concourse_linux_amd64
chmod 755 ./fly_linux_amd64
mv ./concourse_linux_amd64 /usr/local/bin/concourse
mv ./fly_linux_amd64 /usr/local/bin/fly
#fly --version
#concourse --version
sudo mkdir /etc/concourse

sudo ssh-keygen -t rsa -q -N '' -f /etc/concourse/tsa_host_key
sudo ssh-keygen -t rsa -q -N '' -f /etc/concourse/worker_key
sudo ssh-keygen -t rsa -q -N '' -f /etc/concourse/session_signing_key

sudo cp /etc/concourse/worker_key.pub /etc/concourse/authorized_worker_keys

sudo echo CONCOURSE_SESSION_SIGNING_KEY=/etc/concourse/session_signing_key >/etc/concourse/web_environment
sudo echo CONCOURSE_TSA_HOST_KEY=/etc/concourse/tsa_host_key>>/etc/concourse/web_environment
sudo echo CONCOURSE_TSA_AUTHORIZED_KEYS=/etc/concourse/authorized_worker_keys>>/etc/concourse/web_environment
sudo echo CONCOURSE_POSTGRES_SOCKET=/var/run/postgresqlnano /etc/concourse/web_environment>>/etc/concourse/web_environment
sudo echo # Change these values to match your environment>>/etc/concourse/web_environment
sudo echo CONCOURSE_BASIC_AUTH_USERNAME=admin>>/etc/concourse/web_environment
sudo echo CONCOURSE_BASIC_AUTH_PASSWORD=admin>>/etc/concourse/web_environment
sudo echo CONCOURSE_EXTERNAL_URL=http://0.0.0.0:8080>>/etc/concourse/web_environment
#=======================================================================================
sudo echo CONCOURSE_WORK_DIR=/var/lib/concourse>/etc/concourse/worker_environment
sudo echo CONCOURSE_TSA_WORKER_PRIVATE_KEY=/etc/concourse/worker_key>>/etc/concourse/worker_environment
sudo echo CONCOURSE_TSA_PUBLIC_KEY=/etc/concourse/tsa_host_key.pub>>/etc/concourse/worker_environment
sudo echo CONCOURSE_TSA_HOST=127.0.0.1:2222>>/etc/concourse/worker_environment
sudo adduser --system --group concourse
sudo chmod 600 /etc/concourse/*_environment
#=========================================================================================
echo [Unit]>/etc/systemd/system/concourse-web.service
echo Description=Concourse CI web process ATC and TSA>>/etc/systemd/system/concourse-web.service
echo After=postgresql.service>>/etc/systemd/system/concourse-web.service
echo >>/etc/systemd/system/concourse-web.service
echo [Service]>>/etc/systemd/system/concourse-web.service
echo User=concourse>>/etc/systemd/system/concourse-web.service
echo Restart=on-failure>>/etc/systemd/system/concourse-web.service
echo EnvironmentFile=/etc/concourse/web_environment>>/etc/systemd/system/concourse-web.service
echo ExecStart=/usr/local/bin/concourse web>>/etc/systemd/system/concourse-web.service
echo >>/etc/systemd/system/concourse-web.service
echo [Install]>>/etc/systemd/system/concourse-web.service
echo WantedBy=multi-user.target>>/etc/systemd/system/concourse-web.service
#==========================================================================================
echo [Unit]>/etc/systemd/system/concourse-worker.service
echo Description=Concourse CI worker process>>/etc/systemd/system/concourse-worker.service
echo After=concourse-web.service>>/etc/systemd/system/concourse-worker.service
echo >>/etc/systemd/system/concourse-worker.service
echo [Service]>>/etc/systemd/system/concourse-worker.service
echo User=root>>/etc/systemd/system/concourse-worker.service
echo Restart=on-failure>>/etc/systemd/system/concourse-worker.service
echo EnvironmentFile=/etc/concourse/worker_environment>>/etc/systemd/system/concourse-worker.service
echo ExecStart=/usr/local/bin/concourse worker>>/etc/systemd/system/concourse-worker.service
echo >>/etc/systemd/system/concourse-worker.service
echo [Install]>>/etc/systemd/system/concourse-worker.service
echo WantedBy=multi-user.target>>/etc/systemd/system/concourse-worker.service
sudo systemctl enable concourse-web concourse-worker
sudo systemctl start concourse-web concourse-worker
#./concourse_linux_amd64 quickstart --basic-auth-username postgres --basic-auth-password postgres --external-url http://192.168.178.138 --worker-work-dir /opt/concourse/worker
