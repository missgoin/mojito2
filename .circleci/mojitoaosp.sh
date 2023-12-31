#!/bin/bash

SECONDS=0 # builtin bash timer
ZIPNAME="SUPER.KERNEL-MOJITO_$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
TC_DIR="$PWD/tc/r487747"
GCC_64_DIR="$PWD/tc/aarch64-linux-android-4.9"
GCC_32_DIR="$PWD/tc/arm-linux-androideabi-4.9"
#AK3_DIR="$PWD/AnyKernel3"
DEFCONFIG="mojito_defconfig"

export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER="unknown"
export KBUILD_BUILD_HOST="Pancali"
export KBUILD_BUILD_VERSION="1"

if ! [ -d "${TC_DIR}" ]; then
echo "Clang not found! Cloning to ${TC_DIR}..."
if ! git clone --depth=1 https://gitlab.com/moehacker/clang-r487747.git ${TC_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${GCC_64_DIR}" ]; then
echo "gcc not found! Cloning to ${GCC_64_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${GCC_64_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${GCC_32_DIR}" ]; then
echo "gcc_32 not found! Cloning to ${GCC_32_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${GCC_32_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

#if [[ $1 = "-r" || $1 = "--regen" ]]; then
#make O=out ARCH=arm64 $DEFCONFIG savedefconfig
#cp out/defconfig arch/arm64/configs/$DEFCONFIG
#exit
#fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 \
    CC=clang \
    #LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- \
    CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    Image.gz

#if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
if [ -f "out/arch/arm64/boot/Image.gz" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"

#if [ -d "$AK3_DIR" ]; then
#cp -r $AK3_DIR AnyKernel3
#elif ! git clone --depth=1 https://github.com/missgoin/AnyKernel3; then
#echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
#exit 1
#fi

git clone --depth=1 https://github.com/missgoin/AnyKernel3.git
#git clone --depth=1 https://github.com/missgoin/AnyKernel3.git

cp out/arch/arm64/boot/Image.gz AnyKernel3

rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" *
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
echo -e "\nUploading to keep.sh!"
curl --upload-file $ZIPNAME https://free.keep.sh
else
echo -e "\nCompilation failed!"
exit 1
fi