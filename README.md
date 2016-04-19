#kaldi-ios-pos
A demo of running Kaldi ASR decoder on iOS based on KaldiIOS framework, our port of Kaldi to iOS. For more details see http://keenresearch.com/kaldi-ios-framework.

The app uses acoustic models in librispeech-nnet2 directory (originally from http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/exp/nnet2_online/nnet_ms_a_online/)

A simple bigram language model that listens to numbers 1-100 is used in the app. HCLG file is currently hard-coded and referenced from the model directory (librispeech-nnet2/HCLG.fsts). You can replace it with a different language model; you  will need to compile HCLG using Kaldi tools and relevant data from http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/).

The KaldiIOS framework also supports GMM recognizer. We are planning to add acoustic models that showcase the use of the GMM recognizer.



