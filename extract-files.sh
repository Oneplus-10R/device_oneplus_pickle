#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=pickle
VENDOR=oneplus

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_FIRMWARE=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-firmware)
            ONLY_FIRMWARE=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        odm/bin/hw/android.hardware.ir-service)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.ir-V1-ndk_platform.so" "android.hardware.ir-V1-ndk.so" "${2}"
            ;;
        odm/lib64/vendor.oplus.hardware.hdcp-V1-ndk_platform.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.common-V2-ndk_platform.so" "android.hardware.common-V2-ndk.so" "${2}"
            ;;
        system_ext/etc/init/init.vtservice.rc|\
        vendor/etc/init/android.hardware.neuralnetworks-shim-service-mtk.rc)
            [ "$2" = "" ] && return 0
            sed -i "s|start|enable|g" "${2}"
            ;;
        system_ext/lib64/libsink.so)
            [ "$2" = "" ] && return 0
            grep -q "libshim_sink.so" "${2}" || "${PATCHELF}" --add-needed "libshim_sink.so" "${2}"
            ;;
        system_ext/lib64/libsource.so)
            [ "$2" = "" ] && return 0
            grep -q "libui_shim.so" "${2}" || "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            ;;
        system_ext/priv-app/ImsService/ImsService.apk)
            [ "$2" = "" ] && return 0
            apktool_patch "${2}" "${MY_DIR}/blob-patches/ImsService.patch"
            ;;
        vendor/bin/hw/android.hardware.gnss-service.mediatek|\
        vendor/lib64/hw/android.hardware.gnss-impl-mediatek.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.gnss-V1-ndk_platform.so" "android.hardware.gnss-V1-ndk.so" "${2}"
            ;;
        vendor/bin/hw/android.hardware.media.c2@1.2-mediatek-64b)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libavservices_minijail_vendor.so" "libavservices_minijail.so" "${2}"
            grep -q "libstagefright_foundation-v33.so" "${2}" || "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/bin/hw/android.hardware.security.keymint-service.trustonic)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.security.keymint-V1-ndk_platform.so" "android.hardware.security.keymint-V1-ndk.so" "${2}"
            "${PATCHELF}" --replace-needed "android.hardware.security.sharedsecret-V1-ndk_platform.so" "android.hardware.security.sharedsecret-V1-ndk.so" "${2}"
            "${PATCHELF}" --replace-needed "android.hardware.security.secureclock-V1-ndk_platform.so" "android.hardware.security.secureclock-V1-ndk.so" "${2}"
            grep -q "android.hardware.security.rkp-V3-ndk.so" "${2}" || "${PATCHELF}" --add-needed "android.hardware.security.rkp-V3-ndk.so" "${2}"
            ;;
        vendor/bin/mnld|\
        vendor/lib64/hw/android.hardware.sensors@2.X-subhal-mediatek.so|\
        vendor/lib64/liboplus_mtkcam_lightsensorprovider.so|\
        vendor/lib64/mt6895/libaalservice.so)
            [ "$2" = "" ] && return 0
            grep -q "libshim_sensors.so" "${2}" || "${PATCHELF}" --add-needed "libshim_sensors.so" "${2}"
            ;;
        vendor/etc/init/init.thermal_core.rc)
            [ "$2" = "" ] && return 0
            sed -i 's|ro.vendor.mtk_thermal_2_0|vendor.thermal.link_ready|g' "${2}"
            ;;
        vendor/etc/media_profiles_V1_0.xml)
            [ "$2" = "" ] && return 0
            sed -i '/<CamcorderProfiles cameraId="3">/,/<\/CamcorderProfiles>/ { /^[[:space:]]*<!--/! { /^[[:space:]]*$/! { s/^/<!-- /; s/$/ -->/; } } }' "${2}"
            ;;
        vendor/lib64/hw/audio.primary.mediatek.so)
            [ "$2" = "" ] && return 0
            grep -q "libstagefright_foundation-v33.so" "${2}" || "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/lib64/hw/mt6895/android.hardware.camera.provider@2.6-impl-mediatek.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            grep -q "libcamera_metadata_shim.so" "${2}" || "${PATCHELF}" --add-needed "libcamera_metadata_shim.so" "${2}"
            ;;
        vendor/lib64/hw/mt6895/vendor.mediatek.hardware.pq@2.15-impl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            grep -q "libshim_sensors.so" "${2}" || "${PATCHELF}" --add-needed "libshim_sensors.so" "${2}"
            sed -i 's|/my_product/vendor/etc/cust_silky_brightness_%s_%s.xml|/vendor/etc/cust_silky_brightness_%s_%s.xml\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g' "${2}"
            sed -i 's|/my_product/vendor/etc/cust_silky_brightness_%s.xml|/vendor/etc/cust_silky_brightness_%s.xml\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g' "${2}"
            ;;
        vendor/lib64/lib3a.ae.pipe.so|\
        vendor/lib64/mt6895/lib3a.awbsync.so|\
        vendor/lib64/mt6895/lib3a.flash.so|\
        vendor/lib64/mt6895/lib3a.sensors.color.so|\
        vendor/lib64/mt6895/lib3a.sensors.flicker.so)
            [ "$2" = "" ] && return 0
            grep -q "liblog.so" "${2}" || "${PATCHELF_0_17_2}" --add-needed "liblog.so" "${2}"
            ;;
        vendor/lib64/libmidasserviceintf_aidl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.frameworks.stats-V1-ndk_platform.so" "android.frameworks.stats-V1-ndk.so" "${2}"
            ;;
        vendor/lib64/mt6895/libmnl.so)
            [ "$2" = "" ] && return 0
            grep -q "libcutils.so" "${2}" || "${PATCHELF}" --add-needed "libcutils.so" "${2}"
            ;;
        vendor/lib64/mt6895/libmtkcam_stdutils.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

if [ -z "${ONLY_FIRMWARE}" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${SECTION}" ]; then
    extract_firmware "${MY_DIR}/proprietary-firmware.txt" "${SRC}"
fi

"${MY_DIR}/setup-makefiles.sh"
