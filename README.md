#kaldi-ios-pos
NOTE: Kaldi-iOS version 0.3.1, with a few bug fixes and couple of new features is available for download from http://keenresearch.com/kaldi-ios-framework. 

A proof-of-concept app that shows how to run Kaldi-iOS automated speech recognition framework. For more details see http://keenresearch.com/kaldi-ios-framework.

The demo uses acoustic models in librispeech-nnet2-en-us directory (http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/exp/nnet2_online/nnet_ms_a_online). Aternatively, you can use gmm decoder and models in librispeech-gmm-en-us directory (tri1 librispeech models; will be updated with better models soon).

Three different demos are provided in this proof of concept app:

1. Music library voice control: your music library will be loaded and song names and artist names will be used to create a custom decoding graph

2. Contacts voice control: your contacts will be loaded and first/last name will be used to create a custom decoding graph

3. Educational Reading Demo: demonstrates ASR use for following users reading aloud, but highlighting words as they are read. Oral reading rate of speech is computed in real time. Additional information related to oral reading fluency will be available in future releases.



