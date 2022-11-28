# Generate SSH Key
# Example From  192.168.1.7 --> 192.168.1.13
# Login as oracle user to 192.168.1.7 
su - oracle
# Step 1. Generate SSH key at Source Client
ssh-keygen -t ecdsa
[enter]
[enter]	--> For no password
# Step 2: Upload SSH Key to – 192.168.1.13
ssh-copy-id oracle@192.168.1.13
ssh-copy-id -i ~/.ssh/id_ecdsa.pub oracle@192.168.1.13
# Step 3: Test
ssh oracle@192.168.1.13

# Step 4 Lists the files in your .ssh directory
cd ~/.ssh
ls -al
-rw-------   1 oracle oinstall  177 Feb 16  2022 authorized_keys
-rw-------   1 oracle oinstall  227 Mar 14  2022 id_ecdsa
-rw-r--r--   1 oracle oinstall  174 Mar 14  2022 id_ecdsa.pub
-rw-r--r--   1 oracle oinstall  347 Mar 18  2022 known_hosts
# Step 5 Usage of SSH Key Connection Examples
# a. Copy Directory to Remote Server Example
rsync -av -P /backup/EXP/ oracle@192.168.1.13:/backup/EXP/
scp /backup/EXP/database_*.dmp oracle@192.168.1.13:/backup/EXP/
# b. Remote Server Commnd Execute Example
ssh oracle@192.168.1.13 'bash -s < /home/oracle/import.sh'
# ---     Delete SSH Key     ---
# There are no common automatic methods to delete a public key, you must remove it manually.
vi ~/.ssh/authorized_keys
# Remove the line containing your key.
# Save and exit.