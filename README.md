# VxWorks Layer for Google Cloud IoT Core

## Overview

This document provides a quick summary of how to build and run the **Google Cloud IoT Core** device software development kit (SDK) for C that resides in VxWorks 7 on your device. The SDK is an embedded C client library for interacting with the Google Cloud IoT platform. This client library is not provided in VxWorks 7 RPM packages or on the VxWorks 7 product DVDs. You need to manually install this library on VxWorks 7.

Release note:
    The version 1.0.0.x has been validated with VxWorks 7 SR0610.

### Project License

The license for this project is the BSD-3-Clause. Text of BSD-3-Clause license and other applicable license notices can be found in the LICENSE_NOTICES.txt file in the top level directory. Each source files should include a license notice that designates the licensing terms for the respective file.

Note the mbed TLS is under the Apache 2.0 license.

### Prerequisite

You must have a Google account to try the samples.  To create a free account on Google please visit: https://console.cloud.google.com/freetrial

Before installing the SDK prepare the development environment.
1. Install git and ensure it operates from the command line.
2. Ensure the VxWorks 7 DVD is installed.
3. Ensure the **Google Cloud IoT** device SDK for C source code is available from the following location:

   https://github.com/GoogleCloudPlatform/iot-device-sdk-embedded-c

## Installing the SDK

1. Download the **VxWorks 7 Google Cloud IoT SDK** layer from the following location:

   https://github.com/Wind-River/vxworks7-layer-for-google-cloud-iot-core-sdk

2. Set WIND_LAYER_PATHS to point to the vxworks7-layer-for-google-cloud-iot-core-sdk directory. Command-line users may set this directly using export on Linux or set on Windows. Developers working on a Microsoft Windows host may also set the system environment variables. On Microsoft Windows 10, these can be found in the Control Panel under View advanced system Settings. Click the "Advanced" tab to find the "Environment Variables" button. From here you may set WIND_LAYER_PATHS to point to the vxworks7-layers-for-google-cloud-iot-core-sdk. Please refer to the VxWorks documentation for details on the WIND_LAYER_PATHS variable.
2. Confirm the layer is present in your VxWorks 7 installation. In a VxWorks development shell, you may run "vxprj vsb listAll" and look for GOOGLE_IOT_SDK_1_0_0_0 to confirm that the layer has been found.

## Creating the VSB and VIP Using WrTool

Create the VxWorks 7 VxWorks source build (VSB) and VxWorks image project (VIP) using either the Wind River Workbench environment or the command line tool **WrTool**. This procedure uses the *vxsim_linux* board support package (BSP) as an example.

1. Set the environment variable and change the directory.

        export WIND_WRTOOL_WORKSPACE=$HOME/WindRiver/workspace
        cd $WIND_WRTOOL_WORKSPACE

2. Create the VSB using the **WrTool**.

        wrtool prj vsb create -force -bsp vxsim_linux myVSB -S
        cd myVSB
        wrtool prj vsb add GOOGLE_IOT_SDK
        make -j[jobs]  <-- set the number of parallel build jobs, typically 2, 4, 8
        cd ..

3. Create the VIP using the **WrTool**.

        wrtool prj vip create -force -vsb myVSB -profile PROFILE_STANDALONE_DEVELOPMENT vxsim_linux llvm myVIP
        cd myVIP
        wrtool prj vip component add INCLUDE_SHELL INCLUDE_NETWORK INCLUDE_IFCONFIG INCLUDE_PING INCLUDE_IPDNSC
        wrtool prj vip component add INCLUDE_POSIX_PTHREAD_SCHEDULER  INCLUDE_DEFAULT_TIMEZONE
        wrtool prj vip parameter set DNSC_PRIMARY_NAME_SERVER   "\"1.1.1.1\""
        wrtool prj vip parameter set DNSC_SECONDARY_NAME_SERVER "\"1.0.0.1\""
        cd ..

The test sample is provided in the Google Cloud IoT Core device SDK for C as *examples/iot_core_mqtt_client/src/iot_core_mqtt_client.c*. It can be used to connect your device to the Google Cloud IoT Core service, publish telemetry to the cloud and to receive commands from the Google Cloud IoT service. To enable this sample, you need to create an RTP project.

## Creating the RTP Using WrTool

1. Create an RTP project based on myVSB.

        wrtool prj rtp create -vsb myVSB myRTP

2. Add the file for iot_core_mqtt_client

        wrtool prj file add $WIND_WRTOOL_WORKSPACE/myVSB/3pp/GOOGLE_IOT_SDK/googleiotembedded_c/examples/iot_core_mqtt_client/src/iot_core_mqtt_client.c

3. Delete the sample rtp.c file

        wrtool prj file delete rtp.c

4. Add additional sample source code and header files.

        wrtool prj file add $WIND_WRTOOL_WORKSPACE/myVSB/3pp/GOOGLE_IOT_SDK/googleiotembedded_c/examples/common/src/commandline.h
        wrtool prj file add $WIND_WRTOOL_WORKSPACE/myVSB/3pp/GOOGLE_IOT_SDK/googleiotembedded_c/examples/common/src/commandline.c
        wrtool prj file add $WIND_WRTOOL_WORKSPACE/myVSB/3pp/GOOGLE_IOT_SDK/googleiotembedded_c/examples/common/src/example_utils.h
        wrtool prj file add $WIND_WRTOOL_WORKSPACE/myVSB/3pp/GOOGLE_IOT_SDK/googleiotembedded_c/examples/common/src/example_utils.c

5. Add the certificates

	Follow the instructions from the Google Cloud documentation to generate an ES256 key pair. https://cloud.google.com/iot/docs/how-tos/credentials/keys

	Import the two files ec_private.pem and ec_public.pem into your example. The commands below assume that the files were generated in your home directory.

        wrtool prj file add $HOME/ec_private.pem
        wrtool prj file add $HOME/ec_public.pem

6. Add the include directories.

        wrtool prj include add '-I$(PRJ_ROOT_DIR)' myRTP
        wrtool prj include add '-I$(VSB_DIR)/share/h' myRTP
        wrtool prj include add '-I$(VSB_DIR)/usr/h/published/UTILS' myRTP

5. Add the usr/lib/common library directory.

        wrtool prj lib add '-L$(VSB_DIR)/usr/lib/common' myRTP

6. Add the static library dependencies.

        wrtool prj lib add '-liotc' myRTP
        wrtool prj lib add '-lunix' myRTP
        wrtool prj lib add '-lnet' myRTP
        wrtool prj lib add '-lmbedtls' myRTP
        wrtool prj lib add '-lmbedx509' myRTP
        wrtool prj lib add '-lmbedcrypto' myRTP

7. Build the RTP

        wrtool prj build myRTP

8. Deploy it to your target with the certificate files.

9. Follow the instructions on the "Quickstart" to set up the Goolge Cloud IoT Core service.

    https://cloud.google.com/iot/docs/quickstart

10. Execute the RTP with arguments specifying details from your Google IoT Cloud account. From a command shell it would appear as follows:

    /romfs/iot_core_mqtt_client.vxe -p "<PROJECT_NAME>" -d "projects/<PROJECT_NAME>/locations/<REGION>/registries/<REGISTRY_NAME>/devices/<DEVICE_ID>" -t "/devices/<DEVICE_ID>/state" -f "/romfs/ec_private.pem"

## Viewing the Device Information on the Google IoT Dashboard

You can run your device image with the Google IoT SDK and then view the device
information dashboard at the Google IoT website.

* For information on what Google IoT is, see the following information:

  https://cloud.google.com/iot/docs/

* For information on how to use the C SDK, see the following information:

  https://github.com/GoogleCloudPlatform/iot-device-sdk-embedded-c

### Legal Notices

All product names, logos, and brands are property of their respective owners. All company, product and service names used in this software are for identification purposes only. Wind River and VxWorks are a registered trademarks of Wind River Systems. Google and Google Cloud  are registered trademarks of the Google Corporation.

Disclaimer of Warranty / No Support: Wind River does not provide support and maintenance services for this software, under Wind River’s standard Software Support and Maintenance Agreement or otherwise. Unless required by applicable law, Wind River provides the software (and each contributor provides its contribution) on an “AS IS” BASIS, WITHOUT WARRANTIES OF ANY KIND, either express or implied, including, without limitation, any warranties of TITLE, NONINFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the software and assume ay risks associated with your exercise of permissions under the license.
