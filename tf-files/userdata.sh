# Updates the operating system [İşletim sistemini günceller]
dnf update -y

# Installs pip (Python package manager) [pip (Python paket yöneticisi) kurar]
dnf install pip -y

# Installs a specific version of Flask (2.3.3) [Belirli bir sürüm olan Flask 2.3.3'ü kurar]
pip3 install flask==2.3.3

# Installs Flask MySQL support [Flask için MySQL desteğini kurar]
pip3 install flask_mysql

# Installs Git version control system [Git versiyon kontrol sistemini kurar]
dnf install git -y

# Assigns the user-provided Git token and username to variables [Kullanıcıdan alınan git token ve kullanıcı adını değişkenlere atar]
TOKEN=${user-data-git-token}
USER=${user-data-git-name}

# Changes to the ec2-user's home directory and clones the specified repository [EC2 kullanıcısının ev dizinine gider ve belirtilen depoyu klonlar]
cd /home/ec2-user && git clone https://$TOKEN@github.com/$USER/phonebook.git

# Sets the database endpoint as an environment variable [Veritabanı bağlantı noktasını bir ortam değişkenine atar]
export MYSQL_DATABASE_HOST=${db-endpoint} 

# Runs the Phonebook application [Phonebook uygulamasını çalıştırır]
python3 /home/ec2-user/phonebook/phonebook-app.py