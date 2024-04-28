#!/bin/bash

NEW_TRANS_DIR=new_translation
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

sort_all_i18n_files() {
    for f in $I18N_FILES; do
        jq -S '.' $f >$TEMP_DIR/a
        mv $TEMP_DIR/a $f
    done
}

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
    # remove two white spaces, commas and quotes:
    #
    #minecraft_access.area_map.cursor_reach_bound
    #minecraft_access.area_map.cursor_reset
    #...
    sed -E 's/\s{2}"([a-z_\\.]+).*/\1/' $f
}

i18n_name() {
    # "../en_us.json" -> "en_us"
    # "new_trans/en_us_untrans.txt" -> "en_us"
    echo $1 | sed -E 's/.*\/([a-zA-Z]{2}_[a-zA-Z]{2}).*/\1/'
}

generate_untranslated_files_for_each_language_except_en() {
    # generate an untranslated file which contains all fields,
    # for new language translation
    echo "{\"a\":\"b\"}" >$TEMP_DIR/un_un.json
    generate_untranslated_files_for_one_language $TEMP_DIR/un_un.json

    for f in $I18N_FILES_EXCEPT_EN; do
        generate_untranslated_files_for_one_language $f
    done
}

generate_untranslated_files_for_one_language() {
    i18n_file=$1
    name=$(i18n_name "$i18n_file")
    key_file=${TEMP_DIR}/${name}_keys
    untrans_file=${NOT_TRNAS_DIR}/${name}_untranslated.txt

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

merge_new_translations_back_to_i18n_files() {
    new_files=$(ls $NEW_TRANS_DIR/*.txt)
    for f in $new_files; do
        merge_one_language $f
    done
}

merge_one_language() {
    new_file=$1
    tempa=$TEMP_DIR/a
    tempb=$TEMP_DIR/b

    # extract every first (key) and third (translation) lines from new translation file,
    # then combine them as {key},{translation}
    awk 'NR%3==1 {first=$0} NR%3==0 {print first","$0}' $new_file >$tempa
    # construct json from kv style
    jq -R '[inputs|split(",")|{(.[0]):.[1]}] | add' $tempa >$tempb
    # remove empty-value fields
    jq 'del(.. | select(. == ""))' $tempb >$tempa

    name=$(i18n_name "$new_file")
    ori_file=$I18N_DIR/${name}.json

    if [ -e $ori_file ]; then
        # exist language, merge two jsons
        jq -S -s '.[0] + .[1]' $ori_file $tempa >$tempb
        mv $tempb $ori_file
    else
        # new language, create the i18n file
        mv $tempa $ori_file
    fi
}

# -- main --

rm_rf_directories_if_exists $TEMP_DIR $NOT_TRNAS_DIR
create_directories_if_not_exists $TEMP_DIR $NEW_TRANS_DIR $NOT_TRNAS_DIR

sort_all_i18n_files
merge_new_translations_back_to_i18n_files
generate_untranslated_files_for_each_language_except_en

rm_rf_directories_if_exists $TEMP_DIR
