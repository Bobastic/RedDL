# RedDL

Project initially inspired from [Simple-Subreddit-Image-Downloader](https://github.com/ostrolucky/Simple-Subreddit-Image-Downloader)

This simple bash script allows you to download up to around a thousand pictures from a subreddit. You can specify a sort method like *hot* or *top month*. This handles galleries and linked images.

There is a thousand image limitation because I use the native Reddit API. If you want to download every image from a subreddit, use **RedDL+** which works with the Pushshift API.

The script will create an **image/** folder in the current directory and put the downloaded images in a dedicated directory in **images/**.

# Usage

./RedDl.sh -s subreddit

Use the **-h** flag for more precise information.
