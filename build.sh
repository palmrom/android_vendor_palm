#! /bin/bash

# Copyright 2017 JDCTeam
# Copyright 2018 Palm Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#########################################################################
#
#



THISDIR=$PWD
ROM_NAME="Palm Project"
VARIANT=userdebug
CM_VER=14.1
OUT="out/target/product/cheeseburger"
TARGET="cheeseburger"
FILENAME=PalmProject-"$CM_VER"-"$(date +%Y%m%d)"-"$TARGET"
AROMA_DIR=aroma

buildROM() {	
	cd $PWD
	read -p "Going to Build...Use ccache? (y/n)";
	if [ "$REPLY" == "y" ]; then
		export USE_CCACHE=1
	fi;

	#Cheeseburger building
	if [ "$TARGET" == "cheeseburger" ]; then
	
		echo "Building..."
		brunch cheeseburger
		echo ""
		echo ""
		if [ "$?" == 0 ]; then
			echo "Build done"
		else
			echo "Build failed"
		fi
	fi




}

doRefresh() {	
 	read -p "Refresh build dir? (y/n)";
	if [ "$REPLY" == "y" ]; then
		echo "Refreshing build dirs..."
		rm -rf build
		repo sync build
		repo sync build/soong
		repo sync build/kati
		repo sync build/blueprint
	fi	
}

anythingElse() {
    echo " "
    echo " "
    echo "Anything else?"
    select more in "Yes" "No"; do
        case $more in
            Yes ) bash build.sh; break;;
            No ) exit 0; break;;
        esac
    done ;
}

deepClean() {
    echo " "
    echo " "
        read -t 3 -p "Clean ccache? 3 sec timeout? (y/n)";
	if [ "$REPLY" == "y" ]; then
		ccache -C
		ccache -c
	fi;
	echo "Making clean"
	make clean
	echo "Making clobber"
	make clobber
	
}

upstreamMerge() {
	echo "Refreshing manifest"
	repo init -u git://github.com/palmrom/manifests.git -b palm-7.1
	echo "Syncing projects"
	repo sync --force-sync
	
	
        echo "Upstream merging"
        # Our snippet/manifest
        ROOMSER=.repo/manifests/snippets/palm.xml
        # Lines to loop over
        CHECK=$(cat ${ROOMSER} | grep -e "<remove-project" | cut -d= -f3 | sed 's/revision//1' | sed 's/\"//g' | sed 's|/>||g')

        # Upstream merging for forked repos
        while read -r line; do
           echo "Upstream merging for $line"
           rm -rf $line
	   repo sync $line
	   cd "$line"
	   git branch -D palm-7.1
	   git checkout -b palm-7.1
           UPSTREAM=$(sed -n '1p' UPSTREAM)
           BRANCH=$(sed -n '2p' UPSTREAM)

            git pull https://www.github.com/"$UPSTREAM" "$BRANCH"
            git push origin palm-7.1
            croot
        done <<< "$CHECK"
	
	croot
      

}

useAroma() {
    LOG="Unzipping files to repack with AROMA..."/$(date +"%T")
    if [ ! -d "$AROMA_DIR" ]; then
	echo "No AROMA directory found.Please check your sources"
	break;
    fi
    FILENAME=PalmProject-"$CM_VER"-"$(date +%Y%m%d)"-"$TARGET"-AROMA
    echo " "
    LATEST=$(ls -t $OUT | grep -v .zip.md5 | grep .zip | head -n 1)
    TEMP2=tmpAroma
    if [ -d "$TEMP2" ]; then 
    rm -rf "$TEMP2"
    fi
    echo "Removing previous Aroma Builds"
    rm -rf Palm*.zip
    rm -rf Palm*.md5
    mkdir "$TEMP2"
    echo "Unpacking ROM to temp folder"
    unzip -q "$OUT"/"$LATEST" -d "$TEMP2"
    echo "Removing META-INF folder"
    rm -rf "$TEMP2"/META-INF
    echo "Copying Aroma Installer"
    cp -r "$AROMA_DIR"/palm "$TEMP2"/palm
    cp -r "$AROMA_DIR"/xbin "$TEMP2"/xbin
    cp -r "$AROMA_DIR"/META-INF "$TEMP2"/META-INF
    cd "$TEMP2"
    echo "Repacking ROM"
    zip -rq9 ../"$FILENAME".zip *
    cd ..
    echo "Creating MD5"
    md5sum "$FILENAME".zip > "$FILENAME".zip.md5
    echo "Cleaning up"
    rm -rf "$TEMP2"
	echo " "
    echo "-- Done.. Added AROMA.. Build finished successfully!"
    LOG="Added AROMA. Build finished successfully!"/$(date +"%T")

}


echo " "
echo " "
echo " "
echo " "
echo " "
echo -e "\e[1;92m--= \e[1;95mWelcome to the $ROM_NAME build script\e[1;92m =--"
echo -e "\e[0m "
echo " "
echo -e "\e[1;96mPlease make your selections carefully"
echo -e "\e[0m "
echo " "
. build/envsetup.sh > /dev/null
echo " " 
echo " "
select build in "Deep clean (inc. ccache)" "Build ROM" "Add Aroma Installer to ROM" "Refresh manifest,repo sync and upstream merge" "Deep Clean,Refresh Build,Build,No Aroma" "Deep Clean,Refresh Build,Build,Add Aroma"    "Exit"; do
	case $build in
		"Deep clean (inc. ccache)" ) deepClean; anythingElse; break;;
		"Build ROM" ) buildROM; useAroma; anythingElse; break;;
		"Add Aroma Installer to ROM" ) useAroma; anythingElse; break;;
		"Refresh manifest,repo sync and upstream merge" ) upstreamMerge; anythingElse; break;;
		"Deep Clean,Refresh Build,Build,No Aroma"  ) deepClean; doRefresh; buildROM; anythingElse; break;;
		"Deep Clean,Refresh Build,Build,Add Aroma"  )  deepClean; doRefresh; buildROM; useAroma; anythingElse; break;;
		"Exit" ) exit 0; break;;
	esac
done
exit 0
