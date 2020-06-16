# Bamboo configurator for automatic deployment and registration of Bamboo agents

This script assumes that you have JAVA installed and accessible via the PATH. The capabilities.prop file contains instructions for the CI/CD server to locate and configure capabilities automatically, allowing for truly ephemeral agents which can be redeployed seamlessly. There are instructions to create one of these files here: https://confluence.atlassian.com/bamkb/list-of-default-keys-for-the-bamboo-capabilities-properties-file-946025256.html

The $bbagent variable is to be set to the location of the server's remote agent repository, and the $service account variable is to be set for the domain service account that is being used. 

#ADD-IN AGENT SERVER is to be replaced with the URL of the Bamboo servers web address. 
