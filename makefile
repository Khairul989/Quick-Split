clean: ## Cleans the environment
	@echo "╠ Cleaning the project..."
	@rm -rf pubspec.lock
	@flutter clean
	@cd ios && rm -rf Pods Podfile.lock
	@flutter pub get

watch: ## Watches the files for changes
	@echo "╠ Watching the project..."
	@dart run build_runner watch --delete-conflicting-outputs

build_runner: ## Build the files for changes
	@dart run build_runner clean
	@echo "╠ Building the project..."
	@dart run build_runner clean
	@dart run build_runner build --delete-conflicting-outputs