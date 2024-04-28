#!/bin/bash

NEW_TRANS_DIR=new_translated
NOT_TRNAS_DIR=not_translated
TEMP_DIR=temp

I18N_DIR=..
# example values:
# ../en_us.json ../it_it.json ../pt_br.json ../zh_cn.json
I18N_FILES=$(ls $I18N_DIR/??_??.json)
# ../en_us.json
EN_I18N_FILE=$(echo $I18N_FILES | sed -E 's/\b.*(en_us\.json).*\b/\1/')
# ../it_it.json ../pt_br.json ../zh_cn.json
I18N_FILES_EXCEPT_EN=$(echo $I18N_FILES | sed -E 's/\s*.*en_us\.json\s//')

rm_rf_directories_if_exists() {
    for dir in "$@"; do
        if [ -e $dir ]; then
            rm -rf $dir
        fi
    done
}

create_directories_if_not_exists() {
    for dir in "$@"; do
        if [ ! -e $dir ]; then
            mkdir $dir
        fi
    done
}

diff_keys_between_two_json_files() {
    f=$TEMP_DIR/a
    #  "minecraft_access.area_map.cursor_reach_bound",
    #  "minecraft_access.area_map.cursor_reset",
    #  ...
    comm -23 <(jq -S 'keys' $1) <(jq -S 'keys' $2) >$f
    # remove two white spaces, commas and quotation marks:
    #
    #minecraft_access.area_map.cursor_reach_bound
    #minecraft_access.area_map.cursor_reset
    #...
    sed -E 's/\s\s"//' $f | sed -E 's/",//'
}

i18n_name() {
    # "../en_us.json" -> "en_us"
    echo $1 | sed -E 's/.*\/([a-zA-Z]{2}_[a-zA-Z]{2})\.json/\1/'
}

work_on_each_language_except_en() {
    for f in $I18N_FILES_EXCEPT_EN; do
        work_on_one_language $f
    done
}

work_on_one_language() {
    i18n_file=$1
    name=$(i18n_name "$i18n_file")
    key_file=${TEMP_DIR}/${name}_keys
    untrans_file=${NOT_TRNAS_DIR}/${name}_untransalted.txt

    generate_untrans_key_file $i18n_file $key_file
    if [ $? -eq 1 ]; then
        return 0
    fi

    generate_untrans_file $key_file $untrans_file
}

generate_untrans_key_file() {
    i18n_file=$1
    key_file=$2

    # save diff into files
    diff_keys_between_two_json_files $EN_I18N_FILE $i18n_file >$key_file

    # if key file is empty, return early
    if [ ! -s $key_file ]; then
        return 1
    fi
}

generate_untrans_file() {
    key_file=$1
    untrans_file=$2

    touch $untrans_file
    while read -r key; do
        # query English text of this field
        en_value=$(jq -r --arg keyvar "$key" '.[$keyvar]' $EN_I18N_FILE)
        # append three lines:
        # {key}
        # {en_value}
        # (empty line)
        printf "%s\n%s\n\n" "$key" "$en_value" >>$untrans_file
    done <$key_file
}

# -- main --

rm_rf_directories_if_exists $TEMP_DIR $NOT_TRNAS_DIR
create_directories_if_not_exists $TEMP_DIR $NEW_TRANS_DIR $NOT_TRNAS_DIR
work_on_each_language_except_en
rm_rf_directories_if_exists $TEMP_DIR
