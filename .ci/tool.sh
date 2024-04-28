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
    comm -23 <(jq 'keys' $1) <(jq 'keys' $2) >$f
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

save_untranslated_keys_into_files() {
    for f in $I18N_FILES_EXCEPT_EN; do
        # f=../zh_cn.json, then key_file=temp/zh_cn_keys
        name=$(i18n_name "$f")
        key_file=${TEMP_DIR}/${name}_keys
        # save diff into files
        diff_keys_between_two_json_files $EN_I18N_FILE $f >$key_file

        # rm if file is empty
        if [ ! -s $key_file ]; then
            rm -f $key_file
        fi

    done
}

# -- main --

rm_rf_directories_if_exists $TEMP_DIR
create_directories_if_not_exists $TEMP_DIR $NEW_TRANS_DIR $NOT_TRNAS_DIR
save_untranslated_keys_into_files
# rm_rf_directories_if_exists $TEMP_DIR
