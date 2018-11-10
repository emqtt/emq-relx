PROJECT = emqx-rel
PROJECT_DESCRIPTION = Release Project for EMQ X Broker
PROJECT_VERSION = 3.0

DEPS += emqx emqx_retainer emqx_recon emqx_reloader emqx_dashboard emqx_management \
		emqx_auth_clientid emqx_auth_username emqx_auth_ldap emqx_auth_http \
        emqx_auth_mysql emqx_auth_pgsql emqx_auth_redis emqx_auth_mongo \
        emqx_sn emqx_coap emqx_lwm2m emqx_stomp emqx_plugin_template emqx_web_hook \
        emqx_auth_jwt emqx_statsd emqx_delayed_publish emqx_lua_hook

## This is either a tag or branch name for ALL dependencies
VSN ?= v3.0-rc.3

# emqx and plugins
dep_emqx                 = git https://github.com/emqx/emqx $(VSN)
dep_emqx_retainer        = git https://github.com/emqx/emqx-retainer $(VSN)
dep_emqx_recon           = git https://github.com/emqx/emqx-recon $(VSN)
dep_emqx_reloader        = git https://github.com/emqx/emqx-reloader $(VSN)
dep_emqx_dashboard       = git https://github.com/emqx/emqx-dashboard $(VSN)
dep_emqx_management      = git https://github.com/emqx/emqx-management $(VSN)
dep_emqx_statsd          = git https://github.com/emqx/emqx-statsd $(VSN)
dep_emqx_delayed_publish = git https://github.com/emqx/emqx-delayed-publish $(VSN)

# emq auth/acl plugins
dep_emqx_auth_clientid = git https://github.com/emqx/emqx-auth-clientid $(VSN)
dep_emqx_auth_username = git https://github.com/emqx/emqx-auth-username $(VSN)
dep_emqx_auth_ldap     = git https://github.com/emqx/emqx-auth-ldap $(VSN)
dep_emqx_auth_http     = git https://github.com/emqx/emqx-auth-http $(VSN)
dep_emqx_auth_mysql    = git https://github.com/emqx/emqx-auth-mysql $(VSN)
dep_emqx_auth_pgsql    = git https://github.com/emqx/emqx-auth-pgsql $(VSN)
dep_emqx_auth_redis    = git https://github.com/emqx/emqx-auth-redis $(VSN)
dep_emqx_auth_mongo    = git https://github.com/emqx/emqx-auth-mongo $(VSN)
dep_emqx_auth_jwt      = git https://github.com/emqx/emqx-auth-jwt $(VSN)

# mqtt-sn, coap and stomp
dep_emqx_sn    = git https://github.com/emqx/emqx-sn $(VSN)
dep_emqx_coap  = git https://github.com/emqx/emqx-coap $(VSN)
dep_emqx_lwm2m = git https://github.com/emqx/emqx-lwm2m $(VSN)
dep_emqx_stomp = git https://github.com/emqx/emqx-stomp $(VSN)

# plugin template
dep_emqx_plugin_template = git https://github.com/emqx/emq-plugin-template $(VSN)

# web_hook
dep_emqx_web_hook  = git https://github.com/emqx/emqx-web-hook $(VSN)
dep_emqx_lua_hook  = git https://github.com/emqx/emqx-lua-hook $(VSN)

# Add this dependency before including erlang.mk
all:: OTP_21_OR_NEWER

# COVER = true
include erlang.mk

# Fail fast in case older than OTP 21
.PHONY: OTP_21_OR_NEWER
OTP_21_OR_NEWER:
	@erl -noshell -eval "R = list_to_integer(erlang:system_info(otp_release)), halt(if R >= 21 -> 0; true -> 1 end)"

# Compile options
ERLC_OPTS += +warn_export_all +warn_missing_spec +warn_untyped_record

plugins:
	@rm -rf rel
	@mkdir -p rel/conf/plugins/ rel/schema/
	@for conf in $(DEPS_DIR)/*/etc/*.conf* ; do \
		if [ "emqx.conf" = "$${conf##*/}" ] ; then \
			cp $${conf} rel/conf/ ; \
		elif [ "acl.conf" = "$${conf##*/}" ] ; then \
			cp $${conf} rel/conf/ ; \
		elif [ "ssl_dist.conf" = "$${conf##*/}" ] ; then \
			cp $${conf} rel/conf/ ; \
		else \
			cp $${conf} rel/conf/plugins ; \
		fi ; \
	done
	@for schema in $(DEPS_DIR)/*/priv/*.schema ; do \
		cp $${schema} rel/schema/ ; \
	done

app:: plugins
