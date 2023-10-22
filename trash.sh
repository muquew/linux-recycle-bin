#!/bin/bash

# 如果不存在，则创建回收文件夹
# If it does not exist, create a recycle folder
TRASH_DIR="$HOME/.trash"
if [ ! -d "$TRASH_DIR" ]; then
    mkdir -p "$TRASH_DIR"
fi

# 如果不存在，则创建日志文件
# If no log file exists, create a log file
LOG_FILE="$TRASH_DIR/.logs"
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi


alias rm=trash
# rmf别名用于强制删除
# rmf for forced deletion
alias rmf='/bin/rm -rf'
alias rl='ls ~/.trash'
# 查看日志文件
# cat log files
alias rl2='cat $LOG_FILE'
# 撤销删除
# undelete
alias ru=undelfile
# 清空回收站
# empty the recycle bin
alias rll=cls


trash()
{
  for file in "$@"; do
    if [ -e "$file" ]; then
        # local是局部变量
        # local is a local variable
        local delete_time=$(date '+%Y-%m.%d-%H:%M:%S')
        local file_basename=$(basename "$file")
        local original_path=$(dirname "$(realpath "$file")")
        local new_file_name="${delete_time}_${file_basename}"
        # 添加日志文件：原始绝对路径 文件名 新的文件名（原文件名+删除时间）
        # Add log file: Original absolute path File name New file name (original file name + deleted time)
        echo -e "$original_path  $file_basename  $new_file_name" >> "$LOG_FILE"
        mv -i "$file" "$TRASH_DIR/$new_file_name"
    else
        echo "Does not exist: $file"
    fi
  done
}


undelfile()
{
  for file in "$@"; do
    while IFS= read -r line; do
        original_path=$(echo "$line" | awk '{print $1}')
        file_basename=$(echo "$line" | awk '{print $2}')
        new_file_name=$(echo "$line" | awk '{print $3}')
        if [[ "$file" = "$file_basename" ]]; then
          # 如果已经存在目标文件echo并且创建备份（添加后缀~）
          # If the object file already exists,echo and create a backup(Suffix ~)
          if [ -e "$original_path/$file_basename" ]; then
            echo "Creating backup for existing file: $original_path/$file_basename"
            mv "$original_path/$file_basename" "$original_path/$file_basename~"
          fi
          # 撤销删除
          # undelete
          mv "$TRASH_DIR/$new_file_name" "$original_path/$file_basename"
          # 为恢复删除的行添加第四个参数undeletion
          # Add a fourth parameter "undeletion" for recovering deleted rows
          awk -v orig="$original_path" -v base="$file_basename" -v new="$new_file_name" \
            '{ if ($1 == orig && $2 == base && $3 == new) print $0 " undeletion"; else print $0 }' "$LOG_FILE" > "$LOG_FILE.tmp" \
            && mv "$LOG_FILE.tmp" "$LOG_FILE"
          break
        fi
    done < "$LOG_FILE"
    # 删除已经恢复的文件的logs
    # Delete logs of files that have been recovered
    sed -i '/ undeletion/d' "$LOG_FILE"
    continue
  done
}


cls()
{
    read -p "clear sure?[y/N] " confirm
    # 如果用户没有输入任何内容，则默认为 N
    # If the user does not enter anything, the default is N
    confirm=${confirm:-N}
    [ "$confirm" == 'y' ] || [ "$confirm" == 'Y' ]  && /bin/rm -rf "$TRASH_DIR"/* && echo "" > "$LOG_FILE"
}



export TRASH_DIR
