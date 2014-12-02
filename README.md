#kaldi-ios-pos
A simple proof of concept demo of running Kaldi ASR decoder on iOS. It's based on Kaldi online2-wav-nnet2-latgen-faster binary and in its current form it runs ASR on a (hard-coded) wav file, which is part of the app. All the ASR dependencies (models, grammars, etc.) are also part of the application. All of the Kaldi related functionality is contained in KaldiTest class.

The proof of concept demo doesn't work with the live audio, nor it provides an Objective C wrapper/interface for Kaldi. Exception and error handling is not handled at all, so if you are missing some resources, the app will quit with an exception (check the console for Kaldi error output).

A simple example grammar that listens for a day of week is used in the app. It runs in reasonable (close to real) time on an iPhone 5.

"ASR Resources" group contains all the necessary resources (config files, models, etc.). Paths in the config files were edited so they reference filenames directly.

"WAVs" group contains a few wav files (16bps, 8kHz) which you can use to run the recognition. A variable named 'filename' in KaldiTest.mm contains path to the wav file.

"kaldi-util" group contains two kaldi source files and corresponding header files that were modified to address IO on the iOS platform. These files will take presedence over the same .o files in the kaldi static library.

"includes" group contains OpenFST and Kaldi include files.

The project already includes openfst.a static library; Kaldi static library is too large for github, so you will need to compile it and add it to the project by following directions below. Both libraries are currently built only for the device, so the simulator build won't work. 

##Steps for building OpenFST and Kaldi libraries for iOS

Download Kaldi source code in kaldi/ directory and this project in kaldi-ios-pos/ directory.

###Building Kaldi iOS Library
1) Build Kaldi dependencies for Mac OS first

    cd kaldi-trunk/tools/
    make

2) Build kaldi static library

    cd kaldi-trunk/src
    cp kaldi-ios-poc/extras/build-kaldi-ios.sh .
    ./configure
    ./build-kaldi-ios.sh iphone

You can also direct compiler to optimize the code (CXXFLAGS = "-O3 -DNDEBUG")

###Building OpenFST iOS Library
```
cd kaldi-trunk/tools/
cp kaldi-ios-pos/extras/build-openfst-ios.sh .
./build-openfst-ios.sh
```
Add the following ReadText method to the symbol-table.h file (either in kaldi-trunk/tools/openfst/src/include/fst/symbol-table.h or when you add these files to the iOS project):
```
static SymbolTable* ReadText(const string& filename, ifstream& strm,
                            const SymbolTableTextOptions &opts = SymbolTableTextOptions()) {
     if (!strm) {
      LOG(ERROR) << "SymbolTable::ReadText: Can't open file ";
       return 0;
     }
     return ReadText(strm, filename, opts);
}
```
(TODO - symbol-table.h update should be done in build-openfst-ios.sh script)

##App Build Settings
- check Search Paths for all the additional paths that need to be set
- Language - C++, dialect is set to GNU++11, and C++ Standard Library to libstdc++
- Preprocessor Macros: HAVE_POSIX_MEMALIGN=1 HAVE_CLAPACK=1
