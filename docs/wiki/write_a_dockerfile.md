# Write a Dockerfile and an entrypoint.sh

This document gives a concise, practical guide to writing Dockerfiles with examples, best practices, and quick tips for building images efficiently and securely.

Official reference: https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/

## Quick reference

Common Dockerfile instructions and what they do:

- FROM: start a new build stage from a base image.
- RUN: execute commands during image build.
- COPY / ADD: copy files from the build context (prefer COPY).
- WORKDIR: change working directory for subsequent commands.
- ENV / ARG: set environment variables (ARG is build-only).
- USER: switch to a non-root user.
- EXPOSE: document which ports the container listens on.
- CMD / ENTRYPOINT: default executable and arguments when container starts.
- LABEL: add metadata to the image.
- VOLUME: declare mount points for external storage.
- HEALTHCHECK: allow Docker to check container health.

## Best practices

- Minimize image size: prefer smaller base images (e.g., `alpine`, `python:slim`), and use multi-stage builds for compiled artifacts.
- Reduce layers: combine related `RUN` commands using shell `&&` and clean package caches in the same layer.
- Use `.dockerignore` to avoid sending unnecessary files to the build context (node_modules, build artifacts, .git).
- Pin versions: install explicit package versions to avoid surprises.
- Drop root privileges: create and switch to a non-root user with `USER` when possible.
- Use `COPY` instead of `ADD` unless you need `ADD`'s tar/remote URL behavior.
- Keep secrets out of images: use build-time `ARG` only for non-sensitive values and runtime environment variables or secret managers for secrets.


## Examples (ROS 2 only)

### ROS 2 Humble (multi-stage) — build with `colcon` and run installed workspace

This example builds a ROS 2 workspace using `colcon` in a build stage and produces a small runtime image that only contains the installed artifacts.

```
# build stage
FROM ros:humble-ros-base AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
		apt-get install -y --no-install-recommends \
			build-essential \
			python3-colcon-common-extensions \
			python3-rosdep \
			python3-pip \
		&& rm -rf /var/lib/apt/lists/*

# initialize rosdep (may already be initialized in some base images)
RUN rosdep init || true
RUN rosdep update || true

WORKDIR /workspace
# copy only source to leverage build cache if other files change
COPY ./src ./src

# install package system deps and build
RUN rosdep install --from-paths src --ignore-src -r -y || true
RUN . /opt/ros/humble/setup.sh && colcon build --symlink-install --parallel-workers $(nproc)

# runtime stage
FROM ros:humble-ros-base
ENV ROS_DISTRO=humble
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 && rm -rf /var/lib/apt/lists/*

# copy installed workspace from build stage
COPY --from=build /workspace/install /workspace/install

SHELL ["/bin/bash", "-lc"]
ENV PATH=/workspace/install/bin:$PATH
ENV LD_LIBRARY_PATH=/workspace/install/lib:$LD_LIBRARY_PATH

# entrypoint that sources the ROS 2 and workspace environments
ENTRYPOINT ["/bin/bash","-lc","source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && exec \"$@\""]
CMD ["bash"]
```

## Entrypoint script (`entrypoint.sh`)

Using a small shell entrypoint script is a clean way to source ROS 2 and workspace environments, handle optional startup commands, and ensure proper signal forwarding.

Example `entrypoint.sh`:

```
#!/bin/bash
set -e
# source ROS 2 and the installed workspace if present
source /opt/ros/humble/setup.bash
[ -f /workspace/install/setup.bash ] && source /workspace/install/setup.bash

# if no args provided, fall back to an interactive shell
if [ "$#" -eq 0 ]; then
	exec bash
else
	# use exec so the container PID 1 receives signals
	exec "$@"
fi
```

Dockerfile snippet to install and use the script:

```
# copy entrypoint into image and make executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
```

Notes:

- Keep the script minimal and use `exec` to replace the shell with the target process so signals (SIGTERM/SIGINT) are forwarded properly.
- Avoid putting long, multi-step logic in the entrypoint; prefer small scripts and move complex setup into build-time steps when possible.
- Make sure `entrypoint.sh` is in `.dockerignore` during development if you generate it dynamically, or add it to the repo for reproducibility.

4) Small Node.js production image (use `.dockerignore` to exclude dev files)

```
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "server.js"]
```

## Build and run

- Build an image: `docker build -t myimage:latest .`
- Build with build args: `docker build --build-arg BUILDTIME_VAR=value -t myimage .`
- Run interactively: `docker run --rm -it -p 8080:8080 myimage:latest`
- Run in background: `docker run -d --name mysvc -p 80:80 myimage`

## Caching tips

- Order Dockerfile steps so that frequently-changing files are copied later. For example, copy only `requirements.txt` and install dependencies before copying application source — this keeps dependency layers cached.
- Keep package installation and cleanup in the same `RUN` to avoid leaving caches in previous layers.

## Security suggestions

- Do not bake credentials into images. Use runtime secrets, environment variables, or secret stores.
- Run as non-root: create a user and switch with `USER`.
- Scan images for vulnerabilities (e.g., `docker scan`, `trivy`).

## Additional resources

- Dockerfile reference: https://docs.docker.com/engine/reference/builder/
- Docker best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Use `.dockerignore` to reduce build context size: https://docs.docker.com/engine/reference/builder/#dockerignore-file

---

