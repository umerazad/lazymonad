jekyll build
s3cmd sync --delete-removed _site/ s3://www.lazymonad.com/ --verbose
s3cmd setacl s3://www.lazymonad.com/ --acl-public --recursive