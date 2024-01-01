:: Intended for usage with folders holding media, to save the original file names

@echo off
for %%F in (*) do echo %%~nxF >> INFO.txt
