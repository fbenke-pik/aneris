.DEFAULT_GOAL := help

CI_DIR=./ci
CI_ENVIRONMENT_CONDA_DEFAULT_FILE=$(CI_DIR)/environment-conda-default.yml
CI_ENVIRONMENT_CONDA_FORGE_FILE=$(CI_DIR)/environment-conda-forge.yml

ENVIRONMENT_DOC_FILE=doc/environment.yml

ifndef CONDA_PREFIX
$(error Conda not active, please install conda and then activate it using \`conda activate\`))
else
ifeq ($(CONDA_DEFAULT_ENV),base)
$(error Do not install to conda base environment. Source a different conda environment e.g. \`conda activate aneris\` or \`conda create --name aneris python=3.7\` and rerun make))
endif
VENV_DIR=$(CONDA_PREFIX)
endif

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([\$$\(\)a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT


help:  ## print short description of each target
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)


.PHONY: clean  ## clean all build artifacts
clean:
	rm -rf build dist *egg-info __pycache__

.PHONY: new-release
new-release:  ## make a new release of aneris
	@echo 'For a new release on PyPI:'
	@echo 'git tag vX.Y.Z'
	@echo 'make publish-on-pypi'

# first time setup, follow the 'Register for PyPI' section in this
# https://blog.jetbrains.com/pycharm/2017/05/how-to-publish-your-package-on-pypi/
# then this works
.PHONY: publish-on-testpypi
publish-on-testpypi: $(VENV_DIR)  ## publish release on test PyPI
	-rm -rf build dist
	@status=$$(git status --porcelain); \
	if test "x$${status}" = x; then \
		$(VENV_DIR)/bin/python setup.py bdist_wheel --universal; \
		$(VENV_DIR)/bin/twine upload -r testpypi dist/*; \
	else \
		echo Working directory is dirty >&2; \
		echo run git status --porcelain to find dirty files >&2; \
	fi;

.PHONY: publish-on-pypi
publish-on-pypi: $(VENV_DIR)  ## publish release on PyPI
	-rm -rf build dist
	@status=$$(git status --porcelain); \
	if test "x$${status}" = x; then \
		$(VENV_DIR)/bin/python setup.py bdist_wheel --universal; \
		$(VENV_DIR)/bin/twine upload dist/*; \
	else \
		echo Working directory is dirty >&2; \
		echo run git status --porcelain to find dirty files >&2; \
	fi;

.PHONY: ci_dl
ci_dl: $(VENV_DIR)  ## run all the tests
	cd tests/ci; python download_data.py

.PHONY: test
test: $(VENV_DIR)  ## run all the tests
	$(VENV_DIR)/bin/pytest tests --cov=aneris --cov-config $(CI_DIR)/.coveragerc -r a --cov-report term-missing

.PHONY: install
install: $(VENV_DIR)  ## install aneris in virtual env
	$(VENV_DIR)/bin/python setup.py install

.PHONY: docs
docs: $(VENV_DIR)  ## make the docs
	cd doc; make html

.PHONY: virtual-environment
virtual-environment: $(VENV_DIR)  ## make virtual environment for development

$(VENV_DIR):  setup.py $(CI_ENVIRONMENT_CONDA_DEFAULT_FILE) $(CI_ENVIRONMENT_CONDA_FORGE_FILE) $(ENVIRONMENT_DOC_FILE)
	$(CONDA_EXE) config --add channels conda-forge # sets conda-forge as highest priority
	# install requirements
	$(CONDA_EXE) env update --name $(CONDA_DEFAULT_ENV) --file $(CI_ENVIRONMENT_CONDA_DEFAULT_FILE)
	$(CONDA_EXE) env update --name $(CONDA_DEFAULT_ENV) --file $(CI_ENVIRONMENT_CONDA_FORGE_FILE)
	$(CONDA_EXE) env update --name $(CONDA_DEFAULT_ENV) --file $(ENVIRONMENT_DOC_FILE)
	# Install development setup
	$(VENV_DIR)/bin/pip install -e .[tests,deploy,units]
	touch $(VENV_DIR)

.PHONY: release-on-conda
release-on-conda:  ## release aneris on conda
	@echo 'For now, this is all very manual'
	@echo 'Checklist:'
	@echo '- version number'
	@echo '- sha'
	@echo '- README.md badge'
	@echo '- release notes up to date'
