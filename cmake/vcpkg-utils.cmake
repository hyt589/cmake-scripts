include(FetchContent)

function(find_vcpkg)
    if(VCPKG_FOUND)
        message(STATUS "vcpkg is already found")
        set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "tool chain file" FORCE)
        return()
    endif(VCPKG_FOUND)

    message(STATUS "Looking for vcpkg in PATH")
    find_program(VCPKG_PATH vcpkg)
    if("${VCPKG_PATH}" STREQUAL "VCPKG_PATH-NOTFOUND")
        message(STATUS "Vcpkg is not found in path")
        set(VCPKG_FOUND false CACHE BOOL "whether vcpkg is found" FORCE)
    else()
        message(STATUS "VCPKG_PATH: ${VCPKG_PATH}")
        set(VCPKG_FOUND true CACHE BOOL "whether vcpkg is found" FORCE)
        get_filename_component(VCPKG_DIR ${VCPKG_PATH} DIRECTORY)
        set(VCPKG_ROOT_DIR ${VCPKG_DIR} CACHE STRING "vcpkg root" FORCE)
        set(CMAKE_TOOLCHAIN_FILE "${VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "tool chain file" FORCE)
    endif("${VCPKG_PATH}" STREQUAL "VCPKG_PATH-NOTFOUND")
endfunction(find_vcpkg)

function(init_vcpkg_as_dep)
    set(options)
    set(oneValueArgs TAG)
    set(multiValueArgs)
    cmake_parse_arguments("INIT" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    message(STATUS "INIT_TAG: ${INIT_TAG}")

    FetchContent_Declare(
        vcpkg
        GIT_REPOSITORY "https://github.com/microsoft/vcpkg.git"
        GIT_TAG "${INIT_TAG}"
    )

    message(STATUS "Fetching vcpkg as cmake submodule from https://github.com/microsoft/vcpkg.git")
    FetchContent_MakeAvailable(vcpkg)
    message(STATUS "Vcpkg ${INIT_TAG} fetched")

    FetchContent_GetProperties(
        "vcpkg"
        SOURCE_DIR vcpkg_SOURCE_DIR
    )

    # bootstrap vcpkg
    if(WIN32)
        if(NOT EXISTS "${vcpkg_SOURCE_DIR}/vcpkg.exe")
            execute_process(COMMAND cmd /c "${vcpkg_SOURCE_DIR}/bootstrap-vcpkg.bat"
                COMMAND_ERROR_IS_FATAL ANY)
        endif(NOT EXISTS "${vcpkg_SOURCE_DIR}/vcpkg.exe")
        set(VCPKG_PATH "${vcpkg_SOURCE_DIR}/vcpkg.exe" CACHE STRING "vcpkg path" FORCE)
    else()
        if(NOT EXISTS "${vcpkg_SOURCE_DIR}/vcpkg")
            execute_process(COMMAND sh "${vcpkg_SOURCE_DIR}/bootstrap-vcpkg.sh"
                COMMAND_ERROR_IS_FATAL ANY)
        endif(NOT EXISTS "${vcpkg_SOURCE_DIR}/vcpkg")
        set(VCPKG_PATH "${vcpkg_SOURCE_DIR}/vcpkg" CACHE STRING "vcpkg path" FORCE)
    endif()
    
    set(VCPKG_FOUND true CACHE BOOL "whether vcpkg is found" FORCE)
    set(CMAKE_TOOLCHAIN_FILE "${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "tool chain file" FORCE)
    message(STATUS "CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")

endfunction(init_vcpkg_as_dep)

function(vcpkg_create_manifest)
    if(NOT VCPKG_FOUND)
        message(FATAL_ERROR "ERROR: vcpkg is not found")
        return()
    endif(NOT VCPKG_FOUND)

    if(VCPKG_MANIFEST_CREATED)
        message(STATUS "Found existing vcpkg manifest")
        return()
    endif(VCPKG_MANIFEST_CREATED)

    set(options)
    set(oneValueArgs NAME VERSION DIR INSTALL_DIR)
    set(multiValueArgs)
    cmake_parse_arguments("MANIFEST" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(EXISTS "${MANIFEST_DIR}/vcpkg.json")
        message(STATUS "Manifest file already created")
        set(VCPKG_MANIFEST_DIR ${MANIFEST_DIR} CACHE STRING "manifest dir" FORCE)
        return()
    endif(EXISTS "${MANIFEST_DIR}/vcpkg.json")

    execute_process(
        COMMAND "${VCPKG_PATH}" "new" "--name" "${MANIFEST_NAME}" "--version" "${MANIFEST_VERSION}" "--x-install-root=${MANIFEST_INSTALL_DIR}"
        WORKING_DIRECTORY "${MANIFEST_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)
    execute_process(
        COMMAND "${VCPKG_PATH}" "x-update-baseline" "--add-initial-baseline"
        WORKING_DIRECTORY "${MANIFEST_DIR}")
    set(VCPKG_MANIFEST_CREATED true CACHE BOOL "whether vcpkg is found" FORCE)
    set(VCPKG_MANIFEST_DIR ${MANIFEST_DIR} CACHE STRING "manifest dir" FORCE)
endfunction(vcpkg_create_manifest)

function(vcpkg_add)
    if(NOT VCPKG_FOUND)
        message(FATAL_ERROR "ERROR: vcpkg is not found")
        return()
    endif(NOT VCPKG_FOUND)

    if(NOT EXISTS "${VCPKG_MANIFEST_DIR}/vcpkg.json")
        message(FATAL_ERROR "ERROR: vcpkg manifest not found, expected: ${VCPKG_MANIFEST_DIR}/vcpkg.json")
        return()
    endif(NOT EXISTS "${VCPKG_MANIFEST_DIR}/vcpkg.json")

    set(options)
    set(oneValueArgs NAME)
    set(multiValueArgs)
    cmake_parse_arguments("PACKAGE" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    execute_process(
        COMMAND "${VCPKG_PATH}" "add" "port" "${PACKAGE_NAME}"
        WORKING_DIRECTORY "${VCPKG_MANIFEST_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)
endfunction(vcpkg_add)

function(vcpkg_install)
    if(NOT VCPKG_FOUND)
        message(FATAL_ERROR "ERROR: vcpkg is not found")
        return()
    endif(NOT VCPKG_FOUND)

    set(options)
    set(oneValueArgs TRIPLET)
    set(multiValueArgs)
    cmake_parse_arguments("INSTALL" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    execute_process(
        COMMAND "${VCPKG_PATH}" "install" "--triplet=${INSTALL_TRIPLET}" "--clean-after-build"
        WORKING_DIRECTORY "${VCPKG_MANIFEST_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)
endfunction(vcpkg_install)

function(vcpkg_import_sdk)
    set(options)
    set(oneValueArgs URL HASH NAME)
    set(multiValueArgs)
    cmake_parse_arguments("SDK" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    FetchContent_Declare(
        "${SDK_NAME}"
        URL "${SDK_URL}"
        URL_HASH "${SDK_HASH}"
    )

    message(STATUS "Fetching SDK artifact ${SDK_NAME} from ${SDK_URL}")
    FetchContent_MakeAvailable("${SDK_NAME}")
    message(STATUS "Fetched SDK artifact ${SDK_NAME} from ${SDK_URL}")

    FetchContent_GetProperties(
        "${SDK_NAME}"
        SOURCE_DIR SDK_SOURCE_DIR
    )

    message(STATUS "SDK ${SDK_NAME} source dir: ${SDK_SOURCE_DIR}")

    include("${SDK_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake")
endfunction(vcpkg_import_sdk)


