## shallow clone for speed

REBAR_GIT_CLONE_OPTIONS += --depth 1
export REBAR_GIT_CLONE_OPTIONS

REBAR = $(CURDIR)/rebar3

REBAR_URL = https://s3.amazonaws.com/rebar3/rebar3

PROFILE ?= emqx
PROFILES := emqx emqx-edge
PKG_PROFILES := emqx-pkg emqx-edge-pkg

export EMQX_DEPS_DEFAULT_VSN ?= $(shell ./get_lastest_tag.escript ref)
ifneq ($(shell echo $(EMQX_DEPS_DEFAULT_VSN) | grep -oE "^[ev0-9]+\.[0-9]+(\.[0-9]+)?"),)
	export PKG_VSN := $(patsubst v%,%,$(patsubst e%,%,$(EMQX_DEPS_DEFAULT_VSN)))
else
	export PKG_VSN := $(patsubst v%,%,$(shell ./get_lastest_tag.escript tag))
endif

CT_APPS := emqx \
           emqx_auth_clientid \
           emqx_auth_http \
           emqx_auth_jwt \
           emqx_auth_ldap \
           emqx_auth_mongo \
           emqx_auth_mysql \
           emqx_auth_pgsql \
           emqx_auth_redis \
           emqx_auth_username \
           emqx_auth_mnesia \
           emqx_sasl \
           emqx_coap \
           emqx_recon \
           emqx_dashboard \
           emqx_delayed_publish \
           emqx_lua_hook \
           emqx_lwm2m \
           emqx_management \
           emqx_retainer \
           emqx_sn \
           emqx_stomp \
           emqx_web_hook \
           emqx_bridge_mqtt \
           emqx_rule_engine \
           emqx_extension_hook \
           emqx_exproto

.PHONY: default
default: $(REBAR) $(PROFILE)

.PHONY: all
all: $(REBAR) $(PROFILES)

.PHONY: distclean
distclean: remove-build-meta-files
	@rm -rf _build
	@rm -rf _checkouts

.PHONY: distclean-deps
distclean-deps: remove-deps remove-build-meta-files

.PHONY: remove-deps
remove-deps:
	@rm -rf _build/$(PROFILE)/lib
	@rm -rf _build/$(PROFILE)/conf
	@rm -rf _build/$(PROFILE)/plugins

.PHONY: remove-build-meta-files
remove-build-meta-files:
	@rm -f data/app.*.config data/vm.*.args rebar.lock

.PHONY: $(PROFILES)
$(PROFILES:%=%): $(REBAR)
ifneq ($(OS),Windows_NT)
	@ln -snf _build/$(@)/lib ./_checkouts
endif
ifneq ($(shell echo $(@) |grep edge),)
	export EMQX_DESC="EMQ X Edge"
else
	export EMQX_DESC="EMQ X Broker"
endif
	$(REBAR) as $(@) release

.PHONY: $(PROFILES:%=build-%)
$(PROFILES:%=build-%): $(REBAR)
	$(REBAR) as $(@:build-%=%) compile

.PHONY: run $(PROFILES:%=run-%)
run: run-$(PROFILE)
$(PROFILES:%=run-%): $(REBAR)
ifneq ($(OS),Windows_NT)
	@ln -snf _build/$(@:run-%=%)/lib ./_checkouts
endif
	$(REBAR) as $(@:run-%=%) run

.PHONY: clean $(PROFILES:%=clean-%)
clean: $(PROFILES:%=clean-%)
$(PROFILES:%=clean-%): $(REBAR)
	@rm -rf _build/$(@:clean-%=%)
	@rm -rf _build/$(@:clean-%=%)+test

.PHONY: $(PROFILES:%=checkout-%)
$(PROFILES:%=checkout-%): $(REBAR) build-$(PROFILE)
	ln -s -f _build/$(@:checkout-%=%)/lib ./_checkouts

# Checkout current profile
.PHONY: checkout
checkout:
	@ln -s -f _build/$(PROFILE)/lib ./_checkouts

# Run ct for an app in current profile
.PHONY: $(REBAR) $(CT_APPS:%=ct-%)
ct: $(CT_APPS:%=ct-%)
$(CT_APPS:%=ct-%): checkout-$(PROFILE)
	-make -C _build/emqx/lib/$(@:ct-%=%) ct
	@mkdir -p tests/logs/$(@:ct-%=%)
	@if [ -d _build/emqx/lib/$(@:ct-%=%)/_build/test/logs ]; then cp -r _build/emqx/lib/$(@:ct-%=%)/_build/test/logs/* tests/logs/$(@:ct-%=%); fi

$(REBAR):
ifneq ($(wildcard rebar3),rebar3)
	@curl -Lo rebar3 $(REBAR_URL) || wget $(REBAR_URL)
endif
	@chmod a+x rebar3

.PHONY: deps-all
deps-all: $(REBAR) $(PROFILES:%=deps-%) $(PKG_PROFILES:%=deps-%)

.PHONY: $(PROFILES:%=deps-%) $(PKG_PROFILES:%=deps-%)
$(PROFILES:%=deps-%) $(PKG_PROFILES:%=deps-%): $(REBAR)
ifneq ($(shell echo $(@) |grep edge),)
	export EMQX_DESC="EMQ X Edge"
else
	export EMQX_DESC="EMQ X Broker"
endif
	$(REBAR) as $(@:deps-%=%) get-deps

include deploy/packages/packages.mk
include deploy/docker/docker.mk
