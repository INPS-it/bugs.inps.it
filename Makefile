clean:
	@find . -name "*.pyc" | xargs rm -rf
	@find . -name "*.pyo" | xargs rm -rf
	@find . -name "__pycache__" -type d | xargs rm -rf

run-dev: clean
	./scripts/local_dev_start.sh

prepare-test: clean
	./scripts/prepare-test.sh

test: clean
	./scripts/test.sh
