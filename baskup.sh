#!/bin/sh
BACKUP_DIR=./backup

function select_rows () {
  sqlite3 ~/Library/Messages/chat.db "$1"
}

for line in $(select_rows "select distinct guid from chat;" ); do

  contact=$line
  arrIN=(${contact//;/ })
  contactNumber=${arrIN[2]}
  #Make a directory specifically for this folder
  mkdir -p $BACKUP_DIR/$contactNumber/Attachments

  #Perform SQL operations
  select_rows "
  select is_from_me,text, datetime(date + strftime('%s', '2001-01-01 00:00:00'), 'unixepoch', 'localtime') as date from message where handle_id=(
  select handle_id from chat_handle_join where chat_id=(
  select ROWID from chat where guid='$line')
  )" | sed 's/1\|/Me: /g;s/0\|/Friend: /g' > $BACKUP_DIR/$contactNumber/$line.txt

  select_rows "
  select filename from attachment where rowid in (
  select attachment_id from message_attachment_join where message_id in (
  select rowid from message where cache_has_attachments=1 and handle_id=(
  select handle_id from chat_handle_join where chat_id=(
  select ROWID from chat where guid='$line')
  )))" | cut -c 2- | awk -v home=$HOME '{print home $0}' | tr '\n' '\0' | xargs -0 -I fname cp fname $BACKUP_DIR/$contactNumber/Attachments

done
