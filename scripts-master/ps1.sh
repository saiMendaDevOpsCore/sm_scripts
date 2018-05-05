#!/bin/bash

if [ `id -u` = 0 ]; then 
  export PS1='\[\e[1;31m\][\u@\h \W]# \[\e[0m\]'
else
  export PS1='\[\e[1;31m\][\u@\h \W]$ \[\e[0m\]'
fi
