
# Welcome to Soundscape!

Welcome to the Soundscape setup!
![SmallLogo]

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#step-1">Step 1</a></li>
    <li><a href="#step-2">Step 2</a> </li>
    <li><a href="#step-3">Step 3</a></li>
    <li><a href="#step-4">Step 4</a></li>
    <li><a href="#step-5">Step 5</a></li>
    <li><a href="#step-6">Step 6</a></li>
    <li><a href="#step-7"> Step 7</a> </li>
    <li><a href="#step-8">Step 8</a></li>
    <li><a href="#step-9">Step 9</a></li>
    <li><a href="#step-10">Step 10 </a></li>
    <li><a href="#step-11">Step 11</a></li>
    <li><a href="#step-12">Step 12</a> </li>
  </ol>
</details>


## Step 1 Have XCode
An unfortunate requirement to code in Swift (the main language of SoundScape) is that it requires XCode, which requires a Mac.
## Step 2 Get Homebrew
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

Run these three commands: ( AS PROMPTED)

`echo '# Set PATH, MANPATH, etc., for Homebrew.' >>` `/Users/username/.zprofile`

`echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ``/Users/username/.zprofile`

`eval "$(/opt/homebrew/bin/brew shellenv)"`

`brew install rbenv ruby-build`
`rbenv init`
`vim .zshrc`
`:i`
`export PATH=”$HOME/.rvm/bin:$PATH”`
`eval “$(/usr/local/bin/rbenv init -zsh)”`
`escape`
`:wq`
## Step 3 check RVM
if not installed 
`\curl -sSL https://get.rvm.io/ | bash -s stable` 
## Step 4 get Cocoapods
`brew install cocoapods`
## Step 5 Create a Dev Folder
`mkdir ~/Developer`
## Step 6 Get the Git Repository
While in cd Developer
`git clone https://github.com/bnavac/soundscape.git`
## Step 7 Change your bash profile
Run these in order:
`Cd`
`ls -a`
`vim .bashrc`
(press i on keyboard then hit return)
`Paste : eval "$(rbenv init - bash)"`
Hit esc, then shift colon
wq (then hit return)

Should look something like this
![step_7]
## Step 8 Ensure you have the right Ruby
Run:
`rbenv install 3.2.0`
`rbenv global 3.2.0`
Check that it is in the right directory, if you run:
`Which ruby`
Should be under rbenv
## Step 9 Get the rest of the dependencies
Then go into soundscape ios directory:
`Cd Developer/soundscape/apps/ios`
Get Bundle and Cocoapods patch

Run:
`bundle install`
`gem install cocoapods-patch`
`Pod install`

If you run into errors on this step, say your prayers and check which directories your ruby is under and what version it is, run sudo if you don’t have write permission
`Which ruby`
  
Ruby --version
Should look something like:
![step_9]
## Step 10 Open Project
  Cd Developer/soundscape/apps/ios`
open GuideDogs.xcworkspace
## Step 11 Correct Settings
Once xcode is open, click on guidedogs, in the targets tab click Soundscape, go to signing and capabilities

Turn on Automatically manage signing

For team choose (Personal Team)

Set the bundle identifier to soundscape.(yourname).io
## Step 12 Done!
You now should be able to run SoundScape on a virtual iPhone 14 in XCode!

![Logo]

[step_7]:images\s7.png
[step_9]:images\s9.png
[Logo]:images\SoundScape.png
[SmallLogo]:images\SoundScapeSmall.png

