## This will provide a printout of all the test queries under "Queries" in Overdrive.
##  No changes are made, nothin is deleted, this is only a count for diagnostics.
##  If you need to remove anything, confirm first and use OverDrive to delete (after backup).
##
##  Or, To DELETE records from CLI:
##
##  Revisions:
##    DELETE FROM wp_posts WHERE post_type = "revision";
##  Trashed Posts:
##    DELETE FROM wp_posts WHERE post_type = "trash";
##  Spam Comments:
##    DELETE FROM wp_comments WHERE comment_approved = "spam";
##  Trashed Comments:
##    DELETE FROM wp_comments WHERE comment_approved = "trash";
##  Orphaned Postmeta:
##    DELETE pm FROM wp_postmeta pm LEFT JOIN wp_posts wp ON wp.ID = pm.post_id WHERE wp.ID IS NULL;
##  Orphaned Commentmeta:
##    DELETE FROM wp_commentmeta WHERE comment_id NOT IN (SELECT comment_id FROM wp_comments);
##  Transients:
##    DELETE FROM wp_options WHERE option_name LIKE ('\_transient\_%'); DELETE FROM wp_options WHERE option_name LIKE ('\_site\_transient\_%');
##    DELETE FROM wp_options WHERE option_name LIKE ('\_transient\_%'); DELETE FROM wp_options WHERE option_name LIKE ('\_site\_transient\_%');
##  Orphaned Relationships:
##    DELETE tr FROM wp_term_relationships tr INNER JOIN wp_term_taxonomy tt ON (tr.term_taxonomy_id = tt.term_taxonomy_id) WHERE tt.taxonomy != "link_category" AND tr.object_id NOT IN (SELECT ID FROM wp_posts);
##  Limit Login Lockouts:
##    UPDATE wp_options SET option_value = "" WHERE option_name = "limit_login_lockouts";


function dbcount() {
grn='\033[1;32m' lgrn='\033[0;32m' rst='\033[0m'
db=$(grep -i db_name wp-config.php |awk -F"'" '{print $4}'|head -n1)
user=$(grep -i db_user wp-config.php | awk -F"'" '{print $4}'|head -n1)
pass=$(grep -i db_pass wp-config.php |awk -F"'" '{print $4}'|head -n1)
pre=$(grep -i table_prefix wp-config.php | awk -F"'" '{print $2}')
printf "\n\033[4;32m%-9s\t%s${rst}\n" "Entries" "Search Type"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count from ${pre}posts WHERE post_type='revision';" 2>/dev/null) "Revisions"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count from ${pre}posts WHERE post_type='trash';" 2>/dev/null) "Trashed Posts"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count FROM ${pre}comments WHERE comment_approved = 'spam';" 2>/dev/null) "Spam Comments"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count FROM ${pre}comments WHERE comment_approved = 'trashed';" 2>/dev/null) "Trashed Comments"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(pm.meta_id) as row_count FROM ${pre}postmeta pm LEFT JOIN ${pre}posts wp ON wp.ID = pm.post_id WHERE wp.ID IS NULL;" 2>/dev/null) "Orphaned Postmeta"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count FROM ${pre}commentmeta WHERE comment_id NOT IN (SELECT comment_id FROM ${pre}comments);" 2>/dev/null) "Orphaned CommentMeta"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count FROM ${pre}options WHERE option_name LIKE ('\_transient\_%%')" 2>/dev/null) "Transients (_transient_)"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(*) as row_count FROM ${pre}options WHERE option_name LIKE ('\_site\_transient\_%%')" 2>/dev/null) "Transients (_site_transient_)"
printf "${grn}%-9s\t${lgrn}%s${rst}\n" $(mysql -sN -u $user -p"$pass" $db -e "SELECT COUNT(tr.object_id) as row_count FROM ${pre}term_relationships tr INNER JOIN ${pre}term_taxonomy tt ON (tr.term_taxonomy_id = tt.term_taxonomy_id) WHERE tt.taxonomy != 'link_category' AND tr.object_id NOT IN (SELECT ID FROM ${pre}posts);" 2>/dev/null) "Orphaned Relationships"
echo -e "\033[4;32mLimit Login Lockouts:${rst}"
 mysql -sN -u $user -p"$pass" $db -e "SELECT option_value as row_count FROM ${pre}options WHERE option_name = 'limit_login_lockouts';" 2>/dev/null
echo -ne "\033[4;32mAutoLoad NumRows/Size in KB:${rst}\n\t"
 mysql -sN -u $user -p"$pass" $db -e "select count(row_size),sum(row_size)/1024 from (select length(option_value) as row_size from ${pre}options where autoload='yes') as table_size;" 2>/dev/null
}
