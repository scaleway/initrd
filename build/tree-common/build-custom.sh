einfo "Building with custom method"

build_method_url=$(get_any build_method_url)
[ -z "$build_method_url" ] && die "No url to get the custom build method provided"
build_method_scripts_dir=$(mktemp -d)
einfo "Retrieving custom build method"
run --abort wget -O $build_method_scripts_dir/method.sh $build_method_url

einfo "Sourcing custom build method"
. $build_method_scripts_dir/method.sh
