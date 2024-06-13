# Fadr

## Overview

Fadr is an innovative hair clipping system that uses gyroscope and accelerometer data from AirPods Pro and an iPhone to precisely determine the orientation of your head and the clippers. This technology allows the clippers to automatically adjust their cutting height, removing the need for different guards.

Users can choose from a variety of hairstyles within the Fadr app. Once a style is selected, the app calculates the appropriate cutting heights and directs the clippers to adjust accordingly. (In theory) this system enables anyone to achieve professional-quality haircuts at home, ranging from simple trims to complex fades, without needing barber expertise.

<img width="1336" alt="Screenshot 2024-06-11 at 10 28 18 PM" src="https://github.com/ChinemeremChigbo/Fadr/assets/24593519/7f8f42f0-74d5-4c85-b160-501c03fa0bab">

## Tech
The iPhone is mounted to the clippers to track their position, while the AirPods Pro are placed in the user's ears to track head position. The iOS app rotates a 3D head model according to the relative positions of the AirPods Pro and the iPhone. The head model is colored in a gradient of grey, representing the hair length to cut (darker grey indicates longer hair, and lighter grey indicates shorter hair). As the 3D head model rotates, Fadr extracts the gradient color height information from the center point of the model on the screen, similar to an eyedropper tool. Fadr then starts a BLE server on an ESP32 microcontroller and sends the height information to the microcontroller. This data controls a servo or linear actuator, which adjusts the cutting height of the clippers on the user's head.
