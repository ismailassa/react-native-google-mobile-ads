#!/bin/bash
set -e

echo "You should run this from directory where you have cloned the react-native-google-ads repo"
echo "You should only do this when your git working set is completely clean (e.g., git reset --hard)"
echo "You must have already run \`yarn\` in the repository so \`npx react-native\` will work"
echo "This scaffolding refresh has been tested on macOS, if you use it on linux, it might not work"

# Copy the important files out temporarily
if [ -d TEMP ]; then
  echo "TEMP directory already exists - we use that to store files while refreshing."
  exit 1
else
  echo "Saving files to TEMP while refreshing scaffolding..."
  cp example/.mocharc.js TEMP/
  cp example/.detoxrc.json TEMP/
  mkdir -p TEMP/android/app/src/androidTest/java/com/example
  cp android/app/src/androidTest/java/com/example/DetoxTest.java TEMP/android/app/src/androidTest/java/com/example/
  mkdir -p TEMP/e2e
  cp -r e2e/* TEMP/e2e/
  cp example/app.json TEMP/
  #cp example/App.js TEMP/
fi

# Purge the old sample
\rm -fr example

# Make the new example
npx react-native init example --version=0.66.0-rc.1
pushd example
yarn add 'link:../'
yarn add detox mocha --dev

# Java build tweak - or gradle runs out of memory during the build
echo "Increasing memory available to gradle for android java build"
echo "org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> android/gradle.properties

# Detox + Android
echo "Integrating Detox for Android (maven repo, dependency, build config items, kotlin...)"
sed -i -e $'s/mavenLocal()/mavenLocal()\\\n        maven \{ url "$rootDir\/..\/node_modules\/detox\/Detox-android" \}/' android/build.gradle
sed -i -e $'s/ext {/ext {\\\n        kotlinVersion = "1.5.30"/' android/build.gradle
sed -i -e $'s/dependencies {/dependencies {\\\n        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion"/' android/build.gradle
rm -f android/build.gradle??
sed -i -e $'s/dependencies {/dependencies {\\\n    androidTestImplementation("com.wix:detox:+")/' android/app/build.gradle
sed -i -e $'s/defaultConfig {/defaultConfig {\\\n        testBuildType System.getProperty("testBuildType", "debug")\\\n        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"/' android/app/build.gradle
rm -f android/app/build.gradle??


# run pod install after installing our module
cd ios && pod install && cd ..

# Copy the important files back in
popd
echo "Copying Google Ads example files into refreshed example..."
cp -frv TEMP/.* example/
cp -frv TEMP/* example/

# Clean up after ourselves
\rm -fr TEMP