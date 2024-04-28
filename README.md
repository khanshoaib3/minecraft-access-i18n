# minecraft-access-i18n

This is a translation subproject for the [minecraft-access](https://github.com/khanshoaib3/minecraft-access) Minecraft Mod project, which translates the text content to be presented to users in that mod but not present in the Vanilla game into multiple languages.

## How to contribute

The English version is used as the original text.
Please feel free to submit or discuss translating into other languages.

For an existing language, there are automatically generated [untranslated files](#untranslated-keys), each file has the following content, every three line represents an untranslated field:

```text
minecraft_access.keys.other.group_name (field key)
Minecraft Access: Other Keybindings (English translation)
(blank line for filling translation)
...
```

Please fill the blank line with translation.

For adding a new language, the naming of i18n files for the languages need to be the same as the "in-game" Locale Code on the [wiki](https://minecraft.wiki/w/Language#Languages). For example file for the "English (US)" (American English) is "en_us.json".

There is a [file](.ci/not_translated/un_un_untranslated.txt) that contains all fields that need to be translated, change its "un_un" to the Locale Code of the new language then translate the content.

After finishing the translation, please put the translation file under `new_translation` directory then [submit a Pull Request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) (or just send the file to developers, let us upload for you).

## Untranslated Keys

| Language | Untranslated Field Count | File |
|----------|--------------------------|------|
