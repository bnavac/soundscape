# Contributing

This project welcomes contributions and suggestions. Most contributions require you to
agree to a Contributor License Agreement (CLA) declaring that you have the right to,
and actually do, grant us the rights to use your contribution. For details, visit
https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need
to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the
instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.


Contributing Steps: 

RCOS (Extremely Tentative) Download Setup:
Step 1:
Have xcode lol 

Step 2: get rbenv (through homebrew)

Get Homebrew

Either run  
:/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Or get the equivalent from 
https://brew.sh/
Run these three commands: ( AS PROMPTED)
echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/username/.zprofile
 echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/username/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
    Then get rbenv

brew install rbenv ruby-build

rbenv init
vim .zshrc
i
export PATH=”$HOME/.rvm/bin:$PAT”
eval “$(/usr/local/bin/rbenv init -zsh)”
escape
:wq
Step 3: Check if you have RVM

If no then:
https://github.com/rvm/rvm
Or 
\curl -sSL https://get.rvm.io/ | bash -s stable

Once downloaded: should be prompted to: soruce /Users/username/.rvm/scripts/rvm

Make sure to do this 

Step 4: get Cocoapods
a

Step 5: Create Developer Folder on mac 
    mkdir ~/Developer

Step 6: Actually get the Git Repository
    PLEASE DO THIS WHILE IN CD DEVELOPER
Type pwd to check the path, if you’re not in the developer folder, type “cd” and then “cd Developer”.
    Command line clone it (i forgot how to do this, attend the workshop on tuesday :D)
    
     Nevermind : git clone https://github.com/bnavac/soundscape.git    
     Check it worked with “ls” while in the developer directory (cd developer)

Step 6.5: Optional (other commands will reference this, but you don't need it)
    To save time get: 
brew install tree

Once tree is installed 

Step 7: Change your bash profile 
Run these in order: 
Cd 
ls -a 
vim .bashrc
(press i on keyboard then hit return)
Paste : eval "$(rbenv init - bash)"
Hit esc, then shift colon 
wq (then hit return)
    
Should look something like this 


    Once exited out 
source .bashrc (Very important, should give this if completed)
/opt/homebrew/Cellar/rbenv/1.2.0/libexec/../completions/rbenv.bash:16: command not found: complete

Step 8: Make sure you have the correct ruby 
Run:
rbenv install 3.2.0
rbenv global 3.2.0
Check that it is in the right directory, if you run:

Which ruby 
    
Should be under rbenv

Step 9: Get the rest of the programs 

Then go into soundscape ios directory:
Cd Developer/soundscape/apps/ios 
    Get Bundle and Cocoapods patch 
Run: 
bundle install
gem install cocoapods-patch
Pod install 

If you run into errors on this step, say ur prayers and check which directories your ruby    
Is under and what version it is, run sudo if don’t have write permission
Which ruby 

Ruby –version (thats a double dash) 

    Should looked something like:


Step 10: Open the project!!! 

(unnecessary if ur already here) Cd Developer/soundscape/apps/ios
open GuideDogs.xcworkspace

Step 11: 

Once xcode is open, click on guidedogs, in the targets tab click Soundscape, go to signing and capabilities
Turn on Automatically manage signing 
For team choose (Personal Team)
Set the bundle identifier to soundscape.(urname).io

Step 12: Run to virtual iPhone 14 


