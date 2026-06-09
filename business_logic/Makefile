ENV ?= dev
FUNCTION_NAME ?= ssdp-trigger-ingestion-$(ENV)

HANDLERS := trigger_ingestion

.PHONY: $(HANDLERS) publish-all

trigger_ingestion:
	cd trigger_ingestion && \
		zip -j handler.zip handler.py && \
		aws lambda update-function-code \
			--function-name $(FUNCTION_NAME) \
			--zip-file fileb://handler.zip

publish-all: $(HANDLERS)