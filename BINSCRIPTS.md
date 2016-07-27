# util

This repository is intended to be downloaded into a container repository during development for convenience purposes.  Since the major mechanisms of developing to the Docker container construction lifecycle are identical across container images, this repository allows for consistency and additional ease of use across all container images.

## Install

To use these scripts on your container image construction project, issue these commands in the root directory of your container project:

```
```

### common.bash

The installation process will create a common.bash file.  This file should be the central, canonical authority for management of environment variables.  While a subprocess may override them, the files in common.bash should be treated as authoritative defaults.  Processes (e.g. `docker build`, `bats`, inside `Jenkinsfile`) can read this file and process the results therein.

You should edit this file to change the image name, and add any other helpful environment variables.

## Use


### Building

#### build.sh
`bin/build `
#### destroy.sh
#### rebuild.sh

### Running
### rerun.sh
### run.sh


### Testing
#### test.sh