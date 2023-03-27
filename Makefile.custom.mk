##@ App

SHELL := /bin/bash

APPLICATION_NAME="cluster-api-provider-openstack"

# keep in sync with 
# * image tag in helm/cluster-api-provider-openstack/values.yaml
# * used capo-version in mc-bootstrap - defined in Makefile.custom.mk (https://github.com/giantswarm/mc-bootstrap/blob/main/Makefile.custom.mk)
CAPO_VERSION="v0.7.1"

.PHONY: all
all: fetch-upstream-manifest apply-kustomize-patches delete-generated-helm-charts release-manifests ## Builds the manifests to publish with a release (alias to release-manifests)

.PHONY: release-manifests
release-manifests: fetch-upstream-manifest apply-kustomize-patches delete-generated-helm-charts delete-generated-helm-charts ## Builds the manifests to publish with a release
	# move files from workdir over to helm directury structure
	./hack/prepare-helmchart.sh ${APPLICATION_NAME}

.PHONY: fetch-upstream-manifest
fetch-upstream-manifest: ## fetch upstream manifest from
	# fetch upstream released manifest yaml
	./hack/sync-version.sh ${CAPO_VERSION}

.PHONY: apply-kustomize-patches
apply-kustomize-patches: ## apply giantswarm specific patches
	kubectl kustomize config/kustomize -o config/kustomize/tmp

#.PHONY: delete-generated-helm-charts
delete-generated-helm-charts: # clean workspace and delete manifests
	@rm -rvf ./helm/${APPLICATION_NAME}/templates/*.yaml
	@rm -rvf ./helm/${APPLICATION_NAME}/crds/*.yaml

ensure-schema-gen:
	@helm schema-gen --help &>/dev/null || helm plugin install https://github.com/mihaisee/helm-schema-gen.git

.PHONY: schema-gen
schema-gen: ensure-schema-gen ## Generates the values schema file
	@cd helm/cluster-api-provider-openstack && helm schema-gen values.yaml > values.schema.json && git diff values.schema.json
