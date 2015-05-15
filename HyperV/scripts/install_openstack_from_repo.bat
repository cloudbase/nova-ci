@echo off
set PROJ=%1
C:\OpenStack\virtualenv\Scripts\activate.bat && cd %PROJ% && python setup.py install
