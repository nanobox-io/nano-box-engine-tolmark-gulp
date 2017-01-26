# -*- mode: bash; tab-width: 2; -*-
# vim: ts=2 sw=2 ft=bash noet

# Copy the code into the live directory which will be used to run the app
publish_release() {
  nos_print_bullet "Moving build into live code directory..."
	rsync -a $(nos_code_dir)/rel/ $(nos_app_dir)
}

# Determine the nodejs runtime to install. This will first check
# within the Boxfile, then will rely on default_runtime to
# provide a sensible default
nodejs_runtime() {
  echo $(nos_validate \
    "$(nos_payload "config_nodejs_runtime")" \
    "string" "$(nodejs_default_runtime)")
}

# Provide a default nodejs version.
nodejs_default_runtime() {
  packagejs_runtime=$(package_json_runtime)

  if [[ "$packagejs_runtime" = "false" ]]; then
    echo "nodejs-4"
  else
    echo $packagejs_runtime
  fi
}

# todo: extract the contents of package.json
#   Will need https://stedolan.github.io/jq/
#   https://github.com/heroku/heroku-buildpack-nodejs/blob/master/lib/json.sh#L17
#   https://github.com/heroku/heroku-buildpack-nodejs/blob/master/bin/compile#L73
package_json_runtime() {
  echo "false"
}

# Determine which dependency manager to use (yarn/npm)
dep_manager() {
  echo $(nos_validate \
    "$(nos_payload "config_dep_manager")" \
    "string" "$(default_dep_manager)")
}

# Use yarn as the default dep manager
default_dep_manager() {
  # todo: probably need to revert to npm if using an old version
  echo "yarn"
}

# Install the node runtime along with any dependencies.
install_runtime_packages() {
  pkgs=("nginx" "python-2.7" "$(nodejs_runtime)")

  nos_install ${pkgs[@]}
}

# Uninstall build dependencies
uninstall_build_packages() {
  pkgs=("$(nodejs_runtime)" "python-2.7")

  nos_uninstall ${pkgs[@]}
}

# set the runtime in a file inside of node_modules so that if the
# runtime changes between deploys, we can blast the node_modules
# cache and build fresh.
nodejs_persist_runtime() {
  if [[ -d $(nos_code_dir)/node_modules ]]; then
    echo "$(nodejs_runtime)" > $(nos_code_dir)/node_modules/runtime
  fi
}

# check the runtime that was set at the last deploy, and ensure it
# hasn't changed. If it has changed, we'll return false.
nodejs_check_runtime() {
  if [[ ! -d $(nos_code_dir)/node_modules ]]; then
    echo "true"
    return
  fi

  if [[ "$(cat $(nos_code_dir)/node_modules/runtime)" =~ ^$(nodejs_runtime)$ ]]; then
    echo "false"
  else
    echo "true"
  fi
}

# installs npm deps via yarn or npm
install_npm_deps() {
  # if yarn is available, let's use that
  if [[ "$(dep_manager)" = "yarn" ]]; then
    yarn_install
  else # fallback to npm (slow)
    npm_install
  fi
}

# install dependencies via yarn
yarn_install() {
  if [[ -f $(nos_code_dir)/package.json ]]; then

    cd $(nos_code_dir)
    nos_run_process "Installing npm modules" "yarn"
    cd - > /dev/null
  fi
}

# Installing dependencies from the package.json is done with npm install.
npm_install() {
  if [[ -f $(nos_code_dir)/package.json ]]; then

    cd $(nos_code_dir)
    nos_run_process "Installing npm modules" "npm install"
    cd - > /dev/null
  fi
}

# run bower install
bower_install() {
  cd $(nos_code_dir)
  nos_run_process "Installing bower components" "$(nos_code_dir)/node_modules/.bin/bower --config.analytics=false install"
  cd - > /dev/null
}

# generate gulp release
generate_rel() {
  cd $(nos_code_dir)
  nos_run_process "Generating release" "$(nos_code_dir)/node_modules/.bin/gulp rel"
  cd - > /dev/null
}

force_https() {
	echo $(nos_validate "$(nos_payload "config_force_https")" "boolean" "false")
}

error_pages() {
  declare -a error_pages_list
  if [[ "${PL_config_error_pages_type}" = "array" ]]; then
    for ((i=0; i < PL_config_error_pages_length ; i++)); do
      type=PL_config_error_pages_${i}_type
      if [[ ${!type} = "map" ]]; then
        errors=PL_config_error_pages_${i}_errors_value
        page=PL_config_error_pages_${i}_page_value
        if [[ -n ${!errors} && ${!page} ]]; then
          entry="{\"errors\":\"${!errors}\",\"page\":\"${!page}\"}"
          error_pages_list+=("${entry}")
        fi
      fi
    done
  fi
  if [[ -z "error_pages_list[@]" ]]; then
    echo "[]"
  else
    echo "[ $(nos_join ',' "${error_pages_list[@]}") ]"
  fi
}

rewrites() {
  declare -a rewrites_list
  if [[ "${PL_config_rewrites_type}" = "array" ]]; then
    for ((i=0; i < PL_config_rewrites_length ; i++)); do
      type=PL_config_rewrites_${i}_type
      if [[ ${!type} = "map" ]]; then
        rewrite_if=PL_config_rewrites_${i}_if_value
        rewrite_then=PL_config_rewrites_${i}_then_value
        if [[ -n ${!rewrite_if} && ${!rewrite_then} ]]; then
          entry="{\"if\":\"${!rewrite_if}\",\"then\":\"${!rewrite_then}\"}"
          rewrites_list+=("${entry}")
        fi
      fi
    done
  fi
  if [[ -z "rewrites_list[@]" ]]; then
    echo "[]"
  else
    echo "[ $(nos_join ',' "${rewrites_list[@]}") ]"
  fi
}

# Generate a payload to render the nginx conf
nginx_conf_payload() {
  cat <<-END
{
  "code_dir": "$(nos_code_dir)",
  "data_dir": "$(nos_data_dir)",
  "force_https": $(force_https),
  "error_pages": $(error_pages),
  "rewrites": $(rewrites)
}
END
}

# Generate an nginx conf
configure_nginx() {
	mkdir -p $(nos_data_dir)/var/tmp/nginx/client_body_temp
  nos_template \
    "nginx/nginx.conf" \
    "$(nos_etc_dir)/nginx/nginx.conf" \
    "$(nginx_conf_payload)"
}
