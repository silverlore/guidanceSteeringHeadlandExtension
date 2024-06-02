#!/bin/bash

INCLUDE="*.xml *.lua *.dds src\vehicles\specialization\*.lua src\vehicles\specialization\event\*.lua src\*.lua translations\*.xml"
ZIP_FILENAME="FS22_GuidanceSteeringHeadlandExt.zip"

zip -r  $ZIP_FILENAME $INCLUDE

