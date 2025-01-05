#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from the custom device configuration.
$(call inherit-product, device/oneplus/pickle/device.mk)

# Inherit from the LineageOS configuration.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_BRAND := OnePlus
PRODUCT_DEVICE := pickle
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_MODEL := CPH2423
PRODUCT_NAME := lineage_pickle

PRODUCT_GMS_CLIENTID_BASE := android-oneplus

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="sys_mssi_64_cn_armv82-user 14 UKQ1.230924.001 1727668240847 release-keys" \
    BuildFingerprint=OnePlus/CPH2411/OP5566L1:14/UKQ1.230924.001/S.1b618ef_1-502fd:user/release-keys \
    DeviceName=CPH2423 \
    DeviceProduct=CPH2423 \
    SystemDevice=CPH2423 \
    SystemName=CPH2423
