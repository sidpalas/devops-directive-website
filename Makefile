# Project config variables
PROJECT_ID:=devops-directive-project
SITE_NAME:=devops-directive
DOMAIN:=devopsdirective.com

### Local Operations
.PHONY: create-site
create-site:
	hugo new site $(SITE_NAME)
	mv ./$(SITE_NAME)/* ./
	rm -r ./$(SITE_NAME)
	git init
	git submodule add https://github.com/budparr/gohugo-theme-ananke.git themes/ananke
	echo 'theme = "ananke"' >> config.toml
	hugo new posts/test-post.md

.PHONY: check-post-name
check-post-name:
ifndef POST_NAME
	$(error POST_NAME is undefined)
endif

POST_PATH=posts/$(shell date +%Y)/$(shell date +%m)/$(POST_NAME)

.PHONY: create-post
create-post: check-post-name
	hugo new $(POST_PATH)


.PHONY: create-dir-post 
create-dir-post: check-post-name
	hugo new -k=dir-post $(POST_PATH) 


.PHONY: build-site
build-site:
	HUGO_ENV=production hugo

.PHONY: run-hugo-server
run-hugo-server:
	hugo server -D --disableFastRender

### GCS

.PHONY: create-bucket
create-bucket:
	gsutil mb -p $(PROJECT_ID) -b on gs://$(DOMAIN)
	gsutil web set -m index.html -e 404.html gs://$(DOMAIN)
	gsutil iam ch allUsers:legacyObjectReader gs://$(DOMAIN)

.PHONY: rsync-site
rsync-site:
	gsutil -m rsync -d -r public gs://$(DOMAIN)

### GITPOD
run-hugo-server-gitpod:
	hugo server -D --disableFastRender --baseURL=$(shell gp url 1313) --appendPort=false
