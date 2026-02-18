# linux-devops-toolkit

## Day 1: SSH and Linux Filesystem

- Connected to AWS EC2 Ubuntu server using SSH
- Explored filesystem structure
- Identified key directories:
    - /etc (configuration)
    - /var (logs and runtime data)
    - /home (user directories)
    - ls -la (everything in the folder including hidden files and permissinos)
    - cd / (puts you in the root and not"root user")
- Learned about hidden files and how to secure keys

## Day 2: Linux permissions and CHMOD

- Used chmod 400, 500, and 700 to change permissions on files
- 400 grants owner read only (safest, file can not be accidently over written)
- 600 grants owner read and write (common and secure default. Owner can edit key)
- 700 grants owner read, write, and execute (commonly used for directories)
- Implicit denial for everyone else above

## Day 3 – Running a Web Service

- Installed nginx web server on EC2
- Learned systemctl start/stop/restart/status/enable
- Fixed networking by allowing HTTP (port 80) in AWS security group
- Simulated outage and restored service
- Viewed live web traffic in /var/log/nginx/access.log

## Day 4 - Process and Logs
- Learned Linux filesystem structure. (/home, /etc, /var...)
- Utilized "tail -n, and tail -f" to view logs
- Used 'ps aux' and 'grep' to find running services. 
- monitored server activity using 'top' 

## Day 5 - Replace Nginx with custom page
- Used sudo nana /var/www/html/index.html to directly change the contents of the home page. 
- Reloaded page after changes instead of restart to mitigate possible interruption in runtime. 
- Fetched contentents of the page using curl command to confirm changes. 

# Day 6: Nginx virtial hosts
- Learned sites available vs sites enabled
- Created second site directory /var/www/day6
- Created site config
- Added another IPV4 address to server inbound rules. 
- Utilized nginx -t before reload to prevent downtime. 
# Day 7: Deploy Workflow + Permissions
-Built a simple deploy flow: edit source in ~/site-src/day6/index.html, deploy to /var/www/day6/index.html 
- Set ownership to www-data so nginx workers can read site files
- Set permissions to 755 (owner can write; others can read/enter)
- Added set -e to stop deploy on failure
- Verified default site vs day6 site using Host header
    - Default site: curl http://3.144.166.240
    - Day6 site: curl -H "Host: day6.local" http://3.144.166.240