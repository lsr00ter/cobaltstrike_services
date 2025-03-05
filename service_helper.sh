#! /usr/bin/env bash
set -e

if ! command -v java &>/dev/null; then
    echo "[!] Java is not installed. Installing OpenJDK LTS version..."
    sudo apt update
    sudo apt install -y openjdk-17-jdk
else
    echo "[+] Java is already installed."
fi

write_teamserver_service() {
    IP_ADDRESSES=($(hostname -I))
    echo "[+] Available IP addresses:"
    for i in "${!IP_ADDRESSES[@]}"; do
        echo "$i: ${IP_ADDRESSES[$i]}"
    done
    read -p "[+] Choose an IP address (enter the number) for teamserver: " choice
    TEAMSERVER_IP=${IP_ADDRESSES[$choice]}
    read -sp "[+] Enter the password for the Teamserver: " PASSWORD
    echo
    PROFILES=(*.profile)
    echo "[+] Available .profile files:"
    for i in "${!PROFILES[@]}"; do
        echo "$i: ${PROFILES[$i]}"
    done
    read -p "[+] Choose a profile (enter the number): " profile_choice
    C2_PROFILE=${PROFILES[$profile_choice]}
    SCRIPT_PATH="$(dirname "$(realpath "$0")")"
    cat <<EOF >/tmp/teamserver.service
# teamserver.service
[Unit]
Description=Cobalt Strike Teamserver Service
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_PATH
ExecStart=$SCRIPT_PATH/teamserver $TEAMSERVER_IP $PASSWORD $C2_PROFILE

# Example
# ExecStart=/opt/cobaltstrike/teamserver $(hostname -I) thisismypassword /opt/cobaltstrike/c2.profile

[Install]
WantedBy=multi-user.target
EOF
}

write_teamserver_service
sudo mv /tmp/teamserver.service /etc/systemd/system/teamserver.service
sudo systemctl daemon-reload
sudo systemctl start teamserver.service
sudo systemctl enable teamserver.service
systemctl is-active --quiet teamserver.service && echo "[+] Teamserver service is running" || echo "[!] Teamserver service is not running"
