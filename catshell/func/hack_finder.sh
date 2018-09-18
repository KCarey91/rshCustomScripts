#!/bin/bash
## Grep for common strings found in hacked files. (scans all PHP files in CWD)

# To add: Multi-line greps:
# find -type f -iname '*.php' | xargs grep --color -zoHP "('[a-z0-9A-Z]{20,}'\.\s*){10,}"

function hack_finder() {
# Fixed-String Values to search for, one per line
# No regex or globbing.  Just need to escape double-quotes.
fixed_string_values="eval(base64_decode(
gzinflate(base64_decode(
cwd = @getcwd();
chr((ord(
substr(md5(strrev(
chr(ord(
cwd[strlen(\$cwd)
ini_get('safe_mode');
ini_set(\"display_errors\"
=\"\x62\"
$data = base64_decode(\"
\"+ r + \"&r=\" + document.referrer;\"
if(strtoupper(substr(PHP_OS, 0, 3) ) == \"WIN\")
window.top.location.href=\"http://
@ini_get(\"disable_functions\")
){if(@copy(
eval(\$___(\$__));
copy(\"endless.html\"
system(\"wget
symlink(\"/\",\"sym/root\");
@copy(\$_FILES['file']['tmp_name']
error_reporting(0);if(
x6C\x28\x67\x7A\x69\x6E\x66\x6C\x61\x74
$_COOKIE [str_replace(
FOPO
PHP Obfuscator
HACKED"

# Regex escaped for egrep:
regular_expression_values=" = Array\('\w'=>'\w', '\w'=>'\w', '\w'=>'\w',
\.chr\([0-9]*\)\.
[$]GLOBALS\['[a-z0-9A-Z]*'\]\[[0-9]*\]\.[$]GLOBALS\['[a-z0-9A-Z]*'\]\[[0-9]*\]
\$[a-zA-Z0-9]+\[[0-9]+\]\s*\.\s*(\$[a-zA-Z0-9]+\[[0-9]+\]\s*\.\s*)+"

# Convert the regular expression list above into something we can feed into egrep.
regular_expression_values="($(echo -n "${regular_expression_values}" | tr '\n' '|'))"


# Set up some files to ignore.
excluded_files="_wpeprivate/.quarantine
functions/thumb.php$
/timthumb.php$
/updraftplus/includes/phpseclib/Crypt/Hash.php$
/updraftplus/includes/phpseclib/File/X509.php$
/worker/src/PHPSecLib/File/X509.php$
/worker/src/PHPSecLib/Net/SSH2.php$
/worker/src/PHPSecLib/Net/SSH1.php$
/worker/src/PHPSecLib/Crypt/RSA.php$
/worker/src/PHPSecLib/Crypt/Hash.php$
wp-content/plugins/google-sitemap-generator/sitemap-core.php
wp-content/plugins/google-sitemap-generator/sitemap-ui.php
wp-content/plugins/gotmls/images/index.php
wp-content/plugins/gravityforms/includes/phpqrcode/phpqrcode.php
wp-content/plugins/php_compatibility_tester/vendor/squizlabs/php_codesniffer/CodeSniffer/Standards/PhpCompatibility/Tests/sniff-examples/deprecated_ini_directives.php
wp-content/plugins/php_compatibility_tester/vendor/squizlabs/php_codesniffer/CodeSniffer/Standards/php-compatibility/Tests/sniff-examples/deprecated_ini_directives.php
wp-content/plugins/php_compatibility_tester/vendor/wimg/php-compatibility/Tests/sniff-examples/deprecated_ini_directives.php
wp-includes/ID3/module.audio-video.quicktime.php
wp-includes/ID3/module.audio-video.riff.php
wp-includes/ID3/module.audio.mp3.php
wp-includes/class-phpass.php
wp-includes/formatting.php
wp-includes/pomo/entry.php"

# Turn that list into some regex.
excluded_files=$(echo -n "${excluded_files}" | tr '\n' '|')
excluded_files="(${excluded_files})"

# Don't touch below here. :)  This is the thing that finds/searches the files
#   based on the rules defined above.

  ionice -c 2 -n 7 nice -n 19 find . -type f -name '*.php' -not -empty -print0 |
   xargs -0 -r -n 1 | xargs -r -P25 -I@ bash -c "
      if [[ ! \"@\" =~ ${excluded_files} ]] ; then
        LC_ALL=C nice -n 19  grep --color -iHEnr \"${regular_expression_values}\" \"@\"
        LC_ALL=C nice -n 19  grep --color -FHnr '${fixed_string_values}' \"@\"
      fi"

}
