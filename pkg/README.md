# LibreTax Environment
## Custom Packages
### Description
This directory will hold all files that are used to create RPM's that will be installed to each of the systems. Each package should follow the following convention.
```shell
lt_pkg # Root directory of package, should have lt_ prefix with a short name suffix denoting what it performs (e.g. lt_env = environment file).
├── README.md # Describe the package and its' usage.
├── SOURCE # Directory with all scripts, config files, etc. needed for the package.
│   └── script.sh # Example script.
└── SPECS # Holds the spec file that defines the package.
    └── lt_pkg.spec # Defines the package with metadata, installation directory, and source files.
```
### Packages
