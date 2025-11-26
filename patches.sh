# applying the latest driver patches for MT7961 based
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_RAM_CODE_MT7961_1.bin
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin
sudo rm -r /lib/firmware/mediatek/*
sudo cp WIFI_RAM_CODE_MT7961_1.bin /lib/firmware/mediatek/
sudo cp WIFI_MT7961_patch_mcu_1_2_hdr.bin /lib/firmware/mediatek/
sudo chmod 777 /lib/firmware/mediatek/WIFI_RAM_CODE_MT7961_1.bin
sudo chmod 777 /lib/firmware/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin
echo patches done