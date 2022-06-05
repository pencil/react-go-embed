.PHONY: \
	build \
	clean \
	run \
	_

export CGO_ENABLED=0

clean:
	@echo "Cleaning..."
	rm -rf ./build
	rm -rf ./_ui/build

build: _ui/build build/server

build/server:
	@echo "Building server..."
	mkdir -p build
	go build -ldflags '-extldflags "-static"' -tags timetzdata -o build/server ./cmd/server/main.go

_ui/node_modules:
	@echo "Installing node modules..."
	cd _ui && npm install

_ui/build: _ui/node_modules
	@echo "Building UI..."
	cd _ui && npm run build

run: _ui/build
	@echo "Running..."
	go run ./cmd/server/main.go
