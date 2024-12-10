**WE ARE HIRING:** https://keenresearch.com/careers.html

## Note

This proof-of-concept app ships with a trial version of KeenASR framework, which will exit (crash) the app 15min after the framework has been initialized. If you would like to obtain a version of the framework without this limitation, contact us at info@keenresearch.com.

By cloning this repository and downloading the trial KeenASR SDK or ASR Bundle you agree to the [KeenASR SDK Trial Licensing Agreement](https://keenresearch.com/keenasr-docs/keenasr-trial-sdk-licensing-agreement.html)

For more details about the SDK see: http://keenresearch.com/keenasr-docs

## KeenASR Proof-of-Concept App

A proof-of-concept app that shows how to run KeenASR automatic speech recognition framework. For detailed information on all classes and methods, consult the [SDK reference documentation](http://keenresearch.com/keenasr-docs). If starting with the framework from scratch, check our [Quick Start](http://keenresearch.com/keenasr-docs/docs/additional-docs/Quick-Start.html) document.

This demo app uses acoustic models in keenB2mQT-nnet3chain-en-us directory. Keen Research provides variety of custom acoustic models to its clients.

Six different demos are provided in this proof of concept app:

1. Educational Reading Demo: demonstrates ASR use for following users reading aloud, by highlighting words as they are read. Oral reading rate of speech is computed in real time. Additional information related to oral reading fluency will be available in future releases.

2. Educational Words Demo: demonstrates ASR use for recognizing individual words. A set of ~1000 most common words for children is used to create a decoding graph. User can say the word itself of "How do you spell \<WORD\>" or "Spell \<WORD\>" and the word will be displayed on the screen.

3. Command and Control Demo: demonstrates how to use the framework for simple command and control app, for example, a robot control.
