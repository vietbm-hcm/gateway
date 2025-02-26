# This is a wrapper to do lint checks
#
# All make targets related to lint are defined in this file.

##@ Lint

GITHUB_ACTION ?=

.PHONY: lint
lint: ## Run all linter of code sources, including golint, yamllint, whitenoise lint and codespell.

PHONY: lint-deps
lint-deps: ## Everything necessary to lint (useful to separate out in the logs)

GOLANGCI_LINT_FLAGS ?= $(if $(GITHUB_ACTION),--out-format=github-actions)
.PHONY: lint.golint
lint: lint.golint
lint-deps: $(tools/golangci-lint)
lint.golint: $(tools/golangci-lint)
	@echo Running Go linter ...
	$(tools/golangci-lint) run $(GOLANGCI_LINT_FLAGS) --build-tags=e2e --config=tools/linter/golangci-lint/.golangci.yml

.PHONY: lint.yamllint
lint: lint.yamllint
lint-deps: $(tools/yamllint)
lint.yamllint: $(tools/yamllint)
	@echo Running YAML linter ...
	$(tools/yamllint) --config-file=tools/linter/yamllint/.yamllint $$(git ls-files :*.yml :*.yaml | xargs -L1 dirname | sort -u) 

CODESPELL_FLAGS ?= $(if $(GITHUB_ACTION),--disable-colors)
.PHONY: lint.codespell
lint: lint.codespell
lint-deps: $(tools/codespell)
lint.codespell: CODESPELL_SKIP := $(shell cat tools/linter/codespell/.codespell.skip | tr \\n ',')
lint.codespell: $(tools/codespell)
	@echo Running Codespell linter ...
# This ::add-matcher/::remove-matcher business is based on
# https://github.com/codespell-project/actions-codespell/blob/2292753ad350451611cafcbabc3abe387491339a/entrypoint.sh
# We do this here instead of just using
# codespell-project/codespell-problem-matcher@v1 so that the matcher
# doesn't apply to the other linters that `make lint` also runs.
#
# This recipe is written a little awkwardly with everything running in
# one shell, this is because we want the ::remove-matcher lines to get
# printed whether or not it finds complaints.
	@PS4=; set -e; { \
	  if test -n "$$GITHUB_ACTION"; then \
	    printf '::add-matcher::$(CURDIR)/tools/linter/codespell/matcher.json\n'; \
	    trap "printf '::remove-matcher owner=codespell-matcher-default::\n::remove-matcher owner=codespell-matcher-specified::\n'" EXIT; \
	  fi; \
	  (set -x; $(tools/codespell) $(CODESPELL_FLAGS) --skip $(CODESPELL_SKIP) --ignore-words tools/linter/codespell/.codespell.ignorewords --check-filenames --check-hidden -q2); \
	}

.PHONY: lint.whitenoise
lint: lint.whitenoise
lint-deps: $(tools/whitenoise)
lint.whitenoise: $(tools/whitenoise)
	@echo Running WhiteNoise linter ...
	$(tools/whitenoise)
