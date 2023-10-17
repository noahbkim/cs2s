# This file is copied to /root/ by the Dockerfile

# Change shell to ignore hostname
export PS1="\u@docker:\w$ "

# Go to work directory
if [[ -s /work ]]
then
    cd /work
fi
