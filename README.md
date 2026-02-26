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

## Day 6: Nginx virtial hosts
- Learned sites available vs sites enabled
- Created second site directory /var/www/day6
- Created site config
- Added another IPV4 address to server inbound rules. 
- Utilized nginx -t before reload to prevent downtime. 

## Day 7: Deploy Workflow + Permissions
- Built a simple deploy flow: edit source in ~/site-src/day6/index.html, deploy to /var/www/day6/index.html 
- Set ownership to www-data so nginx workers can read site files
- Set permissions to 755 (owner can write; others can read/enter)
- Added set -e to stop deploy on failure
- Verified default site vs day6 site using Host header
    - Default site: curl http://3.144.166.240
    - Day6 site: curl -H "Host: day6.local" http://3.144.166.240
## Day 8 — Security groups + SSH lockdown mindset (recap)
- Locked down EC2 SSH inbound rule to my public IP only instead of 0.0.0.0/0
- Left HTTP (port 80) open when needed so anyone can view the website, while SSH remains restricted
- Confirmed: restricting SSH reduces attack surface; web traffic can be public while admin access stays private
- Day 9 — Processes + logs + filesystem structure
- Used ps aux | grep nginx to inspect running processes (nginx master + worker processes)
- Used top to observe CPU/memory and process activity
- Practiced service management with systemctl (start/stop/restart/reload)
-  Worked with logs:
    - tail -n 20 /var/log/nginx/error.log (last N lines)
    - learned common typos (e.g., nging vs nginx)
    - understood -n = number of lines, -f = follow/stream logs live
    - Clarified filesystem purpose:
    - /var holds variable data (logs, cache, spool) that changes over time
    - /etc holds configuration
    - /home user directories

## Day 10 — Docker fundamentals: images vs containers (custom nginx site)
- Built a custom Docker image from nginx:alpine and deployed a custom index.html
- Key idea: image = immutable artifact, container = running instance of that artifact
- Learned: rebuilding an image is required for changes to be reflected in new containers (immutable pattern)

Dockerfile used:

FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html

## Day 11 — Containers are ephemeral (restart vs recreate)
- Learned why docker exec ... bash failed: base image is Alpine → no bash; use sh
- Learned difference:
- docker restart <container> restarts same container (keeps writable layer)
- docker rm -f <container> then docker run ... creates a new container from the image (edits inside old container are lost)

## Day 12 — Docker volumes + persistence
- Implemented persistent storage using a volume / host mount so data survives container deletion
- Key concept: containers are disposable; data must be durable
- Confirmed: volume survives docker rm, but data is lost if the volume is deleted

## Day 13 — Docker Compose + MySQL persistence + secrets
- Created a multi-service Docker Compose app: nginx + mysql
- Learned service discovery: containers communicate by service name (e.g., db)
- Added named volume to persist database data across container recreation
- Moved secrets into .env and added .env to .gitignore to prevent committing secrets
- Verified persistence by creating a table + row, running docker compose down + up, and confirming the row still exists

Day 14 — EC2 as a Docker Host
Objective

Turn the AWS EC2 instance into a machine capable of running containers instead of manually installed services.

Key Concepts

A server should run containers, not manually configured software.

The host OS becomes a runtime platform, not the application itself.

Docker daemon runs as root and communicates via:

/var/run/docker.sock
Problem Encountered

Running:

docker ps

returned:

permission denied while trying to connect to the Docker daemon socket
Root Cause

The ubuntu user was not in the docker group, and the socket is owned by root.

Fix
sudo usermod -aG docker ubuntu
exit
ssh back in
groups

After reconnect:

docker ps

worked without sudo.

Lesson

Docker permissions are Unix socket permissions.
You are not granting Docker rights — you are granting control over the Docker daemon.

Day 15 — First Remote Container Deployment
Objective

Run a Docker container on the EC2 server and expose it publicly.

Steps:

Build image locally

Push to Docker Hub

Pull on EC2

Run container on port 80

docker pull fluffydabs/yoseph-site:v1
docker run -d --name yoseph-site -p 80:80 fluffydabs/yoseph-site:v1
Problem

Port 80 was already in use.

sudo ss -lntp | grep :80

Result:
nginx was occupying port 80.

Fix
sudo systemctl stop nginx
sudo systemctl disable nginx

Then:

docker run -d -p 80:80 fluffydabs/yoseph-site:v1
Verification
curl http://localhost
curl http://<public-ip>
Lesson

Containers must own the port — you cannot have two services bound to the same port.

Day 16 — Multi-Architecture Docker Images
Problem

EC2 failed to pull image:

no matching manifest for linux/amd64
Root Cause

MacBook builds ARM images (Apple Silicon).
EC2 requires AMD64.

Solution

Use Docker Buildx:

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t fluffydabs/yoseph-site:v1 \
  --push .
Lesson

A Docker image is architecture-specific.
Production servers almost always use linux/amd64.

Day 17 — Automating Remote Deployment

Manual SSH deployments are not scalable.

Created script:

deploy/remote-deploy.sh

The script:

SSHs into EC2

pulls image

replaces container

verifies service

Key concept:
Infrastructure should be reproducible, not manual.

Day 18 — Immutable Releases (Versioned Tags)
Problem

Deploying latest caused confusion.

Solution

Use versioned tags:

v1
v2
v3

Deploying a specific version:

./deploy/remote-deploy.sh v3
Lesson

Never deploy “latest” in production.
You must know exactly what is running.

Day 19 — Git Commit Based Releases

Improved versioning:

sha-<git_commit>

Build:

COMMIT=$(git rev-parse --short HEAD)
docker buildx build -t fluffydabs/yoseph-site:sha-$COMMIT --push .

Deploy:

./deploy/remote-deploy.sh sha-$COMMIT

Verification:

docker inspect yoseph-site
Lesson

A production system should be traceable to a specific commit.

Day 20 — Image Metadata (OCI Labels)

Added Dockerfile labels:

LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.revision=$VCS_REF

Verification:

docker inspect yoseph-site
What This Enables

You can now answer:

What exact code is running in production?

Without checking GitHub.

Day 21 — Health-Gated Deployments

Previous deploy:

stopped container

started new one

This created downtime if the new image failed.

New Process

Start new container on port 8080

Health check

If healthy → replace production

If unhealthy → abort

Result:
Broken deploys no longer take down the site.

Lesson

A deployment is not complete when the container starts.
It is complete when the service responds correctly.

Day 22 — SSH Reliability & Operational Stability

Problem:
SSH sessions randomly dropped during deploys.

Solution:
~/.ssh/config

ServerAliveInterval 20
ServerAliveCountMax 6
Lesson

Operations tooling must be reliable.
Automation must tolerate network interruptions.

Day 23 — Reverse Proxy Introduction (Traefik)

Before:

Internet → container

After:

Internet → Traefik → container

Traefik owns port 80.

Benefits:

no port conflicts

stable entrypoint

multiple services possible

real production architecture

Day 24 — Container Service Routing

Traefik uses Docker labels to route traffic:

traefik.enable=true
traefik.http.routers.yoseph.rule=PathPrefix(`/`)
traefik.http.services.yoseph.loadbalancer.server.port=80

Traefik discovered container automatically via Docker socket.

Verified:

curl http://localhost

returned the website.

Major Architectural Change

The application no longer exposes a port to the internet.

It is now:
an internal service behind an ingress controller.