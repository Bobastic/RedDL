#!/bin/bash

#default arguments
sub=$(mkdir -p images;ls images) #by default update all already downloaded subreddits
v=2 #verbose level
imgTreshold=3000 #maximum amount of images to download for a subreddit
upvoteTreshold=0.8 #minimum upvote ratio

#check flags
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: ./RedDL+.sh [-s SUBREDDIT] [-v LEVEL]"
            echo ""
            echo "Creates an images/ folder in current directory filled with folders with the"
            echo "name of each subreddit you download from. Inside these folders will be all the"
            echo "images from the image and gallery posts of this subreddit. If no subreddit is"
            echo "specified when calling RedDL+, updates the contents of folders of the subreddits"
            echo "you already downloaded from."
            echo ""
            echo "OPTIONS:"
            echo " -s, --subreddit SUBREDDIT     Target SUBREDDIT. If not specified, and"
            echo "                                if possible, download from previously"
            echo "                                downloaded subreddits."
            echo " -v, --verbose <0|1|2>         Verbose level. No output at 0, subreddit"
            echo "                                name at 1, subreddit and image name at 2."
            echo "                                DEFAUT: 2"
            echo ""
            echo "Examples:"
            echo " ./RedDL+.sh -s kitty          Download the images from the r/kitty"
            echo "                                subreddit to images/kitty."
            echo " ./RedDL+.sh                   Download the images from all of the"
            echo "                                subreddits in images/."
            echo " ./RedDL+.sh -v 1              Same as above without printing image names."
            echo ""
            echo "NOTICE:"
            echo "This script uses the Pushshift API, not the standard Reddit API."
            exit 0
            ;;
        -s|--subreddit)
            shift
            sub=$1
            shift
            ;;
        -v|--verbose)
            shift
            case "$1" in
                0|1|2) v=$1;;
                *) echo "$1 is not a valid verbose level! Valid arguments: 0 1 2";exit 1;;
            esac
            shift
            ;;
        *)
            echo "$1 is not a recognized flag! HELP: ./RedDL+.sh -h"
            exit 1
            ;;
    esac
done 

if [ -z "$sub" ];then
    echo "You don't have any subreddit folder to update. Add a subreddit as an argument. HELP: ./RedDL+.sh -h"
    exit 1
fi

if [ $(c() { echo $#; };c $sub;unset -f c) -gt 1 ] && [ $v -ge 1 ];then
    echo "Updating pics from: "$sub"."
    echo "HELP: ./RedDL+.sh -h"
fi

for subreddit in $sub;do
    mkdir -p "images/$subreddit"
    onDiskInit=$(ls images/$subreddit | wc -l)
    npics=-1
    before=""
    if [ $v -ge 1 ];then
        printf "Downloading r/$subreddit pics...\n"
    fi
    processed=0
    while [ $processed -le $imgTreshold ] && [ $npics -ne 0 ];do
        req=$(wget -q -O - "https://api.pushshift.io/reddit/submission/search/?subreddit=$subreddit&size=100&fields=upvote_ratio,created_utc,url,title,id,post_hint,is_gallery,media_metadata,removed_by_category&before=$before" 2>&1) #get a batch of 100 posts (the maximum possible in one request)
        npics=$(echo $req | jq -r ".[] | length")
        i=0
        while [ $i -lt $npics ];do #for each post
            removed=$(echo $req | jq -r ".data[$i].removed_by_category?")
            upvoteRatio=$(echo $req | jq -r ".data[$i].upvote_ratio?")
            if [ "$removed" == "null" ] && [ $(echo "$upvoteRatio>$upvoteTreshold" | bc) -eq 1 ];then
                if [ $(echo $req | jq -r ".data[$i].post_hint?") == "image" ];then #if it is a standard image post
                    url=$(echo $req | jq -r ".data[$i].url")
                    ext=${url: -4:4}
                    id=$(echo $req | jq -r ".data[$i].id")
                    name=$(echo $req | jq -r ".data[$i].title")
                    name="${name//&amp/&}"
                    name="${name//\// }"
                    name="${name:0:200}"
                    wget -q -O "images/$subreddit/$name$id$ext" $url > /dev/null 2>&1 & #download and save the image
                    processed=$(($processed+1))
                    if [ $v -ge 1 ];then
                        tput cuu 1
                        printf "\rDownloading r/$subreddit pics...($processed processed)\033[K\n"
                    fi
                    if [ $v -ge 2 ];then
                        printf -- "${name:0:$(($(tput cols)-10))}\033[K"
                    fi
                elif [ $(echo $req | jq -r ".data[$i].is_gallery?") == "true" ];then #if this is a gallery
                    ids=$(echo $req | jq -r ".data[$i].media_metadata | keys[]")
                    name=$(echo $req | jq -r ".data[$i].title")
                    name="${name//&amp/&}"
                    name="${name//\// }"
                    name="${name:0:200}"
                    for id in $ids;do #for each image of the gallery
                        ext=$(echo $req | jq -r ".data[$i].media_metadata[\"$id\"].m")
                        ext=".${ext: -3:3}"
                        url="https://i.redd.it/$id.jpg"
                        wget -q -O "images/$subreddit/$name$id$ext" $url > /dev/null 2>&1 & #download and save the image
                        processed=$(($processed+1))
                        if [ $v -ge 1 ];then
                            tput cuu 1
                            printf "\rDownloading r/$subreddit pics...($processed processed)\033[K\n"
                        fi
                        if [ $v -ge 2 ];then
                            printf -- "${name:0:$(($(tput cols)-25))} $id\033[K"
                        fi
                    done
                fi
            fi
            i=$(($i+1))
        done
        before=$(echo $req | jq -r ".data[(($i-1))].created_utc")
        wait #wait for all processes to end
    done
    find images/$subreddit -size 0 -delete #delete empty images that may have been downloaded
    if [ $v -ge 1 ];then
        tput cuu 1
        printf "\rr/$subreddit done ($processed pics, $(($processed-$onDiskInit)) new)\033[K\n\033[K"
    fi
done

#TODO
#some error message appears sometimes
#make imgTreshold a script parameter
#try to handle porn ads when downloading from badly moderated or old subs