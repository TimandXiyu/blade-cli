# razerctl — Razer Blade 16 control tool.
# One-click build on a generic Linux box:
#     cmake -B build && cmake --build build
# Then (optional, needs root) install + sudo-less setup:
#     sudo cmake --install build
#
# The plain Makefile is kept too; this CMake path is for folks who prefer the
# standard cmake configure/build/install flow.

cmake_minimum_required(VERSION 3.10)
project(razerctl
        VERSION 1.0
        DESCRIPTION "Razer Blade 16 fan / perf / kbd / dGPU-undervolt control over hidraw"
        LANGUAGES C)

# Linux-only: it talks to /dev/hidraw and NVIDIA NvAPI/NVML.
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "razerctl is Linux-only (uses hidraw + libnvidia-api).")
endif()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(CMAKE_C_STANDARD 11)

add_executable(razerctl razerctl.c)
target_compile_options(razerctl PRIVATE -O2 -Wall)
target_link_libraries(razerctl PRIVATE ${CMAKE_DL_LIBS})   # dlopen libnvidia-api.so / libnvidia-ml.so

# ---- install (optional; run with sudo for the sudo-less setup to take) --------
include(GNUInstallDirs)
install(TARGETS razerctl RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES razerctl.1 DESTINATION ${CMAKE_INSTALL_MANDIR}/man1)

option(RAZERCTL_SETUP "On install: grant cap_sys_admin + install the udev rule (needs root)" ON)
if(RAZERCTL_SETUP)
    # Runs at `cmake --install` time. Mirrors `make install`: grant the
    # capability the dGPU undervolt needs and drop the HID uaccess rule.
    # Caps drop on copy, so this must run on every install. Non-root installs
    # just warn instead of failing the whole install.
    install(CODE [[
        set(BIN "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/razerctl")
        find_program(SETCAP_EXE NAMES setcap)
        if(SETCAP_EXE)
            execute_process(COMMAND ${SETCAP_EXE} cap_sys_admin+epi "${BIN}" RESULT_VARIABLE rc)
            if(rc EQUAL 0)
                message(STATUS "razerctl: granted cap_sys_admin (sudo-less dGPU undervolt)")
            else()
                message(WARNING "razerctl: setcap failed (run install as root) — dGPU undervolt will need sudo")
            endif()
        else()
            message(WARNING "razerctl: 'setcap' not found (install libcap) — dGPU undervolt will need sudo")
        endif()

        set(RULE "/etc/udev/rules.d/99-razerctl.rules")
        file(WRITE "${RULE}"
            "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{idVendor}==\"1532\", ATTRS{idProduct}==\"02b7\", MODE=\"0660\", TAG+=\"uaccess\"\n")
        find_program(UDEVADM_EXE NAMES udevadm)
        if(UDEVADM_EXE)
            execute_process(COMMAND ${UDEVADM_EXE} control --reload-rules)
            execute_process(COMMAND ${UDEVADM_EXE} trigger)
        endif()
        message(STATUS "razerctl: installed udev rule ${RULE} (re-plug / re-login if the device isn't reachable yet)")
        message(STATUS "razerctl: NOTE the dGPU max-freq cap still needs real root — run `sudo razerctl` for it")
    ]])
endif()
