#!/bin/bash

# Update system
sudo apt update -y
sudo apt upgrade -y

# Install Java 17 (required by Jenkins)
sudo apt install -y openjdk-17-jdk

# Install Maven
sudo apt install -y maven

# Verify Maven installation
mvn -version

# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update -y
sudo apt install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Open Jenkins port (if UFW is enabled)
sudo ufw allow 8080 || true

# Print Jenkins status
sudo systemctl status jenkins --no-pager


