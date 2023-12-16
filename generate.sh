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

    # Joining our lists with the default filters.dat
    ./deps/ruleset_converter --chrome_version=0 --input_format=unindexed-ruleset --output_format=filter-list --input_files="logs/$1.dat","logs/filters.dat" --output_file="logs/$1_b0.txt" > "logs/$1_2.log" 2>&1

    # Removing duplicate values (a ruleset_converter bug?) like :
    # $script,xmlhttprequest,third-party,domain=tamilyogi.cc|tamilyogi.vip
    # $script,xmlhttprequest,third-party,domain=tamilyogi.vip|tamilyogi.cc
    ./deps/ruleset_converter --chrome_version=0 --input_format=filter-list --output_format=unindexed-ruleset --input_files="logs/$1_b0.txt" --output_file="logs/$1_b0.dat" 
    ./deps/ruleset_converter --chrome_version=0 --input_format=unindexed-ruleset --output_format=filter-list --input_files="logs/$1_b0.dat" --output_file="logs/$1_b0.txt" 

    # Fixing/sorting (I prefer sorted lists with whitelist rules at the end)
    grep -vf rules/badfilters.txt "logs/$1_b0.txt" > "logs/$1_b1.txt"
    sort -u "logs/$1_b1.txt" > "logs/$1_b2.txt"
    grep -v '^@@' "logs/$1_b2.txt" > "logs/$1_b3.txt"
    grep '^@@' "logs/$1_b2.txt" > "logs/$1_b4.txt"
    
    # Joining with myfilters.txt
    ./deps/ruleset_converter --chrome_version=0 --input_format=filter-list --output_format=unindexed-ruleset --input_files="logs/$1_b3.txt","logs/$1_b4.txt","rules/myfilters.txt" --output_file="dist/$1.dat" > "logs/$1_3.log" 2>&1
    
    # Generating a filter list (*.txt) too
    ./deps/ruleset_converter --chrome_version=0 --input_format=unindexed-ruleset --output_format=filter-list --input_files="dist/$1.dat" --output_file="dist/$1.txt" > "logs/$1_err4.log" 2>&1
    
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
wget -O logs/filters.dat https://www.bromite.org/filters/filters.dat
# ./deps/ruleset_converter --input_format=unindexed-ruleset --output_format=filter-list --input_files=rules/filters.dat --output_file=rules/filters.txt > logs/filter.log 2>&1
echo "::endgroup::"

# All other lists can be listed here
# filtrite bromite-extended
filtrite bromite-4pda

echo "::group::Cleanup"
cleanup
echo "::endgroup::"

