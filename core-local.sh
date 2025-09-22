#!/bin/bash
#=================================================
# This script is from https://github.com/lunatickochiya/Lunatic-s805-rockchip-Action
# Written By lunatickochiya
# QQ group :286754582  https://jq.qq.com/?_wv=1027&k=5QgVYsC
#=================================================

function init_openwrt() {
OpenWrt_PATCH_FILE_DIR=openwrt-2410
Matrix_Target=ath79-nftables
Target_CFG_Machine=domywifi_dw33d-ath79
PATCH_JSON_INPUT={"OPENSSL_3_5": "1", "BCM_FULLCONE": "1", "TRY_BBR_V3": "1", "Firewall_Allow_WAN": "1", "MAC80211_616": "0", "TEST_KERNEL": "0", "ADD_IB": "0", "ADD_SDK": "0", "DOCKER_BUILDIN": "0"}
SFE_INPUT_STATUS=true
INPUT_PKGS_CFG_STATUS=m
INPUT_PKGS_CFG_FOO=luci-app-example,luci-app-example2
IPSET_VALUE=192.168.7.1
#CONFIG_JSON_INPUT={"Cache": "1", "UPLOAD_RELEASE": "1", "ALLKMOD": "1"}
init_gh_env_2410
config_json_input_set
patch_json_input_set
init_gh_env_common

init_math_config
init_openwrt_pkg_config

git_clone_openwrt

init_openwrt_patch_common
init_openwrt_patch_2410

add_openwrt_sfe_ipt_k66
add_openwrt_sfe_nft_k66
add_openwrt_sfe_kernel_k612
add_openwrt_sfe_kmods

add_openwrt_files
patch_openwrt_core_pre

autoset_set_ip
update_openwrt_feeds

move_openwrt_config_ready
fix_openwrt_feeds
refine_openwrt_config

add_openwrt_kmods

}

function git_clone_openwrt() {
	git clone $REPO_URL -b $REPO_BRANCH openwrt --single-branch
	cd openwrt
	sed -i \
		-e 's|https://git.openwrt.org/feed/packages.git;openwrt-24.10|https://github.com/openwrt/packages.git;openwrt-24.10|' \
		-e 's|https://git.openwrt.org/project/luci.git;openwrt-24.10|https://github.com/openwrt/luci.git;openwrt-24.10|' \
		-e 's|https://git.openwrt.org/feed/routing.git;openwrt-24.10|https://github.com/openwrt/routing.git;openwrt-24.10|' \
		-e 's|https://git.openwrt.org/feed/telephony.git;openwrt-24.10|https://github.com/openwrt/telephony.git;openwrt-24.10|' \
		feeds.conf.default
	sed -i '$a src-git lunatic7 https://github.com/lunatickochiya/actionbased-openwrt-packages.git' feeds.conf.default
}

function autoset_set_ip() {
	sed -i "s/192\.168\.10\.1/$IPSET_VALUE/g" openwrt/package/kochiya/autoset/files/def_uci/zzz-autoset*
	grep 'set network.lan.ipaddr=' openwrt/package/kochiya/autoset/files/def_uci/zzz-autoset*
}
function update_openwrt_feeds() {
	cd openwrt
	./scripts/feeds update -a
	./scripts/feeds install -a
	cd ../
}
function init_pkg_env() {
	sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
	sudo -E apt-get -qq update
	sudo -E apt-get -qq install build-essential clang flex g++ gawk gcc-multilib gettext \
		git libncurses5-dev libssl-dev python3-distutils python3-pyelftools python3-setuptools \
		libpython3-dev rsync unzip zlib1g-dev swig aria2 jq subversion qemu-utils ccache rename \
		libelf-dev device-tree-compiler libgnutls28-dev coccinelle libgmp3-dev libmpc-dev libfuse-dev \
		b43-fwcutter cups-ppdc

	sudo -E apt-get -qq purge azure-cli ghc* zulu* llvm* firefox powershell openjdk* dotnet* google* mysql* php* android*
	sudo -E apt-get -qq autoremove --purge
	sudo -E apt-get -qq clean

	sudo timedatectl set-timezone "$TZ"
	sudo mkdir -p /workdir
	sudo chown "$USER":"$GROUPS" /workdir
}

function init_gh_env_2410() {
	source "${GITHUB_WORKSPACE}/env/common.txt"
	source "${GITHUB_WORKSPACE}/env/openwrt-24.10.repo"
	echo -e "TEST_KERNEL=$(echo $PATCH_JSON_INPUT | jq -r ".TEST_KERNEL")" >> "$GITHUB_ENV"
}

function init_gh_env_2410_ipq() {
	source "${GITHUB_WORKSPACE}/env/common.txt"
	source "${GITHUB_WORKSPACE}/env/openwrt-ipq.repo"
	echo -e "Branch=$(echo $PATCH_JSON_INPUT | jq -r ".Branch")" >> $GITHUB_ENV
	echo -e "IPQ_Firmware=$(echo $PATCH_JSON_INPUT | jq -r ".IPQ_Firmware")" >> $GITHUB_ENV
}

function config_json_input_set() {
	echo -e "Cache=$(echo $CONFIG_JSON_INPUT | jq -r ".Cache")" >> "$GITHUB_ENV"
	echo -e "UPLOAD_RELEASE=$(echo $CONFIG_JSON_INPUT | jq -r ".UPLOAD_RELEASE")" >> "$GITHUB_ENV"
	echo -e "ALLKMOD=$(echo $CONFIG_JSON_INPUT | jq -r ".ALLKMOD")" >> "$GITHUB_ENV"
}

function patch_json_input_set() {
	echo -e "OPENSSL_3_5=$(echo $PATCH_JSON_INPUT | jq -r ".OPENSSL_3_5")" >> "$GITHUB_ENV"
	echo -e "BCM_FULLCONE=$(echo $PATCH_JSON_INPUT | jq -r ".BCM_FULLCONE")" >> "$GITHUB_ENV"
	echo -e "TRY_BBR_V3=$(echo $PATCH_JSON_INPUT | jq -r ".TRY_BBR_V3")" >> "$GITHUB_ENV"
	echo -e "Firewall_Allow_WAN=$(echo $PATCH_JSON_INPUT | jq -r ".Firewall_Allow_WAN")" >> "$GITHUB_ENV"
	echo -e "DOCKER_BUILDIN=$(echo $PATCH_JSON_INPUT | jq -r ".DOCKER_BUILDIN")" >> "$GITHUB_ENV"
	echo -e "ADD_IB=$(echo $PATCH_JSON_INPUT | jq -r ".ADD_IB")" >> "$GITHUB_ENV"
	echo -e "ADD_SDK=$(echo $PATCH_JSON_INPUT | jq -r ".ADD_SDK")" >> "$GITHUB_ENV"
	echo -e "MAC80211_616=$(echo $PATCH_JSON_INPUT | jq -r ".MAC80211_616")" >> "$GITHUB_ENV"
}

function init_gh_env_common() {
	echo "date=$(date +'%m/%d_%Y_%H/%M')" >> "$GITHUB_ENV"
	echo "date2=$(date +'%Y/%m %d')" >> "$GITHUB_ENV"
	echo "date3=$(date +'%m.%d')" >> "$GITHUB_ENV"

	echo "REPO_URL=${REPO_URL}" >> "$GITHUB_ENV"
	echo "BURN_UBOOT_IMG_URL=${BURN_UBOOT_IMG_URL}" >> "$GITHUB_ENV"
	echo "AMLIMG_TOOL_URL=${AMLIMG_TOOL_URL}" >> "$GITHUB_ENV"
	echo "REPO_BRANCH=${REPO_BRANCH}" >> "$GITHUB_ENV"
	echo "DIY_SH=${DIY_SH}" >> "$GITHUB_ENV"
	echo "DIY_SH_AFB=${DIY_SH_AFB}" >> "$GITHUB_ENV"
	echo "DIY_SH_RFC=${DIY_SH_RFC}" >> "$GITHUB_ENV"
	echo "UPLOAD_BIN_DIR=${UPLOAD_BIN_DIR}" >> "$GITHUB_ENV"
	echo "UPLOAD_IPK_DIR=${UPLOAD_IPK_DIR}" >> "$GITHUB_ENV"
	echo "UPLOAD_FIRMWARE=${UPLOAD_FIRMWARE}" >> "$GITHUB_ENV"
	echo "UPLOAD_COWTRANSFER=${UPLOAD_COWTRANSFER}" >> "$GITHUB_ENV"
	echo "UPLOAD_WETRANSFER=${UPLOAD_WETRANSFER}" >> "$GITHUB_ENV"
	echo "UPLOAD_ALLKMOD=${UPLOAD_ALLKMOD}" >> "$GITHUB_ENV"
	echo "UPLOAD_SYSUPGRADE=${UPLOAD_SYSUPGRADE}" >> "$GITHUB_ENV"
	echo "USE_Cache=${USE_Cache}" >> "$GITHUB_ENV"

	chmod +x "$DIY_SH" "$DIY_SH_AFB" "$DIY_SH_RFC"
	echo "The Matrix_Target is: $Matrix_Target"
	echo "The MATH Matrix_Target is: $Target_CFG_Machine"
}

function init_math_config() {
	if [ "$Matrix_Target" == 'mt798x-nftables' ] || [ "$Matrix_Target" == 'mt798x-nousb-nftables' ] || \
		[ "$Matrix_Target" == 'ramips-nftables' ] || [ "$Matrix_Target" == 'ath79-nftables' ] || \
		[ "$Matrix_Target" == 'ipq-nftables' ]; then
		bash $GITHUB_WORKSPACE/add-test-packages.sh nft
		echo "----$Matrix_Target-----NFT-test---"
	fi

	if [ "$Matrix_Target" == 'mt798x-iptables' ] || [ "$Matrix_Target" == 'mt798x-nousb-iptables' ] || \
		[ "$Matrix_Target" == 'ramips-iptables' ] || [ "$Matrix_Target" == 'ath79-iptables' ] || \
		[ "$Matrix_Target" == 'ipq-iptables' ]; then
		mv -f machine-configs/single/$Target_CFG_Machine-iptables.config machine-configs/$Matrix_Target.config
		echo "----$Matrix_Target-----IPT-Machine--------"
	elif [ "$Matrix_Target" == 'mt798x-nftables' ] || [ "$Matrix_Target" == 'mt798x-nousb-nftables' ] || \
		 [ "$Matrix_Target" == 'ramips-nftables' ] || [ "$Matrix_Target" == 'ath79-nftables' ] || \
		 [ "$Matrix_Target" == 'ipq-nftables' ]; then
		mv -f machine-configs/single/$Target_CFG_Machine-nftables.config machine-configs/$Matrix_Target.config
		echo "----$Matrix_Target-----NFT-Machine--------"
	fi
}

function init_openwrt_pkg_config() {
	case "$Matrix_Target" in
		mt798x-iptables)
			mv -f package-configs/single/$Target_CFG_Machine-iptables.config package-configs/mt798x-common-iptables.config
			echo "----$Matrix_Target-----IPT-Package-Config----"
			;;
		mt798x-nftables)
			mv -f package-configs/single/$Target_CFG_Machine-nftables.config package-configs/mt798x-common-nftables.config
			echo "----$Matrix_Target-----NFT-Package-Config----"
			;;
		mt798x-nousb-nftables)
			mv -f package-configs/single/$Target_CFG_Machine-nftables.config package-configs/mt798x-nousb-nftables.config
			echo "----$Matrix_Target-----NFT-Package-Config----"
			;;
		mt798x-nousb-iptables)
			mv -f package-configs/single/$Target_CFG_Machine-iptables.config package-configs/mt798x-nousb-iptables.config
			echo "----$Matrix_Target-----IPT-Package-Config----"
			;;
		ramips-iptables)
			mv -f package-configs/single/$Target_CFG_Machine-iptables.config package-configs/ramips-common-iptables.config
			echo "----$Matrix_Target-----IPT-Package-Config----"
			;;
		ramips-nftables)
			mv -f package-configs/single/$Target_CFG_Machine-nftables.config package-configs/ramips-common-nftables.config
			echo "----$Matrix_Target-----NFT-Package-Config----"
			;;
		ath79-iptables)
			mv -f package-configs/single/$Target_CFG_Machine-iptables.config package-configs/ath79-common-iptables.config
			echo "----$Matrix_Target-----IPT-Package-Config----"
			;;
		ath79-nftables)
			mv -f package-configs/single/$Target_CFG_Machine-nftables.config package-configs/ath79-common-nftables.config
			echo "----$Matrix_Target-----NFT-Package-Config----"
			;;
		ipq-iptables)
			mv -f package-configs/single/$Target_CFG_Machine-iptables.config package-configs/ipq-common-iptables.config
			echo "----$Matrix_Target-----IPT-Package-Config----"
			;;
		ipq-nftables)
			mv -f package-configs/single/$Target_CFG_Machine-nftables.config package-configs/ipq-common-nftables.config
			echo "----$Matrix_Target-----NFT-Package-Config----"
			;;
	esac
}

function init_openwrt_pkg_config_nss() {
	case "$Matrix_Target" in
		ipq-iptables)
			mv -f package-configs/single/$Target_CFG_Machine-iptables-nss.config package-configs/ipq-common-iptables.config
			echo "----$Matrix_Target-----IPT-Package-Config----"
			;;
		ipq-nftables)
			mv -f package-configs/single/$Target_CFG_Machine-nftables-nss.config package-configs/ipq-common-nftables.config
			echo "----$Matrix_Target-----NFT-Package-Config----"
			;;
	esac
}

function init_openwrt_patch_common() {
	if [ "$Firewall_Allow_WAN" = "1" ]; then
		$GITHUB_WORKSPACE/$DIY_SH firewall-allow-wan
		echo "----$Matrix_Target----wan-allow---"
		echo "WAN_NAME=_WAN_ALLOW" >> $GITHUB_ENV
	fi

	if [ "$TRY_BBR_V3" = "1" ]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/mypatch-bbr-v3 ] && cp -r $OpenWrt_PATCH_FILE_DIR/mypatch-bbr-v3/* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
		echo "----$Matrix_Target----bbr-v3---"
		echo "TRY_BBR_V3_NAME=_BBR_V3" >> $GITHUB_ENV
	fi

	if [ "$OPENSSL_3_5" = "1" ]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/openssl-bump ] && cp -r $OpenWrt_PATCH_FILE_DIR/openssl-bump/* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
		echo "----$Matrix_Target----openssl-3-5---"
		echo "OPENSSL_3_5_NAME=_OPENSSL_3_5" >> $GITHUB_ENV
	fi

	if [ "$MAC80211_616" = "1" ]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/mac80211-616 ] && cp -r $OpenWrt_PATCH_FILE_DIR/mac80211-616/* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
		rm -rf openwrt/package/kernel/mt76/patches/100-api_compat.patch
		echo "----$Matrix_Target----mac80211-6-16---"
		echo "MAC80211_616_NAME=_MAC80211_616" >> $GITHUB_ENV
	fi

	if [ "$AG71XX_FIX" = "1" ]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/my-patch-ag71xx-fix ] && cp -r $OpenWrt_PATCH_FILE_DIR/my-patch-ag71xx-fix/* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
	fi

	if [ "$BCM_FULLCONE" = "1" ] && [[ "$Matrix_Target" == *-iptables ]]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/bcmfullcone ] && cp -r $OpenWrt_PATCH_FILE_DIR/bcmfullcone/a-* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
		rm -rf $OpenWrt_PATCH_FILE_DIR/luci-patch-2410/0004-Revert-luci-app-firewall-add-fullcone.patch
		echo "----$Matrix_Target-----ipt-bcm---"
		echo "BCM_FULLCONE_NAME=_BCM_FULLCONE" >> $GITHUB_ENV
	fi

	if [ "$BCM_FULLCONE" = "1" ] && [[ "$Matrix_Target" == *-nftables ]]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/bcmfullcone ] && cp -r $OpenWrt_PATCH_FILE_DIR/bcmfullcone/b-* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
		rm -rf $OpenWrt_PATCH_FILE_DIR/luci-patch-2410/0004-Revert-luci-app-firewall-add-fullcone.patch
		echo "----$Matrix_Target-----nft-bcm---"
		echo "BCM_FULLCONE_NAME=_BCM_FULLCONE" >> $GITHUB_ENV
	fi

	if [ "$DOCKER_BUILDIN" = "1" ]; then
		bash $GITHUB_WORKSPACE/add-sfe-packages.sh ipq-docker
		echo "----$Matrix_Target-----Docker--Config--Added--"
		echo "DOCKER_NAME=_DOCKER" >> $GITHUB_ENV
	fi

	if [ "$ADD_SDK" = "1" ]; then
		bash $GITHUB_WORKSPACE/add-sfe-packages.sh lunatic-lede-sdk
		echo "----$Matrix_Target----SDK---"
	fi

	if [ "$ADD_IB" = "1" ]; then
		bash $GITHUB_WORKSPACE/add-sfe-packages.sh lunatic-lede-ib
		echo "----$Matrix_Target----IB---"
	fi
}

function init_openwrt_patch_2410() {
	if [ "$TEST_KERNEL" = "1" ]; then
		[ -d $OpenWrt_PATCH_FILE_DIR/core-6-12 ] && cp -r $OpenWrt_PATCH_FILE_DIR/core-6-12/* $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target
		rm -rf openwrt/package/kernel/mt76/patches/100-api_compat.patch
		echo "----$Matrix_Target----TEST-KERNEL---"
	fi
}

function init_openwrt_patch_2410_ipq() {
	bash $GITHUB_WORKSPACE/add-sfe-packages.sh $IPQ_Firmware
}


function ln_openwrt() {
	sudo mkdir -p -m 777 /mnt/openwrt/dl /mnt/openwrt/bin /mnt/openwrt/staging_dir /mnt/openwrt/build_dir
	ln -sf /mnt/openwrt/dl openwrt/dl
	ln -sf /mnt/openwrt/bin openwrt/bin
	ln -sf /mnt/openwrt/staging_dir openwrt/staging_dir
	ln -sf /mnt/openwrt/build_dir openwrt/build_dir
	df -hT
	ls /mnt/openwrt
}

function add_openwrt_sfe_ipt_k66() {
	if [ "$Matrix_Target" == 'mt798x-iptables' ] || [ "$Matrix_Target" == 'mt798x-nousb-iptables' ] || \
	   [ "$Matrix_Target" == 'ramips-iptables' ] || [ "$Matrix_Target" == 'ath79-iptables' ] || \
	   [ "$Matrix_Target" == 'ipq-iptables' ]; then
		bash "$GITHUB_WORKSPACE/add-sfe-packages.sh" ipt
		echo "----$Matrix_Target-----ipt-sfe---"
		cd openwrt
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/pending-6.6/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.6/
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/hack-6.6/952-add-net-conntrack-events-support-multiple-registrant.patch -P target/linux/generic/hack-6.6/
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/hack-6.6/953-net-patch-linux-kernel-to-support-shortcut-fe.patch -P target/linux/generic/hack-6.6/
		echo "# CONFIG_NF_CONNTRACK_CHAIN_EVENTS is not set" >> "./target/linux/generic/config-6.6"
		echo "# CONFIG_SHORTCUT_FE is not set" >> "./target/linux/generic/config-6.6"
		# git clone https://github.com/lunatickochiya/luci-app-turboacc-js package/luci-app-turboacc-js && sed -i 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?' ./package/luci-app-turboacc-js/Makefile ; rm -rf ./package/luci-app-turboacc-js/.git/
		git clone --depth=1 --single-branch --branch "package" https://github.com/chenmozhijin/turboacc
		mv -n turboacc/shortcut-fe ./package
		rm -rf turboacc
		cd ../
	fi
}

function add_openwrt_sfe_nft_k66() {
	if [ "$Matrix_Target" == 'mt798x-nftables' ] || [ "$Matrix_Target" == 'mt798x-nousb-nftables' ] || \
	   [ "$Matrix_Target" == 'ramips-nftables' ] || [ "$Matrix_Target" == 'ath79-nftables' ] || \
	   [ "$Matrix_Target" == 'ipq-nftables' ]; then
		cd openwrt
		curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
		echo "----$Matrix_Target-----NFT-acc----"
		cd ../
	fi
}

function add_openwrt_sfe_kernel_k612() {
	if [ "$TEST_KERNEL" = "1" ]; then
		cd openwrt
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/pending-6.12/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.12/
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/hack-6.12/952-add-net-conntrack-events-support-multiple-registrant.patch -P target/linux/generic/hack-6.12/
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/hack-6.12/953-net-patch-linux-kernel-to-support-shortcut-fe.patch -P target/linux/generic/hack-6.12/
		rm -rf package/turboacc/shortcut-fe/simulated-driver
		cd ../
	fi
	if [ "$Branch" = "24.10-nss-6.12" ]; then
		cd openwrt
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/pending-6.12/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.12/
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/hack-6.12/952-add-net-conntrack-events-support-multiple-registrant.patch -P target/linux/generic/hack-6.12/
		wget -N https://raw.githubusercontent.com/chenmozhijin/turboacc/refs/heads/package/hack-6.12/953-net-patch-linux-kernel-to-support-shortcut-fe.patch -P target/linux/generic/hack-6.12/
		rm -rf package/turboacc/shortcut-fe/simulated-driver
		rm -rf package/shortcut-fe/simulated-driver
		cd ../
	fi

}

function add_openwrt_sfe_kernel_nss_patch() {
		mkdir -p openwrt/target/linux/qualcommax/patches-6.6
		mkdir -p openwrt/target/linux/qualcommax/patches-6.12
	if [ "$Branch" = "24.10-nss-6.12" ]; then
		cp -f openwrt-ipq/sfe-ipq-6.12/20250425/0600-1-qca-nss-ecm-support-CORE.patch openwrt/target/linux/qualcommax/patches-6.12/0600-1-qca-nss-ecm-support-CORE.patch
		cp -f openwrt-ipq/sfe-ipq-6.12/20250425/0981-0-qca-skbuff-revert.patch openwrt/target/linux/qualcommax/patches-6.12/0981-0-qca-skbuff-revert.patch
	fi

	if [ "$Branch" = "24.10-nss-202502" ] || [ "$Branch" = "24.10-nss-202503" ] || [ "$Branch" = "24.10-nss-202504" ]; then
		cp -f openwrt-ipq/sfe-ipq-6.6/202502/0600-1-qca-nss-ecm-support-CORE.patch openwrt/target/linux/qualcommax/patches-6.6/0600-1-qca-nss-ecm-support-CORE.patch
		cp -f openwrt-ipq/sfe-ipq-6.6/202502/0603-1-qca-nss-clients-add-qdisc-support.patch openwrt/target/linux/qualcommax/patches-6.6/0603-1-qca-nss-clients-add-qdisc-support.patch
	else
		cp -f openwrt-ipq/sfe-ipq-6.6/20250425/0600-1-qca-nss-ecm-support-CORE.patch openwrt/target/linux/qualcommax/patches-6.6/0600-1-qca-nss-ecm-support-CORE.patch
		cp -f openwrt-ipq/sfe-ipq-6.6/20250425/0603-1-qca-nss-clients-add-qdisc-support.patch openwrt/target/linux/qualcommax/patches-6.6/0603-1-qca-nss-clients-add-qdisc-support.patch
		cp -f openwrt-ipq/sfe-ipq-6.6/20250425/0981-0-qca-skbuff-revert.patch openwrt/target/linux/qualcommax/patches-6.6/0981-0-qca-skbuff-revert.patch
	fi

		mkdir -p openwrt/package/qca
		echo "SFE=_SFE" >> $GITHUB_ENV
}
function add_openwrt_nosfe_nss_pkgs() {
		# git clone --depth 1 https://github.com/coolsnowwolf/lede && mv lede/package/qca/qca-nss-ecm openwrt/package/qca/qca-nss-ecm && rm -rf lede
		# cp -f openwrt-ipq/sfe-ipq-6.6/0604-1-qca-add-mcs-support.patch openwrt/target/linux/qualcommax/patches-6.6/0604-1-qca-add-mcs-support.patch
		# sed -i 's/"feeds\/lunatic7\/shortcut-fe"//g' diy-2410.sh
		# sed -i 's/"feeds\/lunatic7\/luci-app-turboacc"//g' diy-2410.sh
		mkdir -p openwrt/package/qca

	if [ "$Matrix_Target" == 'mt798x-iptables' ] || [ "$Matrix_Target" == 'mt798x-nousb-iptables' ] || \
		[ "$Matrix_Target" == 'ramips-iptables' ] || [ "$Matrix_Target" == 'ath79-iptables' ] || \
		[ "$Matrix_Target" == 'ipq-iptables' ]; then
		bash $GITHUB_WORKSPACE/add-sfe-packages.sh ipq-ipt-turboacc-nosfe
		# sed -i 's/kmod-shortcut-fe-drv,//g' package-configs/kmod_exclude_list*
		# sed -i 's/"feeds\/lunatic7\/luci-app-turboacc"//g' "$DIY_SH"
		sed -i 's/"feeds\/lunatic7\/shortcut-fe"//g' "$DIY_SH"
		echo "----$Matrix_Target-----BBR-acc----"
	fi
	if [ "$Matrix_Target" == 'mt798x-nftables' ] || [ "$Matrix_Target" == 'mt798x-nousb-nftables' ] || \
		[ "$Matrix_Target" == 'ramips-nftables' ] || [ "$Matrix_Target" == 'ath79-nftables' ] || \
		[ "$Matrix_Target" == 'ipq-nftables' ]; then
		bash $GITHUB_WORKSPACE/add-sfe-packages.sh ipq-nft-turboacc-nosfe
		# sed -i 's/kmod-shortcut-fe-drv,//g' package-configs/kmod_exclude_list*
		sed -i 's/"feeds\/lunatic7\/luci-app-turboacc"//g' "$DIY_SH"
		sed -i 's/"feeds\/lunatic7\/shortcut-fe"//g' "$DIY_SH"
		echo "----$Matrix_Target-----BBR-acc----"
	fi

}

function add_openwrt_sfe_kmods() {
	sed -i 's/kmod-shortcut-fe-cm,kmod-shortcut-fe,kmod-fast-classifier,kmod-fast-classifier-noload,kmod-shortcut-fe-drv,//g' package-configs/kmod_exclude_list*
	# sed -i 's/"feeds\/lunatic7\/shortcut-fe"//g' diy-2410.sh
	# sed -i 's/"feeds\/lunatic7\/luci-app-turboacc"//g' diy-2410.sh
}

function add_openwrt_files() {
	mkdir -p openwrt/feeds/lunatic7

	[ -d package ] && mv -f package/* openwrt/package
	[ -d $OpenWrt_PATCH_FILE_DIR/package-for-mt798x ] && mv -f $OpenWrt_PATCH_FILE_DIR/package-for-mt798x/* openwrt/package
# for 2410
	if [ "$OpenWrt_PATCH_FILE_DIR" = "openwrt-2410" ]; then
	if [ "$Matrix_Target" == 'ramips-iptables' ] || [ "$Matrix_Target" == 'ramips-nftables' ] || \
		[ "$Matrix_Target" == 'ath79-iptables' ] || [ "$Matrix_Target" == 'ath79-nftables' ]; then
		mkdir -p openwrt/package/kochiya/pcre
		[ -d $OpenWrt_PATCH_FILE_DIR/package-for-2410 ] && cp -r $OpenWrt_PATCH_FILE_DIR/package-for-2410/kochiya/pcre openwrt/package/kochiya/pcre
	else
		[ -d $OpenWrt_PATCH_FILE_DIR/package-for-2410 ] && cp -r $OpenWrt_PATCH_FILE_DIR/package-for-2410/* openwrt/package
	fi

	[ -d $OpenWrt_PATCH_FILE_DIR/mypatch-2410 ] && mv -f $OpenWrt_PATCH_FILE_DIR/mypatch-2410 openwrt/mypatch-2410
	[ -d $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target ] && mv -f $OpenWrt_PATCH_FILE_DIR/mypatch-2410-$Matrix_Target openwrt/mypatch

	if [ "$TEST_KERNEL" = "1" ]; then
		find openwrt/target/linux/mediatek/dts/ -type f -name 'mt7981*.dts' -exec sed -i 's|#include "mt7981.dtsi"|#include "mt7981b.dtsi"|' {} +
		# mv -f $OpenWrt_PATCH_FILE_DIR/2410-test/999-wct4xxp-Eliminate-old-style-declaration.patch openwrt/feeds/telephony/libs/dahdi-linux/patches/999-wct4xxp-Eliminate-old-style-declaration.patch
	fi
	fi
# for 2410 end

# for 2410 ipq
	if [ "$OpenWrt_PATCH_FILE_DIR" = "openwrt-ipq" ]; then
	[ -d $OpenWrt_PATCH_FILE_DIR/package-for-openwrt-ipq ] && cp -r $OpenWrt_PATCH_FILE_DIR/package-for-openwrt-ipq/* openwrt/package
	[ -d $OpenWrt_PATCH_FILE_DIR/mypatch-openwrt-ipq ] && mv -f $OpenWrt_PATCH_FILE_DIR/mypatch-openwrt-ipq openwrt/mypatch-openwrt-ipq
	[ -d $OpenWrt_PATCH_FILE_DIR/mypatch-openwrt-ipq-$Matrix_Target ] && mv -f $OpenWrt_PATCH_FILE_DIR/mypatch-openwrt-ipq-$Matrix_Target openwrt/mypatch
	fi

	[ -e files ] && mv files openwrt/files
}

function patch_openwrt_core_pre() {
	cd openwrt
	"$GITHUB_WORKSPACE/$DIY_SH" patch-openwrt
# for 2410
	if [ "$SFE_INPUT_STATUS" = "true" ] && [ "$TEST_KERNEL" = "1" ]; then
		echo "# CONFIG_NF_CONNTRACK_CHAIN_EVENTS is not set" >> "./target/linux/generic/config-6.12"
		echo "# CONFIG_SHORTCUT_FE is not set" >> "./target/linux/generic/config-6.12"
	fi
# for 2410 ipq
	if [ "$SFE_INPUT_STATUS" = "true" ] && [ "$Branch" = "24.10-nss-6.12" ]; then
		echo "# CONFIG_NF_CONNTRACK_CHAIN_EVENTS is not set" >> "./target/linux/generic/config-6.12"
		echo "# CONFIG_SHORTCUT_FE is not set" >> "./target/linux/generic/config-6.12"
	fi

	cd ../
}

function add_openwrt_kmods() {
	cd openwrt

	if [ "$Matrix_Target" == 'ramips-iptables' ] || [ "$Matrix_Target" == 'ramips-nftables' ]; then
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ramips
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ramips
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ramips
		make defconfig
	elif [ "$Matrix_Target" == 'ath79-iptables' ] || [ "$Matrix_Target" == 'ath79-nftables' ]; then
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ath79
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ath79
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ath79
		make defconfig
	elif [ "$Matrix_Target" == 'ipq-iptables' ] || [ "$Matrix_Target" == 'ipq-nftables' ]; then
		if [ "$Branch" = "24.10-nss-6.12" ]; then
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-6-12
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-6-12
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-6-12
		make defconfig
		else
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ipq-nss
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ipq-nss
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-ipq-nss
		make defconfig
		fi
	elif [ "$TEST_KERNEL" = "1" ] || [ "$Branch" = "24.10-nss-6.12" ]; then
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-6-12
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-6-12
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod-6-12
		make defconfig
	else
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod
		make defconfig
		$GITHUB_WORKSPACE/$DIY_SH_RFC kmod
		make defconfig
	fi

	"$GITHUB_WORKSPACE/$DIY_SH_RFC" "$Matrix_Target"
	cd ../
}

function move_openwrt_config_ready() {
	[ -e package-configs ] && mv package-configs openwrt/package-configs
	[ -e machine-configs/$Matrix_Target.config ] && mv -f machine-configs/$Matrix_Target.config openwrt/package-configs/.config
}


function fix_openwrt_nss_sfe_feeds() {
	if [ "$SFE_INPUT_STATUS" = "true" ]; then
		sed -i '/CONFIG_NF_CONNTRACK_EVENTS=y/ a\
		CONFIG_NF_CONNTRACK_CHAIN_EVENTS=y \\' openwrt/feeds/nss_packages/qca-nss-ecm/Makefile
		rm -rf openwrt/feeds/nss_packages/qca-nss-ecm/patches/0006-treewide-rework-notifier-changes-for-5.15.patch
    fi
}

function fix_openwrt_feeds() {
	if [ "$OpenWrt_PATCH_FILE_DIR" = "openwrt-2410" ]; then
	[ -d $OpenWrt_PATCH_FILE_DIR/lunatic7-revert ] && mv -f $OpenWrt_PATCH_FILE_DIR/lunatic7-revert openwrt/feeds/lunatic7/lunatic7-revert
	[ -d $OpenWrt_PATCH_FILE_DIR/luci-patch-2410 ] && mv -f $OpenWrt_PATCH_FILE_DIR/luci-patch-2410 openwrt/feeds/luci/luci-patch-2410
	[ -d $OpenWrt_PATCH_FILE_DIR/feeds-package-patch-2410 ] && mv -f $OpenWrt_PATCH_FILE_DIR/feeds-package-patch-2410 openwrt/feeds/packages/feeds-package-patch-2410
	fi
	if [ "$OpenWrt_PATCH_FILE_DIR" = "openwrt-ipq" ]; then
	[ -d $OpenWrt_PATCH_FILE_DIR/lunatic7-revert ] && mv -f $OpenWrt_PATCH_FILE_DIR/lunatic7-revert openwrt/feeds/lunatic7/lunatic7-revert
	[ -d $OpenWrt_PATCH_FILE_DIR/luci-patch-openwrt-ipq ] && mv -f $OpenWrt_PATCH_FILE_DIR/luci-patch-openwrt-ipq openwrt/feeds/luci/luci-patch-openwrt-ipq
	[ -d $OpenWrt_PATCH_FILE_DIR/feeds-package-patch-openwrt-ipq ] && mv -f $OpenWrt_PATCH_FILE_DIR/feeds-package-patch-openwrt-ipq openwrt/feeds/packages/feeds-package-patch-openwrt-ipq
	fi

	cd openwrt
	"$GITHUB_WORKSPACE/$DIY_SH"  "$Matrix_Target"
	cd ../
}

function refine_openwrt_config() {
	cd openwrt
	IFS=',' read -r -a package_array <<< "$INPUT_PKGS_CFG_FOO"
	for pkg in "${package_array[@]}"; do
		./scripts/feeds install "$pkg"

		if [ "$INPUT_PKGS_CFG_STATUS" = "y" ]; then
			echo "CONFIG_PACKAGE_$pkg=y" >> .config
			echo "$pkg Added ..."
		elif [ "$INPUT_PKGS_CFG_STATUS" = "m" ]; then
			echo "CONFIG_PACKAGE_$pkg=m" >> .config
			echo "$pkg Marked ..."
		elif [ "$INPUT_PKGS_CFG_STATUS" = "n" ]; then
			echo "CONFIG_PACKAGE_$pkg=n" >> .config
			echo "$pkg Remove ..."
		fi
	done

	make defconfig

	for pkg in "${package_array[@]}"; do
		awk -v pkg="$pkg" '\$0 ~ pkg { print }' .config
	done

	"$GITHUB_WORKSPACE/$DIY_SH_RFC" "$Matrix_Target"
	cd ../
}

function awk_openwrt_config() {
	echo "------------------------"
	awk '/CONFIG_LINUX/ { print }' .config
	awk '/'"$Matrix_Target"'/ { print }' .config
	echo "------------------------"
	awk '/'"$Target_CFG_Machine"'/ { print }' .config
	echo "------------------------"
	awk '/mediatek/ { print }' .config
	echo "------------------------"
	awk '/wpad/ { print }' .config
	echo "------------------------"
	awk '/docker/ { print }' .config
	echo "------------------------"
	awk '/DOCKER/ { print }' .config
	echo "------------------------"
	awk '/store/ { print }' .config
	echo "------------------------"
	awk '/perl/ { print }' .config
	echo "------------------------"
	awk '/dnsmasq/ { print }' .config
	echo "------------------------"
	awk '/CONFIG_PACKAGE_kmod/ { print }' .config
	echo "------------------------"
	awk '/mt7981/ { print }' .config
	echo "------------------------"
	awk '/turboacc/ { print }' .config
}



if [ "$1" == "init-pkg-env" ]; then
init_pkg_env
elif [ "$1" == "init-gh-env-2410" ]; then
init_gh_env_2410
config_json_input_set
patch_json_input_set
init_gh_env_common
elif [ "$1" == "init-gh-env-2410-ipq" ]; then
init_gh_env_2410_ipq
config_json_input_set
patch_json_input_set
init_gh_env_common
elif [ "$1" == "init-math-config" ]; then
init_math_config
elif [ "$1" == "init-openwrt-pkg-config" ]; then
init_openwrt_pkg_config
elif [ "$1" == "init-openwrt-pkg-config-nss" ]; then
init_openwrt_pkg_config_nss
elif [ "$1" == "init-openwrt-patch-2410" ]; then
init_openwrt_patch_common
init_openwrt_patch_2410
elif [ "$1" == "init-openwrt-patch-2410-ipq" ]; then
init_openwrt_patch_common
init_openwrt_patch_2410_ipq
elif [ "$1" == "ln-openwrt" ]; then
ln_openwrt
elif [ "$1" == "add-openwrt-sfe-2410" ]; then
add_openwrt_sfe_ipt_k66
add_openwrt_sfe_nft_k66
add_openwrt_sfe_kernel_k612
add_openwrt_sfe_kmods
elif [ "$1" == "add-openwrt-sfe-2410-ipq" ]; then
add_openwrt_sfe_ipt_k66
add_openwrt_sfe_nft_k66
add_openwrt_sfe_kernel_k612
add_openwrt_sfe_kmods
add_openwrt_sfe_kernel_nss_patch
elif [ "$1" == "add-openwrt-nosfe-2410-ipq" ]; then
add_openwrt_sfe_nss_pkgs
elif [ "$1" == "add-openwrt-files-2410" ]; then
add_openwrt_files
patch_openwrt_core_pre
elif [ "$1" == "add-openwrt-kmods" ]; then
add_openwrt_kmods
elif [ "$1" == "fix-openwrt-feeds" ]; then
fix_openwrt_nss_sfe_feeds
move_openwrt_config_ready
fix_openwrt_feeds
refine_openwrt_config
elif [ "$1" == "awk-openwrt-config" ]; then
awk_openwrt_config
else
echo "Invalid argument"
fi
