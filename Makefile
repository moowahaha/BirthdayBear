.PHONY: build serve deploy help

PROJECT ?=
SERVICE := birthday-bear
REGION  := us-central1

help:
	@echo "Targets:"
	@echo "  make build                       Build the docker image locally"
	@echo "  make serve                       Run the static container at http://localhost:8080"
	@echo "  make deploy PROJECT=<gcp-id>     Deploy to Cloud Run in the given project"

build:
	docker build -t $(SERVICE) .

serve: build
	docker run --rm -it -p 8080:8080 $(SERVICE)

deploy:
	@if [ -z "$(PROJECT)" ]; then \
		echo "PROJECT is required. Usage: make deploy PROJECT=your-gcp-project-id"; \
		exit 1; \
	fi
	gcloud run deploy $(SERVICE) \
		--source . \
		--project $(PROJECT) \
		--region $(REGION) \
		--allow-unauthenticated \
		--platform managed
