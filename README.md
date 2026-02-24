# Piano Assistant
## An app to make you better at musical instruments, easier
### Bluetooth MIDI Device required, and currently only supports MacOS

This app uses an open source Music Recognition model, Audiveris, to automatically scan and process sheet music visually into data, that can be used to help you play and practice your song of choice. Simply input a piece of sheet music to scan, and it will give you a song you can play, with notes highlighted and which notes to play displayed. This allows you to not only practice the song at your own pace, but also makes sure you learn the song properly along the way.

## Current Features:
* Connect to and read packets from a BluetoothMIDI capable device for processing.
* Scan sheet music using a Command Line Interface with Audiveris.
* Parse MusicXML files to extract necessary note, measure, and page information.
* Persistently stores both note data, and images of the sheet music.
* Play your sheet music with highlighted notes, and displaying what notes to press via text.

## Audiveris
Audiveris is an Open Source Music Recongition tool. Their github repo is linked below.
https://github.com/Audiveris/audiveris


Future Plans:
* Properly implement the use of volta brackets
* Create sight reading quizes, no annotations or help during play
* Show where the user pressed wrong notes by overlaying the mistakes onto the sheet music for review
* Auto connect to previously connected devices, and allow connections to be made during app runtime
* Regenerate sheet music via Audiveris to ensure clean sheet music is displayed.
* iOS support
* Transfer pre-processed song data to iOS app via Bluetooth to play songs on mobile devices
