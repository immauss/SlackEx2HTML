## SlackEx2HTML ##
This does exactly what the name implies: It converst a Slack export to a series of html files so you can search/browse through you full history from Slack. 
## Usage ##
Edit the varibles to suit your system
### Things for the user to configure.
DEBUG="0"
### Where you unzipped the archive from Slack
SRCDIR="/home/me/Downloads/SlackHistory"
### where to put the output
DSTDIR="/home/me/SlackHistory"
### RELDIR is the directory on the server where you are storing the files as seen from the web.
RELDIR="/resources/Site/SlackHistory"
### Main site home page
HOME="https://companyhomepage.com"
### Name of Organization for Title pages
ORGNAME="Your Org Name"
## Run the script.
```
./slackex2html.sh
```

Be Happy
:)
