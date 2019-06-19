#!/bin/bash

set -e
# count: real line count of history push 
  count=0
# offset: line count of incomplete block
offset=0
 if [ -e "$FILE" ]; then
    count=$(cat ./.count.txt | awk '/^[0-9]+$/{print $1}')
 fi
# totalCount: current mysql-slow.log line count
totalCount=$(wc -l /data/log/mysql/mysql-slow.log | awk '{print $1}')

IFS=$'\n'
declare -a lines=(`tail -n +$count /data/log/mysql/mysql-slow.log | awk '{print $0}'`)

len=${#lines[@]}
for ((i=0;i<$len;i++));do
   posSt=$i
   posEnd=$i
   if echo ${lines[posSt]} | grep -qP '^# Time: ' ;then
      posEnd=$((i + 1))
      until [ $posEnd -ge $len ] || `echo ${lines[posEnd]} | grep -qP '^# Time: '` ;do
            posEnd=$((posEnd + 1))
      done
      
      if echo ${lines[posEnd]} | grep -qP '^# Time: ' ;then
         i=$((posEnd -1))
      else
         offset=$((len - posSt))
         break
      fi
    else 
       continue
    fi     
   
   pos=$((posSt + 1))
   str=""
   queryTime=""
   while [ $pos -lt $posEnd ];do
         pos=$((pos + 1))
         if echo ${lines[pos]} | grep -qP '^# Query_time:' ;then
            queryTime=(`echo ${lines[pos]} | awk '{print $2 $3}'`)
            continue
         fi 

         if echo ${lines[pos]} | grep -qP '^# ' ;then
            continue
         else
            str=$str" "${lines[pos]}
         fi
    done

   str=$str" "$queryTime
   if echo $str | grep -iqP 'select|update|delete|insert|create|drop|show|alter';then
      echo $str
   fi
done

# write real push count into file
echo $((totalCount - offset)) >./.count.txt
chmod 666 /data/log/mysql/.count.txt

 