//
//  KaldiTest.cpp
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 11/14/14.
//  Copyright (c) 2014 Keen Research. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "KaldiTest.h"

#include "feat/wave-reader.h"
#include "online2/online-nnet2-decoding.h"
#include "online2/onlinebin-util.h"
#include "online2/online-timing.h"
#include "online2/online-endpoint.h"
#include "fstext/fstext-lib.h"
#include "lat/lattice-functions.h"




void KaldiTest::RunTest() {
  using namespace std;
  using namespace kaldi;
  using namespace fst;

//  typedef kaldi::int32 int32;
//  typedef kaldi::int64 int64;
  
  ParseOptions po("");
  
  
  BaseFloat chunk_length_secs = 0.05;
  bool do_endpointing = false;
  bool online = true;
  NSString *nnet2_rxfilename = @"final.mdl";
  NSString *fst_rxfilename = @"HCLG.fst";
  NSString *word_syms_rxfilename = @"words.txt";

  NSString *filename = @"mon-wed-fri.wav";

  OnlineEndpointConfig endpoint_config;
  // feature_config includes configuration for the iVector adaptation,
  // as well as the basic features.
  OnlineNnet2FeaturePipelineConfig feature_config;
  OnlineNnet2DecodingConfig nnet2_decoding_config;
  
  feature_config.Register(&po);
  nnet2_decoding_config.Register(&po);
  endpoint_config.Register(&po);
  
  /*
   ../src/online2bin/online2-wav-nnet2-latgen-faster \
   --do-endpointing=false \
   --online=false \
   --config=../nnet_a_gpu_online/conf/online_nnet2_decoding.conf \
   --max-active=7000 \
   --beam=15.0 \
   --lattice-beam=6.0 \
   --acoustic-scale=0.1 \
   --word-symbol-table=data/lang/words.txt \
   ../nnet_a_gpu_online/smbr_epoch2.mdl \
   data/lang/HCLG.fst \
   "ark:echo utterance-id1 utterance-id1|" "scp:echo utterance-id1 test5.wav|" ark:/dev/null
   */
  
  char *argv[] = {"decoder", "--config=online_nnet2_decoding.conf", "--max-active=7000", "--beam=15.0", "--lattice-beam=6.0", "--acoustic-scale=0.1"};
  int argc = sizeof(argv)/sizeof(*argv);
  
  po.Read(argc, argv);
  

  OnlineNnet2FeaturePipelineInfo feature_info(feature_config);
  
  if (!online) {
    feature_info.ivector_extractor_info.use_most_recent_ivector = true;
    feature_info.ivector_extractor_info.greedy_ivector_extractor = true;
    chunk_length_secs = -1.0;
  }
  
  TransitionModel trans_model;
  nnet2::AmNnet nnet;
  {
    bool binary;
    Input ki(nnet2_rxfilename.UTF8String, &binary);
    trans_model.Read(ki.Stream(), binary);
    nnet.Read(ki.Stream(), binary);
  }
  
  fst::Fst<fst::StdArc> *decode_fst = ReadFstKaldi(fst_rxfilename.UTF8String);
  
  fst::SymbolTable *word_syms = NULL;
  if (word_syms_rxfilename != nil) {
    NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
    NSArray *parts = [NSArray arrayWithObjects: bundlePath, word_syms_rxfilename, nil];
    NSString *path = [NSString pathWithComponents:parts];
    const char *cpath = [path fileSystemRepresentation];
    std::ifstream strm(cpath, ifstream::in);
    if (!(word_syms = fst::SymbolTable::ReadText(word_syms_rxfilename.UTF8String, strm)))
      KALDI_ERR << "Could not read symbol table from file "
      << word_syms_rxfilename;
  }
  
  double tot_like = 0.0;
  int64 num_frames = 0;
  
  OnlineTimingStats timing_stats;

  
  NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
  NSArray *parts = [NSArray arrayWithObjects: bundlePath, filename, nil];
  NSString *path = [NSString pathWithComponents:parts];
  const char *cpath = [path fileSystemRepresentation];
  std::string iosFile(cpath);
  std::ifstream file(cpath, std::ios_base::in|std::ios_base::binary);
  WaveData wav;
  wav.Read(file);

  OnlineIvectorExtractorAdaptationState adaptation_state(feature_info.ivector_extractor_info);
  SubVector<BaseFloat> data(wav.Data(), 0);
  
  OnlineNnet2FeaturePipeline feature_pipeline(feature_info);
  feature_pipeline.SetAdaptationState(adaptation_state);
  
  NSLog(@"Initializing decoder");
  SingleUtteranceNnet2Decoder decoder(nnet2_decoding_config,
                                      trans_model,
                                      nnet,
                                      *decode_fst,
                                      &feature_pipeline);
  NSLog(@"Decoder initialized");
  OnlineTimer decoding_timer("wav");
  
  BaseFloat samp_freq = wav.SampFreq();
  int32 chunk_length;
  if (chunk_length_secs > 0) {
    chunk_length = int32(samp_freq * chunk_length_secs);
    if (chunk_length == 0) chunk_length = 1;
  } else {
    chunk_length = std::numeric_limits<int32>::max();
  }
  NSLog(@"Decoding with chunk length %f sec", chunk_length_secs);
  
  int32 samp_offset = 0;
  while (samp_offset < data.Dim()) {
    int32 samp_remaining = data.Dim() - samp_offset;
    int32 num_samp = chunk_length < samp_remaining ? chunk_length
    : samp_remaining;
    
    SubVector<BaseFloat> wave_part(data, samp_offset, num_samp);
    feature_pipeline.AcceptWaveform(samp_freq, wave_part);
    
    samp_offset += num_samp;
    decoding_timer.WaitUntil(samp_offset / samp_freq);
    if (samp_offset == data.Dim()) {
      // no more input. flush out last frames
      feature_pipeline.InputFinished();
    }
    decoder.AdvanceDecoding();
    
    if (do_endpointing && decoder.EndpointDetected(endpoint_config))
      break;
  }
  NSLog(@"Done decoding");

  CompactLattice clat;
  bool end_of_utterance = true;
  decoder.GetLattice(end_of_utterance, &clat);
  NSLog(@"Generated Lattice");

  
  if (clat.NumStates() == 0) {
    KALDI_WARN << "Empty lattice.";
    return;
  }
  CompactLattice best_path_clat;
  CompactLatticeShortestPath(clat, &best_path_clat);
  
  Lattice best_path_lat;
  ConvertLattice(best_path_clat, &best_path_lat);
  
  double likelihood;
  LatticeWeight weight;
//  int32 num_frames;
  std::vector<int32> alignment;
  std::vector<int32> words;
  GetLinearSymbolSequence(best_path_lat, &alignment, &words, &weight);
  num_frames = alignment.size();
  likelihood = -(weight.Value1() + weight.Value2());
  num_frames += num_frames;
  tot_like += likelihood;
  KALDI_VLOG(2) << "Likelihood per frame for utterance is "
  << (likelihood / num_frames) << " over " << num_frames
  << " frames.";
  
  if (word_syms != NULL) {
    std::cerr << "RESULT: ";
    for (size_t i = 0; i < words.size(); i++) {
      std::string s = word_syms->Find(words[i]);
      if (s == "")
        KALDI_ERR << "Word-id " << words[i] << " not in symbol table.";
      std::cerr << s << ' ';
    }
    std::cerr << std::endl;
  }
  
  decoding_timer.OutputStats(&timing_stats);
  
  timing_stats.Print(online);
  
  delete decode_fst;
  delete word_syms; // will delete if non-NULL.
  return;
}

