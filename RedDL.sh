#!/bin/bash

#default arguments
sort="top"
time="all"
sub=$(mkdir -p images;ls images) #by default update all already downloaded subreddits
v=2 #verbose level

#check flags
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: ./RedDL.sh [-s SUBREDDIT] [--sort ORDER] [--time TIME] [-v LEVEL]"
            echo ""
            echo "Creates an images/ folder in current directory filled with folders with the"
            echo "name of each subreddit you download from. Inside these folders will be all the"
            echo "images from the image and gallery posts of this subreddit. If no subreddit is"
            echo "specified when calling RedDL, updates the contents of folders of the subreddits"
            echo "you already downloaded from."
            echo ""
            echo "OPTIONS:"
            echo " -s, --subreddit SUBREDDIT         Target SUBREDDIT. If not specified, and"
            echo "                                    if possible, download from previously"
            echo "                                    downloaded subreddits."
            echo " --sort <new|hot|rising|top>       Sort order. DEFAULT: top"
            echo " --time <all|year|month|week|day>  Period of time. Only useful if --sort is"
            echo "                                    top. DEFAULT: all"
            echo " -v, --verbose <0|1|2>             Verbose level. No output at 0, subreddit"
            echo "                                    at 1, and subreddit and image name at 2."
            echo "                                    DEFAULT: 2"
            echo ""
            echo "EXAMPLES:"
            echo " ./RedDL.sh -s kitty               Download the images from the r/kitty"
            echo "                                    subreddit to images/kitty."
            echo " ./RedDL.sh -s kitty --sort new    Download the images by new"
            echo " ./RedDL.sh -s kitty --sort new --time day"
            echo "                                   Same as above (--time ignored)"
            echo " ./RedDL.sh -s kitty --sort top --time day"
            echo "                                   Download the images by top of day"
            echo " ./RedDL.sh                        Download the images from all of the"
            echo "                                    subreddits in images/."
            echo " ./RedDL+.sh -v 1                  Same as above without printing image names."
            echo ""
            echo "NOTICE:"
            echo "This script uses the native Reddit API which limits the maximum amount of posts"
            echo "you can get to 1000. If you want to download all of the images of a subreddit"
            echo "use RedDL+."
            exit 0
            ;;
        -s|--subreddit)
            shift
            sub=$1
            shift
            ;;
        --sort)
            shift
            case "$1" in
                new|hot|rising|top) sort=$1;;
                *) echo "You can't sort by $1! Valid arguments: new hot rising top";exit 1;;
            esac
            shift
            ;;
        --time)
            shift
            case "$1" in
                all|year|month|week|day) time=$1;;
                *) echo "You can't sort by top of $1! Valid arguments: all year month week day";exit 1;;
            esac
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
            echo "$1 is not a recognized flag! HELP: ./RedDL.sh -h"
            exit 1
            ;;
    esac
done 

if [ -z "$sub" ];then
    echo "You don't have any subreddit folder to update. Add a subreddit as an argument. HELP: ./RedDL.sh -h"
    exit 1
fi

if [ $(c() { echo $#; };c $sub;unset -f c) -gt 1 ] && [ $v -ge 1 ];then
    echo "Updating pics from: "$sub". HELP: ./RedDL.sh -h"
fi

for subreddit in $sub;do
    mkdir -p "images/$subreddit"
    after=""
    if [ $v -ge 1 ];then
        printf "Downloading r/$subreddit pics...\n"
    fi
    processed=0
    while [ "$after" != "null" ];do
        req=$(wget -q -O - "https://www.reddit.com/r/$subreddit/$sort.json?limit=100&t=$time&after=$after&raw_json=1" 2>&1) #get a batch of 100 posts (the maximum possible in one request)
        npics=$(echo $req | jq -r ".data.dist")
        i=0
        while [ $i -lt $npics ];do #for each post
            if [ $(echo $req | jq -r ".data.children[$i].data.post_hint?") == "image" ];then #if it is a standard image post
                url=$(echo $req | jq -r ".data.children[$i].data.url")
                ext=${url: -4:4}
                id=$(echo $req | jq -r ".data.children[$i].data.id")
                name=$(echo $req | jq -r ".data.children[$i].data.title")
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
            elif [ $(echo $req | jq -r ".data.children[$i].data.is_gallery?") == "true" ];then #if this is a gallery
                ids=$(echo $req | jq -r ".data.children[$i].data.media_metadata | keys[]")
                name=$(echo $req | jq -r ".data.children[$i].data.title")
                name="${name//\// }"
                name="${name:0:200}"
                for id in $ids;do #for each image of the gallery
                    ext=$(echo $req | jq -r ".data.children[$i].data.media_metadata[\"$id\"].m")
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
            i=$(($i+1))
        done
        after=$(echo $req | jq -r ".data.after")
        wait #wait for all processes to end
    done
    if [ $v -ge 1 ];then
        tput cuu 1
        printf "\rr/$subreddit done ($processed pics)\033[K\n\033[K"
    fi
done
