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

-Used chmod 400, 500, and 700 to change permissions on files
    - 400 grants owner read only (safest, file can not be accidently over written)
    - 600 grants owner read and write (common and secure default. Owner can edit key)
    - 700 grants owner read, write, and execute (commonly used for directories)
    - Implicit denial for everyone else above
    
