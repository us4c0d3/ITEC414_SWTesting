# Remove all comments from the test case file
function removeAnnotation() {
    #!/bin/bash
    awk 'BEGIN { multi_line_comment = 0; }
    {
        if (multi_line_comment == 1) {
            if ($0 ~ /\*\//) {
                sub(/^.*\*\//, "");
                multi_line_comment = 0;
            } else {
                next;
            }
        }
        if ($0 ~ /\/\*/) {
            sub(/\/\*.*\*\//, "");
            if ($0 ~ /\/\*/) {
                sub(/\/\*.*$/, "");
                multi_line_comment = 1;
            }
        }
        gsub(/\/\/.*$/, "");
        if ($0 !~ /^ *$/) {
            print;
        }
    }' "$1" > "removedTC.txt"
}

# Get function information from the function prototype
function preprocessPrototype() {
    #!/bin/bash
    function_prototype=$(grep -v '^ *//' "$1" | head -n1)
    function_type=$(echo "$function_prototype" | awk '{ print $1 }')
    function_name=$(echo "$function_prototype" | grep -oP "(?<=\s)\w+(?=\()" )
    num_parameters=$(echo "$function_prototype" | grep -o "," | wc -l)
    echo "Function prototype: $function_prototype"
    echo "Function type: $function_type"
    echo "Function name: $function_name, number of parameters: $num_parameters"
}

# Get the parameter types of the function prototype
function getParamTypes() {
    #!/bin/bash
    arg_str=$(echo $function_prototype | cut -d'(' -f2 | cut -d')' -f1)
    IFS=',' read -ra args <<< "$arg_str"

    # Get the index of the char type of parameters
    counter=0
    char_idx=()
    for arg in "${args[@]}"; do
        arg_type=$(echo $arg | awk '{print $1}')
        if [ $arg_type == "char" ]; then
            char_idx+=($counter)
        fi
        ((counter++))
    done
}

# Process multiple spaces as one space
function processSpace() {
    #!/bin/bash
    modified_string=$1
    modified_string=$(echo "$modified_string" | tr -s ' ')
}

# Main function
#!/bin/bash

# Check that both input files have been provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <c_code_file> <test_case_file>"
    exit 1
fi

# Preprocess the test case file and get the function information
removeAnnotation "$2"
preprocessPrototype "$2"
getParamTypes

# Create a test diver C code file
echo "#include <stdio.h>" > "${function_name}_driver.c"
echo "#include <stdlib.h>" >> "${function_name}_driver.c"
echo "#include \"$1\"" >> "${function_name}_driver.c"
echo "" >> "${function_name}_driver.c"
echo "int main() {" >> "${function_name}_driver.c"
echo "    puts(\"Run the \\\"$function_name\\\" Test Driver\");" >> "${function_name}_driver.c"
echo "    puts(\"---------------------------------------\");" >> "${function_name}_driver.c"

# Read the test cases line by line
line_num=0
while read line || [[ -n $line ]]; do
    if [ $line_num -eq 0 ]; then
        ((line_num++))
        continue
    fi
    processSpace "$line"
    # Extract the test parameters and expected output from the test case line
    line_arr=($modified_string)
    test_params=("${line_arr[@]:1:$((${#line_arr[@]}-2))}")
    expected_output=${line_arr[-1]}

    # Process the char type of test parameters
    for (( i=0; i<${#test_params[@]}; i++ )); do
        if [[ " ${char_idx[@]} " =~ " $i " ]]; then
            test_params[$i]="'${test_params[$i]}'"
        fi
    done
    modified_test_params=$(echo "${test_params[@]}" | sed -e 's/\s\+/, /g')

    # Process the char type of expected output
    if [[ $function_type == "char" ]]; then
        expected_output="'$expected_output'"
    fi

    # Generate the test case
    echo "    printf(\"Test case ${line_arr[0]}: \");" >> "${function_name}_driver.c"
    echo "    if ($function_name($modified_test_params) == $expected_output) {" >> "${function_name}_driver.c"
    echo "        printf(\"Passed\n\");" >> "${function_name}_driver.c"
    echo "    } else {" >> "${function_name}_driver.c"
    echo "        printf(\"Failed\n\");" >> "${function_name}_driver.c"
    echo "    }" >> "${function_name}_driver.c"
    echo "" >> "${function_name}_driver.c"

    ((line_num++))
done < "removedTC.txt"

# Close the main function
echo "    puts(\"---------------------------------------\");" >> "${function_name}_driver.c"
echo "    puts(\"Finish the \\\"$function_name\\\" Test Driver\");" >> "${function_name}_driver.c"
echo "    puts(\"\");" >> "${function_name}_driver.c"
echo "    return 0;" >> "${function_name}_driver.c"
echo "}" >> "${function_name}_driver.c"

# Compile the test driver with gcov test
gcc -fprofile-arcs -ftest-coverage ${function_name}_driver.c

# Run the program
./a.out > "${function_name}_test_result.txt"

# Test the program
gcov -b "${function_name}_driver.c" >> "${function_name}_test_result.txt"

# Clean up the temporary files
rm "removedTC.txt" "a.out"
