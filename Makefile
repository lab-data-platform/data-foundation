SHELL := /bin/bash

REPO        := foundation
PLATFORM    ?= lab-data
ENV         ?= dev
AWS_PROFILE ?= lab-data
AWS_REGION  ?= us-east-2
export AWS_PROFILE

# Avaliado só quando usado (=), para não chamar a AWS em todo `make`.
# O $(shell) não herda o `export` do Makefile, por isso o profile vai explícito.
ACCOUNT_ID   = $(shell AWS_PROFILE=$(AWS_PROFILE) aws sts get-caller-identity --query Account --output text)
STATE_BUCKET = $(PLATFORM)-tfstate-$(ACCOUNT_ID)

.DEFAULT_GOAL := help

.PHONY: help whoami fmt validate test \
        bootstrap-init bootstrap-plan bootstrap-apply \
        init plan apply destroy

help: ## Lista os comandos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

whoami: ## Mostra com qual identidade AWS os comandos vão rodar
	@aws sts get-caller-identity --query Arn --output text

# --- Qualidade (local, sem AWS) ----------------------------------------------

fmt: ## Formata o código Terraform
	terraform fmt -recursive .

validate: ## Valida a sintaxe dos dois stacks
	@for d in bootstrap infra; do \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null && \
		terraform -chdir=$$d validate || exit 1; \
	done

test: ## Roda os testes unitários (provider simulado, sem AWS)
	@for d in bootstrap infra; do \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null && \
		terraform -chdir=$$d test || exit 1; \
	done

# --- Bootstrap: bucket do state de todos os repositórios (roda uma vez) ------

bootstrap-init: ## Inicializa o bootstrap
	terraform -chdir=bootstrap init

bootstrap-plan: bootstrap-init ## Mostra o que o bootstrap vai criar
	terraform -chdir=bootstrap plan

bootstrap-apply: bootstrap-init ## Cria o bucket do state remoto
	terraform -chdir=bootstrap apply

# --- Stack principal (infra/) ------------------------------------------------

init: ## Inicializa o stack com o backend remoto no S3
	terraform -chdir=infra init -reconfigure \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="key=$(REPO)/$(ENV)/terraform.tfstate" \
		-backend-config="region=$(AWS_REGION)" \
		-backend-config="profile=$(AWS_PROFILE)"

plan: ## Mostra as mudanças
	terraform -chdir=infra plan -var="environment=$(ENV)"

apply: ## Aplica as mudanças
	terraform -chdir=infra apply -var="environment=$(ENV)"

destroy: ## Destrói o stack (não apaga o bucket de state)
	terraform -chdir=infra destroy -var="environment=$(ENV)"
