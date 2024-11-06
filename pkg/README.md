# LibreTax Environment
## Custom Packages
### Description
This directory will hold all files that are used to create RPM's that will be installed to each of the systems. Each package should follow the following convention.
```shell
lt_pkg # Root directory of package, should have lt_ prefix with a short name suffix denoting what it performs
│   # (e.g. lt_env = environment file).
├── README.md # Describe the package and its' usage.
├── SOURCE # Directory with all scripts, config files, etc. needed for the package.
│   └── script.sh # Example script.
└── SPECS # Holds the spec file that defines the package.
    └── lt_pkg.spec # Defines the package with metadata, installation directory, and source files.
```

### Creating/Editing Packages
When you add or change a package make sure you adhere to the directory convention above. The below steps are
#### Package Creation
1. Create the package dir `mkdir -p lt_pkg/{SOURCE,SPEC}`
2. Add the scripts to the source dir.
3. Create the spec file with proper convention (refer to existing spec files for guidance).
4. Create a README with a description and usage.
5. Add the package to the proper kickstart.

#### Package Editing
1. Make the desired source changes.
2. If you added files, edit the spec file to include the new source files.
3. Update the README description and usage.

### Packages
* [Environment](./lt_env/README.md)
