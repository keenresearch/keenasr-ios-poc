## Note

This proof-of-concept app ships with a trial version of KeenASR framework, which will exit (crash) the app 15min after the framework has been initialized. If you would like to obtain a version of the framework without this limitation, contact us at info@keenresearch.com.

By cloning this repository and downloading the trial KeenASR SDK or ASR Bundle you agree to the [KeenASR SDK Trial Licensing Agreement](https://keenresearch.com/keenasr-docs/keenasr-trial-sdk-licensing-agreement.html)

For more details about the SDK see: http://keenresearch.com/keenasr-docs

**Important:** 
- You will need [git-lfs](https://git-lfs.github.com/) to checkout the project
- You will need to clone the repository, **Zip download WILL NOT WORK since we use git-lfs for large file management**. After cloning the repository, you will need to **set/change the bundle id** for the app (currently set to com.keenresearch.com.keenasr-ios-poc), as well as **signing settings** in XCode project settings. These settings are under project build settings, General tab->Identity.

## KeenASR Proof-of-Concept App

A proof-of-concept app that shows how to run KeenASR automatic speech recognition framework. For detailed information on all classes and methods, consult the [SDK reference documentation](http://keenresearch.com/keenasr-docs). If starting with the framework from scratch, check our [Quick Start](http://keenresearch.com/keenasr-docs/docs/additional-docs/Quick-Start.html) document.

This demo app uses acoustic models in keenB2mQT-nnet3chain-en-us directory. Keen Research provides a number of custom acoustic models to its clients.

Six different demos are provided in this proof of concept app:

1. Music library voice control: your music library will be loaded and song names and artist names will be used to create a custom decoding graph

2. Contacts voice control: your contacts will be loaded and first/last name will be used to create a custom decoding graph

3. Educational Reading Demo: demonstrates ASR use for following users reading aloud, by highlighting words as they are read. Oral reading rate of speech is computed in real time. Additional information related to oral reading fluency will be available in future releases.

4. Educational Words Demo: demonstrates ASR use for recognizing individual words. A set of ~1000 most common words for children is used to create a decoding graph. User can say the word itself of "How do you spell \<WORD\>" or "Spell \<WORD\>" and the word will be displayed on the screen.

5. Command and Control Demo: demonstrates how to use the framework for simple command and control app, for example, a robot control.

6. File Recognition Demo: demonstrates how to use the framework to recognize audio from the wav file.
