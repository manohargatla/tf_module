#!/bin/bash
sudo apt update
sudo apt install openjdk-17-jdk maven -y
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
# java package
mvn package
jar xvf target/spring-petclinic-3.0.0-SNAPSHOT.jar

