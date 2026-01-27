#!/bin/bash

sleep 2  
hyprctl dispatch workspace 3
killall -SIGUSR2 waybar
