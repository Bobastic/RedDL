Project initially inspired from [Simple-Subreddit-Image-Downloader](https://github.com/ostrolucky/Simple-Subreddit-Image-Downloader)

# RedDL

This simple bash script allows you to download up to around a thousand pictures from a subreddit. You can specify a sort method like *hot* or *top month*. This handles galleries and linked images.

There is a thousand image limitation because I use the native Reddit API. If you want to download every image from a subreddit, use **RedDL+**.

The script will create an **image/** folder in the current directory and put the downloaded images in a dedicated directory in **images/**.

## Usage

`./RedDL.sh -s subreddit`

Use the **-h** flag for a list of all flags.

# RedDL+

Works the same as **RedDL** except it uses the Pushshift API which means you can get *all* the images from a subreddit. Note that you thus can't specify a sort order.

You can set a maximum image amount threshold as well as a minimum upvote ratio for an image to be downloaded to try to *filter out the trash*.

**RedDL+** is much faster than **RedDL** but you also get some *lower quality* images if you are interested in poorly moderated subreddits. When you get to posts that are years old, you can sometimes find porn ads or this kind of stuff. I tried to address the issue with the upvote threshold but it's not perfect.

## Usage

`./RedDL+.sh -s subreddit`

Use the **-h** flag for a list of all flags.

# Requirements

All you need is `bash`, `wget` and `jq`.
