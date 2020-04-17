#! /bin/bash

rm -rf install > /dev/null
mkdir install && cd install
wget https://github.com/cuelang/cue/releases/download/v0.1.1/cue_0.1.1_Linux_x86_64.tar.gz
tar zxvf cue_0.1.1_Linux_x86_64.tar.gz
rm cue_0.1.1_Linux_x86_64.tar.gz
cp cue $HOME/bin
rm cue