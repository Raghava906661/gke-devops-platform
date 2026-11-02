.DEFAULT_GOAL := help
IMAGE ?= pulse-api:local

.PHONY: help install lint fmt test run docker-build docker-run k8s-render tf-fmt tf-validate check

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

install: ## Create venv and install dev dependencies
	python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt

lint: ## Lint Python code
	ruff check app tests && ruff format --check app tests

fmt: ## Auto-format Python and Terraform
	ruff format app tests && terraform -chdir=terraform fmt -recursive

test: ## Run unit tests with coverage
	pytest --cov=app --cov-report=term-missing

run: ## Run the API locally with hot reload
	uvicorn app.main:app --reload --port 8080

docker-build: ## Build the container image
	docker build -t $(IMAGE) .

docker-run: ## Run the container like Kubernetes does (read-only FS, non-root)
	docker run --rm -p 8080:8080 --read-only --tmpfs /tmp $(IMAGE)

k8s-render: ## Render both Kustomize overlays
	kubectl kustomize k8s/overlays/dev && kubectl kustomize k8s/overlays/prod

tf-fmt: ## Check Terraform formatting
	terraform -chdir=terraform fmt -check -recursive

tf-validate: ## Validate Terraform without a backend
	terraform -chdir=terraform init -backend=false -input=false >/dev/null && terraform -chdir=terraform validate

check: lint test tf-fmt tf-validate ## Run all local checks
