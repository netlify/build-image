# get's the major version out of a string
get_major_version() {
  local version=$1
  # The sed replaces all non alphanumeric values if a version starts with `v1.3.0` it should provide `1.4.0`
  echo $(cut -d '.' -f 1 <<< "$version" | sed "s/[^[:digit:].-]//g")
}

NODE_VERSION="14.19.0"

# corepack was packported to 14.19.0
dpkg --compare-versions "$NODE_VERSION" "ge" "14.19.0"

if [ $? -eq 0 ]; then
  # corepack was added in 16.9.0 and packported to 14.19.0
  dpkg --compare-versions "$NODE_VERSION" "ge" "16.9.0"
  if [ $? -eq 0 ] || [ "$(get_major_version $NODE_VERSION)" == "14" ]; then
    echo "yea coprepack enable"

  fi
fi
