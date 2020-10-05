# Project config variables
SITE_NAME := devops-directive
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

.PHONY: build-site
build-site:
	HUGO_ENV=production hugo

.PHONY: run-hugo-server
run-hugo-server:
	hugo server -D

### GCS

create-bucket:
	gsutil mb -p $(PROJECT_ID) -b on gs://$(DOMAIN)
	gsutil web set -m index.html -e 404.html gs://$(DOMAIN)
	gsutil iam ch allUsers:legacyObjectReader gs://$(DOMAIN)

rsync-site:
	gsutil -m -h "Cache-Control:no-cache, max-age=0" rsync -d -r public gs://$(DOMAIN)
