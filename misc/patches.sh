# applying the latest driver patches for MT7961 based
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_RAM_CODE_MT7961_1.bin
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin
sudo rm -r /lib/firmware/mediatek/*
sudo cp WIFI_RAM_CODE_MT7961_1.bin /lib/firmware/mediatek/
sudo cp WIFI_MT7961_patch_mcu_1_2_hdr.bin /lib/firmware/mediatek/
sudo chmod 777 /lib/firmware/mediatek/WIFI_RAM_CODE_MT7961_1.bin
sudo chmod 777 /lib/firmware/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin
# check if files copied
if [[ -f /lib/firmware/mediatek/WIFI_RAM_CODE_MT7961_1.bin && -f /lib/firmware/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin ]]; then
    echo -e "\033[0;32mDriver files for MT7961 successfully copied to /lib/firmware/mediatek/\033[0m"
else
    echo -e "\033[0;31mFailed to copy driver files for MT7961. Please check permissions.\033[0m"
fi