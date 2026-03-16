# Use an official Ubuntu base image
FROM ubuntu:latest

# Install ngrep and other dependencies (bash is included in most standard Linux images like Ubuntu)
RUN apt-get update && apt-get install -y ngrep iproute2 && apt-get install -y inetutils-ping

# Set the default command to run a bash shell
CMD ["/bin/bash"]