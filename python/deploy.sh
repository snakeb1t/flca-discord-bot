#!/bin/bash

source .venv/bin/activate
rm -rf ./dist/*
mkdir ./dist/python
pip install --platform manylinux2014_x86_64 --target ./dist/python --only-binary=:all: pynacl
pip install --target ./dist/python requests
mkdir ./dist/python/ships
cp ships.py ./dist/python/ships
touch ./dist/python/ships/__init__.py
