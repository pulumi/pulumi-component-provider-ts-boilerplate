VERSION         := 0.0.1

PACK            := xyz
PROJECT         := github.com/pulumi/pulumi-${PACK}

PROVIDER        := pulumi-resource-${PACK}
CODEGEN         := pulumi-gen-${PACK}
VERSION_PATH    := provider/pkg/version.Version

WORKING_DIR     := $(shell pwd)
SCHEMA_PATH     := ${WORKING_DIR}/schema.json

override target := "14.15.3"

build:: build_provider

install:: install_provider

# Ensure all dependencies are installed
ensure::
	yarn install

# Provider

build_provider:: ensure
	cp ${SCHEMA_PATH} provider/cmd/${PROVIDER}/
	pushd provider/cmd/${PROVIDER}/ && \
		yarn install && \
	popd && \
	rm -rf build && npx --package @vercel/ncc ncc build provider/cmd/${PROVIDER}/index.ts -o build && \
	sed -i.bak -e "s/\$${VERSION}/$(VERSION)/g" ./build/index.js && \
	rm ./build/index.js.bak && \
	rm -rf ./bin && mkdir bin && \
	npx nexe build/index.js -r build/schema.json -t $(target) -o bin/${PROVIDER}

install_provider:: build_provider

# builds all providers required for publishing
dist:: ensure
	pushd provider/cmd/${PROVIDER}/ && \
		yarn install && \
	popd && \
	rm -rf build && npx --package @vercel/ncc ncc build provider/cmd/${PROVIDER}/index.ts -o build && \
	sed -i.bak -e "s/\$${VERSION}/$(VERSION)/g" ./build/index.js && \
	rm ./build/index.js.bak && \
	rm -rf dist  && mkdir dist && \
	for TARGET in "darwin-amd64" "win-amd64" "linux-amd64"; do \
		rm -rf ./bin && mkdir bin && \
		npx nexe build/index.js -r build/schema.json -t "$${TARGET}-14.15.3" -o bin/${PROVIDER} && \
		tar -czvf "dist/$(PROVIDER)-v$(VERSION)-$${TARGET}.tar.gz" bin; \
	done
