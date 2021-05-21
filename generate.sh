echo "::group::Init"

set -e

log () {
    echo `date +"%m/%d/%Y %H:%M:%S"` "$@"
}

cleanup() {
    rm -f filtrite >> /dev/null 2>&1
}

filtrite() {
    echo "::group::List: $1"
    log "Start generating $1"
    ./filtrite "lists/$1.txt" "logs/$1.dat" "logs/$1.log"
    sleep 5
    ./deps/ruleset_converter --input_format=unindexed-ruleset --output_format=filter-list --input_files="logs/$1.dat" --output_file="logs/$1_b1.txt" > "logs/$1_err2.log" 2>&1
    sleep 5
    sort -u "logs/$1_b1.txt" > "logs/$1_b2.txt"
    sleep 5
    perl -E "while(<>) { print $_ unless (/@@/ or /\#/ or /%%/ or /\#\?\#/ ); }" "rules/$1_b2.txt" > "logs/$1_b3.txt"
    sleep 5
    perl -E "while(<>) { print $_ if (/@@/ and !/\#\?\#/); }" "logs/$1_b2.txt" > "logs/$1_b4.txt"
    sleep 5
    ./deps/ruleset_converter --input_format=filter-list --output_format=unindexed-ruleset --input_files="logs/$1_b3.txt","logs/$1_b4.txt" --output_file="dist/$1.dat" > "logs/$1_err3.log" 2>&1
    sleep 5
    ./deps/ruleset_converter --input_format=unindexed-ruleset --output_format=filter-list --input_files="dist/$1.dat" --output_file="dist/$1.txt" > "logs/$1_err4.log" 2>&1
    echo "::endgroup::"
}

cleanup
echo "::endgroup::"

echo "::group::Build executable"
log "Building"
go build -v -o filtrite
echo "::endgroup::"

echo "::group::Downloading latest subresource_filter_tools build"
wget -O "subresource_filter_tools_linux.zip" "https://github.com/xarantolus/subresource_filter_tools/releases/latest/download/subresource_filter_tools_linux-x64.zip"

mkdir -p deps
unzip "subresource_filter_tools_linux.zip" -d deps

rm "subresource_filter_tools_linux.zip"
echo "::endgroup::"


echo "::group::Other setup steps"
chmod +x filtrite
chmod +x deps/ruleset_converter
mkdir -p dist
mkdir -p logs
mkdir -p rules
echo "::endgroup::"

# Default is a special case because of the download
echo "::group::List: bromite-default"
# Download default bromite filter list
wget -O rules/filters.dat https://www.bromite.org/filters/filters.dat
log "Start generating bromite-default filters.txt"
./deps/ruleset_converter --input_format=unindexed-ruleset --output_format=filter-list --input_files=rules/filters.dat --output_file=rules/filters.txt > logs/filter.log 2>&1
echo "::endgroup::"

# All other lists can be listed here
# filtrite bromite-extended
filtrite bromite-4pda

echo "::group::Cleanup"
cleanup
echo "::endgroup::"

