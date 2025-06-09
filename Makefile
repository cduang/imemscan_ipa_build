# 工具路径设置
TARGET_CODESIGN = $(shell which ldid)
TARGET_DPKG = $(shell which dpkg)

# 在 GitHub Actions 中使用不同的临时目录
ifneq (,$(GITHUB_ACTIONS))
    # GitHub Actions 环境
    APP_TMP = $(shell pwd)/build/iMemScan-build
    # 在 GitHub Actions 中自动安装 ldid
    ifeq (,$(TARGET_CODESIGN))
        CODESIGN_INSTALL = brew install ldid
    endif
else
    # 本地开发环境
    APP_TMP = $(TMPDIR)/iMemScan-build
endif

APP_BUNDLE_PATH = $(APP_TMP)/Build/Products/Release-iphoneos/iMemScan.app

# 默认目标
all: build

# 构建目标
build:
	@echo "Building iMemScan..."
	@mkdir -p $(APP_TMP)
	
	# 在 GitHub Actions 中安装必要的工具
	$(CODESIGN_INSTALL)
	
	# 构建项目
	xcodebuild -quiet \
		-project 'iMemScan.xcodeproj' \
		-scheme iMemScan \
		-configuration Release \
		-arch arm64 \
		-sdk iphoneos \
		-derivedDataPath $(APP_TMP) \
		CODE_SIGNING_ALLOWED=NO \
		DSTROOT=$(APP_TMP)/install

	# 确保构建目录存在
	@mkdir -p build/Payload

	# 复制应用包到 Payload 目录
	@cp -r $(APP_BUNDLE_PATH) build/Payload/

	# 签名应用（如果 ldid 可用）
	if [ -f "$(TARGET_CODESIGN)" ]; then \
		$(TARGET_CODESIGN) -Sentitlements.plist build/Payload/iMemScan.app/iMemScan; \
	fi

	# 创建 IPA 文件
	@echo "Creating IPA file..."
	@cd build && zip -r9 iMemScan.ipa Payload

	# 清理临时文件
	@rm -rf build/Payload
	@find . -name ".DS_Store" -delete

	@echo "\nBuild complete!"
	@echo "IPA file: build/iMemScan.ipa"

# 清理构建文件
clean:
	@rm -rf build
	@rm -rf Payload
	@rm -f iMemScan.ipa
	@rm -f iMemScanTS.tipa
