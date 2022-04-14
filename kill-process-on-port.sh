#!/bin/bash
PORT=$1
pid=$(sudo lsof -i :${PORT})
kill -9 pid