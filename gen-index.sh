#!/usr/bin/env bash

# This function generates an index.html file for the current directory
function generate_index_html {
    # Start the HTML document
    echo "<html><head><title>Index of $(pwd)</title></head><body>" > index.html
    
    # Create an array of files in the directory, sorted by name
    files=($(ls -1 | sort -n))

    # Add links to each file in the directory
    for (( i=0; i<${#files[@]}; i++ )); do
        filename="${files[$i]}"
        echo "<a href=\"$filename\">$filename</a><br>" >> index.html
    done

    # Add links to move to the previous and next files in the directory, based on file name order
    for (( i=0; i<${#files[@]}; i++ )); do
        filename="${files[$i]}"
        if (( $i > 0 )); then
            prevfile="${files[$i-1]}"
            echo "<a href=\"$prevfile\"><< $prevfile</a> " >> index.html
        fi
        if (( $i < ${#files[@]}-1 )); then
            nextfile="${files[$i+1]}"
            echo "<a href=\"$nextfile\">$nextfile >></a>" >> index.html
        fi
        echo "<br>" >> index.html
    done

    # End the HTML document
    echo "</body></html>" >> index.html
}

# This function descends through the directory structure and generates index.html files for each directory
function descend_directories {
    for file in *; do
        if [ -d "$file" ]; then
            cd "$file"
            generate_index_html
            descend_directories
            cd ..
        fi
    done
}

# Start in the current directory
generate_index_html
descend_directories

