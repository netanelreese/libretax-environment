# LibreTax Environment
## lt.env
The lt.env file is essentially a bash script that contains all global variables relevant to the whole system. It will be used in all install scripts to provide better readability and less overhead if variables need to be changed. All scripts should source this file.
```{shell}
source /etc/libretax/env/lt.env
```
