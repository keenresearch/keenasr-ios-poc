#kaldi-ios-pos
NOTE: version 0.3, with support for custom decoding graph building, is available for download from http://keenresearch.com/kaldi-ios-framework. This POC will soon be updated to showcase use of custom decoding graph building.

A proof-of-concept app that shows how to run Kaldi-iOS automated speech recognition framework. For more details see http://keenresearch.com/kaldi-ios-framework.

The demo uses acoustic models in librispeech-gmm-en-us directory (tri1 models from librispeech egs). Aternatively, you can use nnet2 decoder and models in librispeech-nnet2-en-us directory (originally from http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/exp/nnet2_online/nnet_ms_a_online/). Nnet2 consumes about 3x more memory (140MB vs 45MB) and runs slower than GMM decoder.

A simple bigram language model that listens to numbers 1-100 (and couple of other phrases) is used in the app. HCLG file is referenced from the model directory (librispeech-nnet2-en-us/HCLG.fst). You can replace it with a different decoding graph; you  will need to compile it using Kaldi tools and relevant data from http://kaldi-asr.org/downloads/build/10/trunk/egs/librispeech/s5/). Future releases of KaldiIOS framework will allow end users to provide either a grammar file or a bigram language model instead of the decoding graph.




