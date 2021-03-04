#!/bin/bash
set -e
export BIN=$PREFIX/bin
export TMPDIR=$PREFIX/tmp

clear
echo
echo
echo
echo "======= TERMUX METASPLOIT 2021 ======="
echo "Created by Ferdian™"
echo
sleep 1
echo "Checking Package..."
pkg install -y ncurses-utils wget &>/dev/null
tput cuu1
tput el
sleep 1
printf " Starting...  "
for load in $(seq 1 15); do
for X in '-' '\' '|' '/'; do echo -en "\b$X"; sleep 0.01; done; done;
tput cuu1

echo

if [ "$(id -u)" = "0" ]; then
	echo "[!] Sorry but I won't let you to install this package as root."
	exit 1
fi

echo "[*] Checking Version of Metasploit..."
MS=$(curl -L -s "https://github.com/rapid7/metasploit-framework/releases" | grep releases/tag | head -1 | cut -b 58-63)
#cp /sdcard/metasploit-framework-6.0.32.tar.gz $HOME/metasploit2021/$MS.tar.gz
if [[ -e $MS.tar.gz ]]; then
sleep 1
echo "Metasploit v.$MS Found in this Phone"
sleep 1
else
echo "[*] Found Latest Version Metasplot v. $MS"
sleep 1
echo "[*] Downloading Metasploit..."
wget https://github.com/rapid7/metasploit-framework/archive/$MS.tar.gz &>/dev/null & PID=$!
while kill -0 $PID 2>/dev/null; do 
    printf  "▓"
    sleep 2
done
echo
echo
fi
echo "Moving Metasploit to Folder tmp..."
cp $MS.tar.gz $TMPDIR
chmod +x $TMPDIR/$MS.tar.gz
echo "Done.."
sleep 1
tput cup 6 0
tput ed
echo "         Running Script Installer..."
sleep 1
echo
echo "[*] Checking Ruby version.."
rubver=$(ruby -v  | grep 'ruby ' | cut -d' ' -f2 | cut -b -5) &> /dev/null
sleep 1
if [[ $rubver = 2.7.2 ]]; then
echo "Ruby 2.7 was Installed.."
sleep 1
elif [[ $rubver = 3.0.0 ]]; then
echo "Need Ruby Version 2.7.2..."
sleep 1
echo "Your version Ruby is $rubver"
sleep 1
echo "Removing Ruby..."
sleep 2
apt remove ruby -y &>/dev/null
apt autoremove -y &>/dev/null
rm -rf $PREFIX/lib/ruby/gems/$rubver
echo "Installing Ruby Version 2.7..."
bash <(curl -fsSL "https://git.io/abhacker-repo") --install ruby=2.7.2 &>/dev/null
else
echo "Ruby not Found!"
echo "Installing Ruby Version 2.7..."
bash <(curl -fsSL "https://git.io/abhacker-repo") --install ruby=2.7.2 &>/dev/null
fi
echo
echo "[*] Checking postgres..."
sleep 1
if [[ -e $BIN/postgres ]]; then
echo "Postgres Found..."
else
echo "Installing Postgres..."
pkg install postgres &>/dev/null
fi
sleep 1
echo "Removing Folder postgresql..."
rm -rf "$PREFIX"/var/lib/postgresql
echo "Removing previous Metasploit..."
rm -rf "$PREFIX"/opt/metasploit-framework
echo
echo "[*] Checking gem pg for version 0.20.0..."
if [ "$(gem list -i pg -v 0.20.0)" = "false" ]; then
echo "Adding gem pg version 0.20.0..."
gem install pg -v 0.20.0 &>/dev/null
else
echo "gem pg v. 0.20.0 found"
fi
tput cup 7 0
tput ed
echo
echo "[*] Extracting new version of Metasploit Framework..."
mkdir -p "$PREFIX"/opt/metasploit-framework
tar zxf "$TMPDIR/$MS.tar.gz" --strip-components=1 \
	-C "$PREFIX"/opt/metasploit-framework
echo
echo "Installing 'rubygems-update' if necessary..."
if [ "$(gem list -i rubygems-update 2>/dev/null)" = "false" ]; then
	gem install --no-document --verbose rubygems-update &>/dev/null
fi

echo "Updating Ruby gems..."
update_rubygems &>/dev/null

echo "Installing 'bundler:1.17.3'..."
gem install --no-document --verbose bundler:1.17.3 &>/dev/null

echo
echo "[*] Installing Metasploit dependencies."
echo "(may take long time)..."
cd "$PREFIX"/opt/metasploit-framework
bundle config build.nokogiri --use-system-libraries
bundle install --jobs=2 --verbose &>/dev/null

tput cup 7 0
tput ed
echo "Running fixes..."
sed -i "s@/etc/resolv.conf@$PREFIX/etc/resolv.conf@g" "$PREFIX"/opt/metasploit-framework/lib/net/dns/resolver.rb
find "$PREFIX"/opt/metasploit-framework -type f -executable -print0 | xargs -0 -r termux-fix-shebang
find "$PREFIX"/lib/ruby/gems -type f -iname \*.so -print0 | xargs -0 -r termux-elf-cleaner

echo "Setting up PostgreSQL database..."
echo
echo
mkdir -p "$PREFIX"/opt/metasploit-framework/config
cat <<- EOF > "$PREFIX"/opt/metasploit-framework/config/database.yml
production:
  adapter: postgresql
  database: msf_database
  username: msf
  password:
  host: 127.0.0.1
  port: 5432
  pool: 75
  timeout: 5
EOF
mkdir -p "$PREFIX"/var/lib/postgresql
pg_ctl -D "$PREFIX"/var/lib/postgresql stop > /dev/null 2>&1 || true
if ! pg_ctl -D "$PREFIX"/var/lib/postgresql start --silent; then
    initdb "$PREFIX"/var/lib/postgresql
    pg_ctl -D "$PREFIX"/var/lib/postgresql start --silent
fi
if [ -z "$(psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='msf'")" ]; then
    createuser msf
fi
if [ -z "$(psql -l | grep msf_database)" ]; then
    createdb msf_database
fi

if [ -e $BIN/msfconsole ];then
	rm $BIN/msfconsole
fi
if [ -e $BIN/msfvenom ];then
	rm $BIN/msfvenom
fi
ln -s $PREFIX/opt/metasploit-framework/msfconsole $BIN
ln -s $PREFIX/opt/metasploit-framework/msfvenom $BIN
echo
echo "[*] Everything Done."
echo "[*] Metasploit Framework installation Finished."
echo "[*] ...Script by Ferdian™..."
echo "Running msfconsole now.."

msfconsole
