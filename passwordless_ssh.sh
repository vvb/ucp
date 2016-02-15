#!/bin/bash
ssh-keygen -t rsa
ssh vagrant@192.168.2.10 mkdir -p .ssh
ssh vagrant@192.168.2.11 mkdir -p .ssh
cat ~/.ssh/id_rsa.pub | ssh vagrant@192.168.2.10 'cat >> .ssh/authorized_keys'
cat ~/.ssh/id_rsa.pub | ssh vagrant@192.168.2.11 'cat >> .ssh/authorized_keys'

ssh vagrant@192.168.2.80 'ls'
ssh vagrant@192.168.2.81 'ls'
