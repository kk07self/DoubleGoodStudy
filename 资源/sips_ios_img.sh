#!/bin/bash

handle_img(){

	for s in ${!iOS_ICON_SIZE_ARRAY[@]};
	do
		logo_path="$iOS_ICON_DIR/$1_${iOS_ICON_SIZE_ARRAY[$s]}"
	    s_2=$[${iOS_ICON_SIZE_ARRAY[$s]}*2]
	    s_3=$[${iOS_ICON_SIZE_ARRAY[$s]}*3]

	    sips -Z ${iOS_ICON_SIZE_ARRAY[$s]} $IMG_PATH --out $logo_path.png
	    sips -Z $s_2  $IMG_PATH --out $logo_path@2x.png
	    sips -Z $s_3  $IMG_PATH --out $logo_path@3x.png  

	done
}


IMG_PATH="1024.png"
iOS_ICON_SIZE_ARRAY=(16 20 29 40 50 57 60 72 76 167 216 512 1024)
iOS_ICON_DIR="iOS_logo_set"

if [ -n "$1" ]
then
    IMG_PATH="$1.png"
else
    echo "please input source logo name. eg: 1024. Size:1024x1024."
fi


mkdir -p $iOS_ICON_DIR
handle_img $1;
