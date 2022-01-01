#!/bin/bash

LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../" &> /dev/null && pwd )"

GETDIRS="${LIB_DIR}/fsutils/getdirs.sh"
FEXISTS="${LIB_DIR}/fsutils/fexists.sh"
ISDIR="${LIB_DIR}/fsutils/isdir.sh"
GETCONTENT="${LIB_DIR}/fsutils/getcontent.sh"

LOGGER="${LIB_DIR}/logger.sh"
CHECK_DEPENDENCIES="${LIB_DIR}/dependencies.sh"

"$CHECK_DEPENDENCIES"
if test $? -ne 0
then exit -1
fi

ARCHIVE="$1"
if test -e "$ARCHIVE"
then
    if test -f "$ARCHIVE"
    then
        if test -r "$ARCHIVE"
        then
            echo -n
        else
            "$LOGGER" error "Cannot read from archive file '$ARCHIVE'"
            exit -1
        fi
    else
        "$LOGGER" error "'$ARCHIVE' is not a file"
        exit -1
    fi
else
    "$LOGGER" error "Archive '$ARCHIVE' doesn't exist"
    exit -1
fi

shift
USAGE="USAGE : `basename "$0"` [path-to-file...]" 

if test $# -eq 0
then
    echo "$USAGE"
    exit -1
fi


while [ $# -gt 0 ]
do
    read -r path <<< "$1"
    if [ "$path" = '..' ] #arg is '..' -> go to parent dir
    then
        if [ "$WD" = "$ROOTDIR" ]
        then
            echo "$ROOTDIR"
        else
            echo "$WD" |sed 's/^\(.*\\\)[^\\]\+[\\]\?$/\1/'
        fi
    elif [ "$path" = '.' ]
    then
        echo "$WD"
    fi

    if [ "${path:0:1}" != '\' ] #path is relative
    then
        path="$WD$path" #converting to absolute path
    else
        if [ "$(echo "${path:0:`expr "${#ROOTDIR}"`}" |sed 's/\\$//')" != "$(echo $ROOTDIR |sed 's/\\$//')" ]
        then
            path="$ROOTDIR${path:1}"
        fi
    fi
    
    "$FEXISTS" "$path" "$ARCHIVE"
    if test $? -ne 0 #does the file exist ?
    then
        "$LOGGER" error "'$path' doesn't exist"
    else
        filename="$(echo "$path" |awk -F'\' '{print $(NF)}')"
        containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]*\)/\1/')"
        
        "$ISDIR" "$(echo "$path" |sed 's/\\$//')" "$ARCHIVE"
        if test $? -ne 0 #is not a directory
        then
            filename="$(echo "$path" |awk -F'\' '{print $(NF)}')"
            containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]*\)/\1/')"
            fileinfo="$("$GETCONTENT" "$ARCHIVE" "$containedin" |grep -o "^$filename"' *[^d][rwx\-]\{9\} [0-9]\+ [0-9]\+ [0-9]\+')" #
            read -r filestart filelen < <(echo "$fileinfo" |awk 'BEGIN{IFS=" "}{printf "%s %s\n",$(NF-1),$NF}')
            fileend=`expr $filestart + $filelen - 1`
            firstline=`sed -n 1p "$ARCHIVE"`
            HEADERSTART=`echo "$firstline" |cut -d":" -f1`
            BODYSTART=`echo "$firstline" |cut -d":" -f2`
            HEADEREND=$BODYSTART
            HEADERLEN=$(($HEADEREND - $HEADERSTART))
            if test $filelen -gt 0
            then 
                #delete file content
                sed -i "$filestart","$fileend"d "$ARCHIVE"
            fi
            #now update other files line starts
            i=1
            while read -r archiveline
            do 
                if test $i -ge "$HEADERSTART"
                then
                    elt="$(echo "$archiveline" |grep ".* [^d][rwx\-]\{9\} [0-9]\+ [0-9]\+ [0-9]\+")"
                    if test -n "$elt"
                    then
                        if [ "$elt" = "$fileinfo" ]
                        then
                            linetodel=$i
                        fi
                        #linestart="$(echo "$elt" |awk '{print $(NF-1)}')"
                        #if test $filelen -gt 0 -a $linestart -gt $filestart #those files' body is after the deleted file's body
                        #then
                         #   sed -i $i's/[0-9]\+ \([0-9]\+\)$/'`expr $linestart - $filelen - 1`' \1/' "$ARCHIVE"
                        #elif [ "$elt" = "$fileinfo" ]
                        #then
                        #    linetodel=$i
                        #else
                        #    sed -i $i's/[0-9]\+ \([0-9]\+\)$/'`expr $linestart - 1`' \1/' "$ARCHIVE"
                        #fi
                    fi
                fi

                if test $i -ge `expr $BODYSTART` #out of the header
                then break
                fi
                ((i++))
            done < "$ARCHIVE"
            sed -i $linetodel'd' "$ARCHIVE"
            sed -i 1's/[0-9]\+:[0-9]\+/'"$HEADERSTART:`expr $BODYSTART - 1`"'/' "$ARCHIVE"
            ((HEADERLEN--))
            ((HEADEREND--))
            awkcommand='( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 ~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {for (i=1;i<=NF-2; i++) {if(i!=NF-4) printf "%s ",$i; else printf "%s  ",$i};($(NF-1)>'$filestart')?newstart=$(NF-1)-1-'$filelen':newstart=$(NF-1)-1;printf ("%d %s\n",newstart,$NF);}
                        ( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 !~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {print}
                        ( ! (NR>='$HEADERSTART' && NR<='$HEADEREND') ) {print}'
            echo "$(gawk -F' ' "$awkcommand" "$ARCHIVE")" > "$ARCHIVE" #updating files start in header
            echo "'$path' has been removed successfully."
            

        else #is a directory
            if [ "${path:`expr "${#path}" - 1`}" == '\' ]
            then
                path="${path:0:`expr "${#path}" - 1`}"
            fi
            containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]*\)/\1/')"
            dirname="$(echo "$path" |awk -F'\' '{print $(NF)}')"
            if [ "${path:`expr "${#path}" - 1`}" != '\' ]
            then
                path="$path\\"
            fi
            rawcontent="$("$GETCONTENT" "$ARCHIVE" "$path" |grep -o '^.* *[daDPSLP\-][rwx\-]\{9\} [0-9]\+')" 
            content="$(echo "$rawcontent" |awk -F' ' '{for(i=1;i<=NF-3;i++) if($i!=" ") printf "%s ",$i; if($i!=" ") print $i;}')" 
            if [ "$path" != "$ROOTDIR" ]
            then
                if test -n "$content" #recursion on dir's content
                then
                    while read -r elt
                    do
                        #echo "$path$elt"
                        "$0" "$ARCHIVE" "$path$elt"
                    done < <(echo "$content")
                fi
                firstline=`sed -n 1p "$ARCHIVE"`
                HEADERSTART=`echo "$firstline" |cut -d":" -f1`
                BODYSTART=`echo "$firstline" |cut -d":" -f2`
                HEADEREND=$BODYSTART
                HEADERLEN=$(($HEADEREND - $HEADERSTART))
                i=1
                friendlyPath="$(echo "$path" |sed 's/\\/\\\\/g')"
                friendlyContainedIn="$(echo "$containedin" |sed 's/\\/\\\\/g')"
                inparentdir=0
                while read -r archiveline
                do 
                    #filee="$(echo "$archiveline" |grep ".* [^d][rwx\-]\{9\} [0-9]\+ [0-9]\+ [0-9]\+")"
                    #echo "$i$filee"
                    #if test -n "$filee"
                    #then
                    #    linestart="$(echo "$filee" |awk '{print $(NF-1)}')"
                    #    sed -i $i's/[0-9]\+ \([0-9]\+\)$/'`expr $linestart - 3`' \1/' "$ARCHIVE"
                    #fi

                    if test $i -ge "$HEADERSTART"
                    then
                        
                        dirr="$(echo "$archiveline" |grep -o '^directory \('"$friendlyPath"'\|'"$friendlyContainedIn"'\)$')"
                        if test -n "$dirr"
                        then
                            base="$(echo "$dirr" |cut -d" " -f'2-')"
                            if [ "$base" = "$path" ] #in the dir we want to remove
                            then
                                position=$i
                            elif [ "$base" = "$containedin" ] #in the parent dir
                            then
                                inparentdir=1
                                ((i++))
                                continue
                            fi
                        fi
                    fi
                    if test $inparentdir -eq 1
                    then
                        if [ "$archiveline" = '@' ]
                        then
                            inparentdir=0
                        elif test -n "$(echo "$archiveline" |grep -o "^$dirname"' *d[rwx\-]\{9\} [0-9]\+$')"
                        then
                            parentdirinstanceline=$i #remove instance of this dir in parentdir
                            inparentdir=0
                        fi
                    fi

                    if test $i -ge `expr $BODYSTART` #out of the header
                    then break
                    fi
                    ((i++))
                done < "$ARCHIVE"
                echo "'$path' has been removed successfully."
                if test -n $parentdirinstanceline
                then
                    sed -i $parentdirinstanceline'd;'$position','$((position+1))'d' "$ARCHIVE" #deleting instance in parent dir, dir entry and @
                fi
                sed -i 1's/[0-9]\+:[0-9]\+/'"$HEADERSTART:`expr $BODYSTART - 3`"'/' "$ARCHIVE"
                ((HEADERLEN-=3))
                ((HEADEREND-=3))
                awkcommand='( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 ~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {for (i=1;i<=NF-2; i++) {if(i!=NF-4) printf "%s ",$i; else printf "%s  ",$i};newstart=$(NF-1)-3;printf ("%d %s\n",newstart,$NF);}
                            ( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 !~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {print}
                            ( ! (NR>='$HEADERSTART' && NR<='$HEADEREND') ) {print}'
                    echo "$(awk -F' ' "$awkcommand" "$ARCHIVE")" > "$ARCHIVE" #adding 3 to each file's line start
            else
                firstline=`sed -n 1p "$ARCHIVE"`
                HEADERSTART=`echo "$firstline" |cut -d":" -f1`
                BODYSTART=`echo "$firstline" |cut -d":" -f2`
                echo "$HEADERSTART:`expr $HEADERSTART + 2`" > "$ARCHIVE"
                for((i=1;i<$HEADERSTART-1;i++)); do echo "" >> "$ARCHIVE"; done
                echo "directory $ROOTDIR" >> "$ARCHIVE"
                echo "@" >> "$ARCHIVE"
            fi
            #firstline=`sed -n 1p "$ARCHIVE"`
            #HEADERSTART=`echo "$firstline" |cut -d":" -f1`
            #HEADERLEN=$((`echo "$firstline" |cut -d":" -f2` -$HEADERSTART))
            #ARCHIVELEN="$(wc -l < "$ARCHIVE")"
            #i=-1
            #while read -r headerline
            #do
              #  ((i++))
             #   if [ "$headerline" = "directory $containedin" ]
             #   then
             #       d="found"
             #       continue
            #    fi

            #    if [ "$headerline" = '@' ]
             #   then
            #        if test -n "$d"
            #        then  
            #               # sed -i "`expr $i + $HEADERSTART - 1`"'s/\(.*\)/\1\n'"$filename $DEFAULTRIGHTS 0 $ARCHIVELEN 0"'/' "$ARCHIVE"
                          #  sed -i '1s/\(.*\)/'"$HEADERSTART:`expr $HEADERLEN + 1 + $HEADERSTART`"'/' "$ARCHIVE"
                           # echo "'$filename' has been created successfully in '$containedin'."
            #            break
            #        fi
             #   fi
           #done < <(tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN)
        fi
    fi
    shift
done



