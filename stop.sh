#!/bin/bash
if  ps aux| grep -v grep | grep "go_simple_serve" ;then
	ps aux|grep "go_simple_serve"|grep -v grep|awk '{print $2}'|xargs kill
fi

