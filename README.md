# Overview

This repository contains useful cmake scripts.

## vcpkg-utils.cmake

This file contains utility wrapper functions of vcpkg.

`find_vcpkg()` tries to find the vcpkg executable on the system `PATH`, and set the cache variable `VCPKG_FOUND` to `true` if it is found, and set the `CMAKE_TOOLCHAIN_FILE` to the corresponding `vcpkg.cmake`.

Examples:

```cmake
cmake_minimum_required(VERSION 3.20)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

include(vcpkg-utils)

find_vcpkg()
```

`init_vcpkg_as_dep()` fetches the official `vcpkg` repository as a cmake submodule. It needs a parameter specifying the tag of `vcpkg` to be used.

Example: try to find vcpkg on system first, if not found, fetch vcpkg as a submodule

```cmake
find_vcpkg()

if(NOT VCPKG_FOUND)
    init_vcpkg_as_dep(TAG 2023.08.09)
endif(NOT VCPKG_FOUND)
```

`vcpkg_create_manifest()` creates a vcpkg manifest file in the specified directory.

Exmaple: 

```cmake
vcpkg_create_manifest(
    NAME "dummy"                                              # Name of your project
    VERSION 1.0.0                                             # Version of your project
    DIR ${CMAKE_CURRENT_LIST_DIR}                             # Directory in which to create the manifest file
    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/vcpkg_installed)  # Where packages will be installed
```

`vcpkg_add()` adds specified package to the created manifest file.

Example:

```cmake
vcpkg_add(NAME opencv) # adds opencv package as a dependency in vcpkg.json
```

`vcpkg_install()` Installs all the dependencies specified in the manifest file. A triplet needs to be provided. This is not necessary if `CMAKE_TOOLCHAIN_FILE` is already set to `vcpkg.cmake`, as CMake would automatically trigger the installation process.

Example:

```cmake
vcpkg_install(TRIPLET x64-windows-static-md)
```

After all packages are built and installed, a binary SDK can be created using the `vcpkg export` command, which will create a zip package.

To use the exported dependencies without rebuilding them again, use the `vcpkg_import_sdk()` function:

```cmake
vcpkg_import_sdk(
NAME my_sdk
URL <url_to_zip>
HASH <hash_of_the_zip>
)
```
