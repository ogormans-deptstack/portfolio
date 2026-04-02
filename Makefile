.PHONY: dev deploy plan apply init fmt validate install bootstrap seed-secrets

dev:
	cd site && npm run dev

deploy:
	cd site && npm run deploy

init:
	cd infra && tofu init

plan:
	cd infra && tofu plan

apply:
	cd infra && tofu apply

fmt:
	cd infra && tofu fmt -recursive

validate:
	cd infra && tofu validate

install:
	cd site && npm install

bootstrap:
	./bootstrap.sh

seed-secrets:
	./seed-secrets.sh
