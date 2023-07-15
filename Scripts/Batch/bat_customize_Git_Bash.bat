
:: Keep this for nice output
@echo off


:: Set source and destination folders
set src="C:\Users\David\GitHubRepos\LinuxFiles\Dotfiles\Actual\.bashrc"
set dest="C:\Users\%username%\"

:: Start message
echo.
echo "::::::::: Setting up .bashrc for Git Bash mintty terminal :::::::::"
echo.

:: Check paths
echo "Checking paths..."

:: Check source
if NOT exist %src% (
    echo "Source invalid"
    goto :end
)

:: Check dest
if NOT exist %dest% (
    echo "Dest invalid"
    goto :end
)


:: Special file paths in User folder
set brc="%dest%.bashrc"
set bprof="%dest%.bash_profile"


:: Remove previous files (if they exist)
echo "Removing previous files..."
if exist %brc% (
    :: AH for hidden files
    del /AH %brc%
)
if exist %bprof% (
    :: AH for hidden files
    del /AH %bprof%
)
echo.


:: Copy brc
echo "Copying bashrc from LinuxFiles repo to User folder..."
copy %src% %dest%
echo.


:: Rename
echo "Renaming..."
rename %brc% ".bash_profile"
echo.


:: Edit step
echo "You can add this to the top of the file:"
echo "  # COPY OF .BASHRC FOR GIT MINTTY BASH"
start "" %bprof%
echo.


:: End label (for goto)
:end

:: Finish message
echo "Finished!"
echo.

:: Hang
@pause