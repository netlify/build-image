# Usage: test-tools/test-build.sh PATH_TO_GIT_REPO BUILD_COMMAND
#
# Example with clean git clone:
#   test-tools/test-build.sh ../netlify-cms 'npm run build'
#
# Example with previous cached build:
#   T=/tmp/cache script/test-build.sh ../netlify-cms 'npm run build'

$NETLIFY_IMAGE="seanlify"
$NODE_VERSION="10"
$RUBY_VERSION="2.6.2"
$YARN_VERSION="1.13.0"
$NPM_VERSION=""
$HUGO_VERSION="0.54.0"
$PHP_VERSION="5.6"
$GO_VERSION="1.12"
$SWIFT_VERSION="5.2"

$tempDirectory = New-Item -ItemType Directory -Path 'tmp' -Force

$EnteredPath = $args[0]
$EnteredCommand = $args[1]

$BASE_PATH=$(pwd)
$REPO_PATH="$(cd $EnteredPath ; pwd)"

Write-Host "BASE_PATH: $BASE_PATH"
Write-Host "REPO_PATH: $REPO_PATH"


$T=$tempDirectory

Write-Host "Using temp cache dir: $T\cache"

$SCRIPT="/usr/local/bin/build " + $EnteredCommand
Write-Host "SCRIPT: $SCRIPT"

docker run --rm `
       -e NODE_VERSION `
       -e RUBY_VERSION `
       -e YARN_VERSION `
       -e NPM_VERSION `
       -e HUGO_VERSION `
       -e PHP_VERSION `
       -e NETLIFY_VERBOSE `
       -e GO_VERSION `
       -e GO_IMPORT_PATH `
       -e SWIFT_VERSION `
       -v "${REPO_PATH}:/opt/repo" `
       -v $T/cache:/opt/buildhome/cache `
       -w /opt/build `
       -it `
       $NETLIFY_IMAGE $SCRIPT
