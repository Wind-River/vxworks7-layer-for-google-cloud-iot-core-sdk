# Copyright (c) 2019, Wind River Systems, Inc.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# 3) Neither the name of Wind River Systems nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

.PHONY: default

include common.mak

ADDED_LIBS += -lunix -lnet -lHASH -lOPENSSL
ADDED_CFLAGS += -isystem${VSB_DIR}/usr/h/published/UTILS
MAKE_OPT += IOTC_BSP_PLATFORM=posix
MAKE_OPT += IOTC_BSP_TLS=mbedtls
MAKE_OPT += MAKEFILE_DEBUG=1
MAKE_OPT += IOTC_TARGET_PLATFORM=vxworks
MAKE_OPT += IOTC_C_FLAGS="$$CFLAGS $$CPPFLAGS "
MAKE_OPT += IOTC_LIB_FLAGS="$$LDFLAGS "
MAKE_OPT += IOTC_HOST_PLATFORM=Linux
MAKE_OPT += MD=

INCLUDE_MBEDTLS=n

include defs.packages.mk
include defs.crossbuild.mk
include rules.packages.mk

default: $(AUTO_INCLUDE_VSB_CONFIG_QUOTE) $(__AUTO_INCLUDE_LIST_UFILE) | $(TOOL_OPTIONS_FILES_ALL)

$(PKG_NAME).build : $(PKG_NAME).configure
	@$(call echo_action,Building,$(PKG_NAME))
	if [ -n "$(VXWORKS_ENV_SH)" ] && \
	   [ -f $(VXWORKS_ENV_SH) ]; then \
		. ./$(VXWORKS_ENV_SH); \
	fi ; \
	$(call pkg_build,$(PKG_NAME))
	@$(MAKE_STAMP)

$(PKG_NAME).configure : $(CONFIGURE_DEPENDS) $(PKG_NAME).patch
	@$(call echo_action,Configuring,$(PKG_NAME))
	sed -i -e 's/\[\[ ! \$$REPLY =~ ^\[Yy\]\$$ \]\]/[ "$$REPLY" != "Y" ] \&\& [ "$$REPLY" != "y" ]/' $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/res/tls/build_*.sh
	sed -i -e 's/^read \(.*\)/REPLY=$(INCLUDE_MBEDTLS)/' $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/res/tls/build_*.sh
	sed -i -e 's/echo "exiting build."/echo "Please set INCLUDE_MBEDTLS=y in vxworks.mak to confirm that you wish to download mbedTLS."/' $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/res/tls/build_mbedtls.sh
	sed -i -e 's/^cd mbedtls$$/cd mbedtls; test ! -f applied_patches \&\& patch -p1 < ..\/..\/..\/mbedtls_vxworks.diff \&\& echo mbedtls_vxworks.diff > applied_patches/' $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/res/tls/build_*.sh
	sed -i -e 's/make CFLAGS="-O2 -DMBEDTLS_PLATFORM_MEMORY $$1"/. ..\/..\/..\/$(VXWORKS_ENV_SH); make CFLAGS="\$$CFLAGS \$$CPPFLAGS -DMBEDTLS_PLATFORM_MEMORY" VERBOSE=1 lib || exit 1/' $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/res/tls/build_*.sh
	@$(MAKE_STAMP)

$(PKG_NAME).install : $(PKG_NAME).build
	@$(call echo_action,Installing,$(PKG_NAME))
	cp $(VSBL_SRC_DIR)/$(PKG_BUILD_DIR)/bin/vxworks/libiotc.a $(VSB_DIR)/usr/lib/common
	cp $(VSBL_SRC_DIR)/$(PKG_BUILD_DIR)/third_party/tls/mbedtls/library/libmbedcrypto.a $(VSB_DIR)/usr/lib/common
	cp $(VSBL_SRC_DIR)/$(PKG_BUILD_DIR)/third_party/tls/mbedtls/library/libmbedtls.a $(VSB_DIR)/usr/lib/common
	cp $(VSBL_SRC_DIR)/$(PKG_BUILD_DIR)/third_party/tls/mbedtls/library/libmbedx509.a $(VSB_DIR)/usr/lib/common
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc_connection_data.h $(VSB_DIR)/usr/h/public
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc_error.h $(VSB_DIR)/usr/h/public
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc.h $(VSB_DIR)/usr/h/public
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc_jwt.h $(VSB_DIR)/usr/h/public
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc_mqtt.h $(VSB_DIR)/usr/h/public
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc_time.h $(VSB_DIR)/usr/h/public
	cp $(VSBL_SRC_DIR)/$(PKG_SRC_DIR)/include/iotc_types.h $(VSB_DIR)/usr/h/public
	@$(MAKE_STAMP)
