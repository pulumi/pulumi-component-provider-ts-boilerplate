VERSION         := 0.0.1

PACK            := xyz
PROJECT         := github.com/pulumi/pulumi-${PACK}

PROVIDER        := pulumi-resource-${PACK}
CODEGEN         := pulumi-gen-${PACK}
VERSION_PATH    := provider/pkg/version.Version

WORKING_DIR     := $(shell pwd)
SCHEMA_PATH     := ${WORKING_DIR}/schema.json

generate:: gen_go_sdk gen_dotnet_sdk gen_nodejs_sdk gen_python_sdk

build:: build_provider build_dotnet_sdk build_nodejs_sdk build_python_sdk

install:: install_provider install_dotnet_sdk install_nodejs_sdk

# Ensure all dependencies are installed
ensure::
	yarn install

# Provider
build_provider:: ensure
	cp ${SCHEMA_PATH} provider/cmd/${PROVIDER}/
	cd provider/cmd/${PROVIDER}/ && \
       		yarn install && \
       		yarn tsc && \
       		cp package.json schema.json ./bin && \
       		sed -i.bak -e "s/\$${VERSION}/$(VERSION)/g" bin/package.json

install_provider:: PKG_ARGS := --no-bytecode --public-packages "*" --public
install_provider:: build_provider
	cd provider/cmd/${PROVIDER}/ && \
		yarn run pkg . ${PKG_ARGS} --target node16 --output ../../../bin/${PROVIDER}

# builds all providers required for publishing
dist:: PKG_ARGS := --no-bytecode --public-packages "*" --public
dist:: build_provider
	cd provider/cmd/${PROVIDER}/ && \
 		yarn run pkg . ${PKG_ARGS} --target node16-macos-x64 --output ../../../bin/darwin-amd64/${PROVIDER} && \
 		yarn run pkg . ${PKG_ARGS} --target node16-macos-arm64 --output ../../../bin/darwin-arm64/${PROVIDER} && \
 		yarn run pkg . ${PKG_ARGS} --target node16-linuxstatic-x64 --output ../../../bin/linux-amd64/${PROVIDER} && \
 		yarn run pkg . ${PKG_ARGS} --target node16-linuxstatic-arm64 --output ../../../bin/linux-arm64/${PROVIDER} && \
 		yarn run pkg . ${PKG_ARGS} --target node16-win-x64 --output ../../../bin/windows-amd64/${PROVIDER}.exe
	mkdir -p dist
	tar --gzip -cf ./dist/pulumi-resource-${PACK}-v${VERSION}-linux-amd64.tar.gz README.md LICENSE -C bin/linux-amd64/ .
	tar --gzip -cf ./dist/pulumi-resource-${PACK}-v${VERSION}-linux-arm64.tar.gz README.md LICENSE -C bin/linux-arm64/ .
	tar --gzip -cf ./dist/pulumi-resource-${PACK}-v${VERSION}-darwin-amd64.tar.gz README.md LICENSE -C bin/darwin-amd64/ .
	tar --gzip -cf ./dist/pulumi-resource-${PACK}-v${VERSION}-darwin-arm64.tar.gz README.md LICENSE -C bin/darwin-arm64/ .
	tar --gzip -cf ./dist/pulumi-resource-${PACK}-v${VERSION}-windows-amd64.tar.gz README.md LICENSE -C bin/windows-amd64/ .

# Go SDK

gen_go_sdk::
	rm -rf sdk/go
	cd provider/cmd/${CODEGEN} && go run . go ../../../sdk/go ${SCHEMA_PATH}

## Empty build target for Go
build_go_sdk::


# .NET SDK

gen_dotnet_sdk::
	rm -rf sdk/dotnet
	cd provider/cmd/${CODEGEN} && go run . dotnet ../../../sdk/dotnet ${SCHEMA_PATH}

build_dotnet_sdk:: DOTNET_VERSION := ${VERSION}
build_dotnet_sdk:: gen_dotnet_sdk
	cd sdk/dotnet/ && \
		echo "${DOTNET_VERSION}" >version.txt && \
		dotnet build /p:Version=${DOTNET_VERSION}

install_dotnet_sdk:: build_dotnet_sdk
	rm -rf ${WORKING_DIR}/nuget
	mkdir -p ${WORKING_DIR}/nuget
	find . -name '*.nupkg' -print -exec cp -p {} ${WORKING_DIR}/nuget \;


# Node.js SDK

gen_nodejs_sdk::
	rm -rf sdk/nodejs
	cd provider/cmd/${CODEGEN} && go run . nodejs ../../../sdk/nodejs ${SCHEMA_PATH}

build_nodejs_sdk:: gen_nodejs_sdk
	cd sdk/nodejs/ && \
		yarn install && \
		yarn run tsc --version && \
		yarn run tsc && \
		cp -R scripts/ bin && \
		cp ../../README.md ../../LICENSE package.json yarn.lock ./bin/ && \
		sed -i.bak -e "s/\$${VERSION}/$(VERSION)/g" ./bin/package.json && \
		rm ./bin/package.json.bak

install_nodejs_sdk:: build_nodejs_sdk
	yarn link --cwd ${WORKING_DIR}/sdk/nodejs/bin


# Python SDK

gen_python_sdk::
	rm -rf sdk/python
	cd provider/cmd/${CODEGEN} && go run . python ../../../sdk/python ${SCHEMA_PATH}
	cp ${WORKING_DIR}/README.md sdk/python

build_python_sdk:: PYPI_VERSION := ${VERSION}
build_python_sdk:: gen_python_sdk
	cd sdk/python/ && \
		python3 setup.py clean --all 2>/dev/null && \
		rm -rf ./bin/ ../python.bin/ && cp -R . ../python.bin && mv ../python.bin ./bin && \
		sed -i.bak -e "s/\$${VERSION}/${PYPI_VERSION}/g" -e "s/\$${PLUGIN_VERSION}/${VERSION}/g" ./bin/setup.py && \
		rm ./bin/setup.py.bak && \
		cd ./bin && python3 setup.py build sdist
