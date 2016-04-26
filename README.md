#kaldi-ios-pos
A demo of running Kaldi ASR decoder on iOS, based on KaldiIOS framework, our port of Kaldi to iOS. For more details see http://keenresearch.com/kaldi-ios-framework.

The demo uses acoustic models in librispeech-gmm directory (tri1 models from librispeech egs). Aternatively, you can use nnet2 decoder and models in librispeech-nnet2 directory (originally from http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/exp/nnet2_online/nnet_ms_a_online/). Nnet2 consumes about 3x more memory (140MB vs 45MB) and runs slower than GMM decoder.

A simple bigram language model that listens to numbers 1-100 (and couple of other phrases) is used in the app. HCLG file is referenced from the model directory (librispeech-nnet2/HCLG.fsts). You can replace it with a different language model; you  will need to compile HCLG using Kaldi tools and relevant data from http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/). Future releases of KaldiIOS framework will provide end users to provide either a grammar file or a bigram language model.




