# AutoPhrase + Stanford POS Tagger

-------


My attempt to change unstable POS tagger to stanford [AutoPhrase](https://github.com/shangjingbo1226/AutoPhrase).<br>

Currently only English is supported.<br>

Please download [full Stanford POS tagger with English model](https://nlp.stanford.edu/software/tagger.shtml) and provide path in `tokenize_raw.sh`:<br>

```
STANFORD_POS_TAGGER_PATH="/home/hcl/Documents/work/keyword-algorithms/stanford-corenlp-full-2017-06-09/stanford-postagger-full-2017-06-09"

```
It takes much longer to process, for 2GB corpus:
```
Tagged 459209610 words at 111480.29 words per second.
Pos tagging took 68 minutes and 40 seconds
```

Working file `bash auto_phrase_stanford.sh <path to txtfile with data>`. <br>
Please convert your source English text to ASCII first:<br>
```
iconv -f UTF8 -t ASCII//TRANSLIT input_txt > input_ascii.txt
```


All the preparations of temporary files are very inefficient and done in bash which involves creation of many copies of the data. My goal was to show it's working.<br>

`wc -l` shows different length of `case_tokenized_train.txt` and `raw_tokenized_train.txt`, this might lead to errors, don't know why it is so at the moment. You may want to just check `tokenize_raw.sh` to understand what's going on and what files are prepared, and write your own less costy implementation in, say, Python.<br>


You can run it with toy dataset (will be automatically downloaded). **Output resides in `models/DBLP/*.txt`.**

```
~/AutoPhrase(master)$ bash auto_phrase_stanford.sh data/DBLP.txt 
===Compilation===
mkdir -p bin
g++ -std=c++11 -Wall -O3 -msse2  -fopenmp  -I.. -pthread -lm -Wno-unused-result -Wno-sign-compare -Wno-unused-variable -Wno-parentheses -Wno-format -o bin/segphrase_train src/main.cpp
g++ -std=c++11 -Wall -O3 -msse2  -fopenmp  -I.. -pthread -lm -Wno-unused-result -Wno-sign-compare -Wno-unused-variable -Wno-parentheses -Wno-format -o bin/segphrase_segment src/segment.cpp
===Downloading Toy Dataset===
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  198M  100  198M    0     0  30.7M      0  0:00:06  0:00:06 --:--:-- 35.4M
===Tokenization===
Detected Language: EN
POS tagging...
Loading default properties from tagger stanford-postagger-full-2017-06-09/models/english-left3words-distsim.tagger
Loading POS tagger from stanford-postagger-full-2017-06-09/models/english-left3words-distsim.tagger ... done [0.7 sec].
Untokenizable: (U+1B, decimal: 27)
Tagged 105730210 words at 110827.50 words per second.
Pos tagging took 15 minutes and 56 seconds
Preparing cleaned text...
Constructing case_tokenized_train.txt...
Constructing raw_tokenized_train.txt
Constructing token conversion table
Constructing pos_tags_tokenized_train.txt
Constructing tokenized_train.txt
Tokenizing stopwords
Tokenizing Wikipedia
No provided expert labels.
===AutoPhrasing===
=== Current Settings ===
Iterations = 2
Minimum Support Threshold = 10
Maximum Length Threshold = 6
POS-Tagging Mode Enabled
Number of threads = 10
Labeling Method = DPDN
        Auto labels from knowledge bases
        Max Positive Samples = -1
=======
Loading data...
# of total tokens = 105730210
max word token id = 869811
# of documents = 5499432
# of distinct POS tags = 45
Mining frequent phrases...
selected MAGIC = 869819
# of frequent phrases = 2029025
Extracting features...
Constructing label pools...
        The size of the positive pool = 31712
        The size of the negative pool = 1991159
# truth patterns = 200386
Estimating Phrase Quality...
Segmenting...
Rectifying features...
Estimating Phrase Quality...
Segmenting...
Dumping results...
Done.

real    15m13.802s
user    78m29.288s
sys     0m26.896s
===Saving Model and Results===
===Generating Output===
~/AutoPhrase(master)$
```

Check output:<br>
```
~/AutoPhrase(master)$ head -10 models/DBLP/AutoPhrase_multi-words.txt
0.9648292369    turbo equalization
0.9647017177    public-key cryptosystem
0.9644216993    boolean satisfiability
0.9638165369    kalman filters
0.9636082266    epipolar geometry
0.9635261410    mit press
0.9633463643    ultra wideband
0.9633258258    maximum entropy
0.9629881396    bundle adjustment
0.9629262437    shallow water
```

Notice the "Untokenized" error. ASCII convertion still lefts intact some Unicode characters like `U+0008` or `U+0014`, and Stanford tagger complains about them (the same was with old tokenizer).  Stanford allows skipping those characters or turning into a separate tags, but, I quess either way might shift the POS tags sequence compared to tokenized text, depending on whether bad character is a part of the word or not (perhaps that was the source of errors?). Therefore, for simplicity, I've chosen to create `raw_tokenized_train.txt` from the data already filtered by Stanford Tokenizer, i.e. create both `raw_tokenized_train.txt` and `pos_tags_tokenized_train.txt` and all other files from its output `text.tag`. POS tag sequence and tokenized text must be exactly equal in length now regardless of what `wc -w` says.

To read about the Stanford POS tagger options:
[https://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/tagger/maxent/MaxentTagger.html](https://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/tagger/maxent/MaxentTagger.html)
[https://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/process/PTBTokenizer.html](https://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/process/PTBTokenizer.html)

See also comments in `tokenize_raw.sh`.

-------


# AutoPhrase: Automated Phrase Mining from Massive Text Corpora

## Publications

Please cite the following two papers if you are using our tools. Thanks!

*   Jingbo Shang, Jialu Liu, Meng Jiang, Xiang Ren, Clare R Voss, Jiawei Han, "**[Automated Phrase Mining from Massive Text Corpora](https://arxiv.org/abs/1702.04457)**", submitted to TKDE, under review. arXiv:1702.04457 [cs.CL]

*   Jialu Liu\*, Jingbo Shang\*, Chi Wang, Xiang Ren and Jiawei Han, "**[Mining
    Quality Phrases from Massive Text
    Corpora](http://jialu.cs.illinois.edu/paper/sigmod2015-liu.pdf)**”, Proc. of
    2015 ACM SIGMOD Int. Conf. on Management of Data (SIGMOD'15), Melbourne,
    Australia, May 2015. (\* equally contributed,
    [slides](http://jialu.cs.illinois.edu/paper/sigmod2015-liu-slides.pdf))

## Recent Changes (2017.10.23)

*   Support extremely large corpus (e.g., 100GB or more). Please comment out the ```// define LARGE``` in the beginning of ```src/utils/parameters.h``` before you run AutoPhrase on such a large corpus.
*   Quality phrases (every token is seen in the raw corpus) provided in the knowledge base will be incorporated during the phrasal segmentation, even their frequencies are smaller than ```MIN_SUP```.
*   Stopwords will be treated as low quality single-word phrases.
*   Model files are saved separately. Please check the variable ```MODEL``` in both ```auto_phrase.sh``` and ```phrasal_segmentation.sh```.
*   The end of line is also a separator for sentence splitting.


## New Features
(compared to SegPhrase)

*   **Minimized Human Effort**. We develop a robust positive-only distant training method to estimate the phrase quality by leveraging exsiting general knowledge bases.
*   **Support Multiple Languages: English, Spanish, and Chinese**. The language
    in the input will be automatically detected.
*   **High Accuracy**. We propose a POS-guided phrasal segmentation model incorporating POS tags when POS tagger is available. Meanwhile, the new framework is able to extract single-word quality phrases.
*   **High Efficiency**. A better indexing and an almost lock-free parallelization are implemented, which lead to both running time speedup and memory saving.

## Related GitHub Repositories

*   [SegPhrase](https://github.com/shangjingbo1226/SegPhrase)
*	[SegPhrase-MultiLingual](https://github.com/remenberl/SegPhrase-MultiLingual)

## Requirements

Linux or MacOS with g++ and Java installed.

Ubuntu:

* g++ 4.8 `$ sudo apt-get install g++-4.8`
* Java 8 `$ sudo apt-get install openjdk-8-jdk`
* curl `$ sudo apt-get install curl`

MacOS:

*   g++ 6 `$ brew install gcc6`
*   Java 8 `$ brew update; brew tap caskroom/cask; brew install Caskroom/cask/java`

## Default Run

#### Phrase Mining Step
```
$ ./auto_phrase.sh
```

The default run will download an English corpus from the server of our data
mining group and run AutoPhrase to get 3 ranked lists of phrases as well as 2 segmentation model files under the
```MODEL``` (i.e., ```models/DBLP```) directory. 
* ```AutoPhrase.txt```: the unified ranked list for both single-word phrases and multi-word phrases. 
* ```AutoPhrase_multi-words.txt```: the sub-ranked list for multi-word phrases only. 
* ```AutoPhrase_single-word.txt```: the sub-ranked list for single-word phrases only.
* ```segmentation.model```: AutoPhrase's segmentation model (saved for later use).
* ```token_mapping.txt```: the token mapping file for the tokenizer (saved for later use).

You can change ```RAW_TRAIN``` to your own corpus and you may also want change ```MODEL``` to a different name.

#### Phrasal Segmentation

We also provide an auxiliary function to highlight the phrases in context based on our phrasal segmentation model. There are two thresholds you can tune in the top of the script. The model can also handle unknown tokens (i.e., tokens which are not occurred in the phrase mining step's corpus).

In the beginning, you need to specify AutoPhrase's segmentation model, i.e., ```MODEL```. The default value is set to be consistent with ```auto_phrase.sh```.

```
$ ./phrasal_segmentation.sh
```

The segmentation results will be put under the ```MODEL``` directory as well (i.e., ```model/DBLP/segmentation.txt```). The highlighted phrases will be enclosed by the phrase tags (e.g., ```<phrase>data mining</phrase>```).

## Incorporate Domain-Specific Knowledge Bases

If domain-specific knowledge bases are available, such as MeSH terms, there are two ways to incorporate them.
* (**recommended**) Append your known quality phrases to the file ```data/EN/wiki_quality.txt```.
* Replace the file ```data/EN/wiki_quality.txt``` by your known quality phrases.

## Handle Other Languages

#### Tokenizer and POS tagger

In fact, our tokenizer supports many different languages, including Arabics (AR), German (DE), English (EN), Spanish (ES), French (FR), Italian (IT), Japanese (JA), Portuguese (PT), Russian (RU), and Chinese (CN). If the language detection is wrong, you can also manually specify the language by modify the ```TOKENIZER``` command in the bash script ```auto_phrase.sh``` using the two-letter code for that language. For example, the following one forces the language to be English.
```
TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer -l EN"
```

We also provide a default tokenizer together with a dummy POS tagger in the ```tools/tokenizer```.
It uses the StandardTokenizer in Lucene, and always assign a tag ```UNKNOWN``` to each token.
To enable this feature, please add the ```-l OTHER"``` to the ```TOKENIZER``` command in the bash script ```auto_phrase.sh```.
```
TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer -l OTHER"
```

If you want to incorporate your own tokenizer and/or POS tagger, please create a new class extending SpecialTagger in the ```tools/tokenizer```. You may refer to StandardTagger as an example.

#### stopwords.txt

You may try to search online or create your own list.

#### wiki_all.txt and wiki_quality.txt

Meanwhile, you have to add two lists of quality phrases in the ```data/OTHER/wiki_quality.txt``` and ```data/OTHER/wiki_all.txt```. 
The quality of phrases in wiki_quality should be very confident, while wiki_all, as its superset, could be a little noisy. For more details, please refer to the [tools/wiki_enities](https://github.com/shangjingbo1226/AutoPhrase/tree/master/tools/wiki_entities).

## Docker

###Default Run

```
sudo docker run -v $PWD/results:/autophrase/results -it \
    -e FIRST_RUN=1 -e ENABLE_POS_TAGGING=1 \
    -e MIN_SUP=30 -e THREAD=10 \
    remenberl/autophrase

./autophrase.sh
```

The results will be available in the results folder.

###User Specified Input
Assuming the path to input file is ./data/input.txt.
```
sudo docker run -v $PWD/data:/autophrase/data -v $PWD/results:/autophrase/results -it \
    -e RAW_TRAIN=data/input.txt \
    -e FIRST_RUN=1 -e ENABLE_POS_TAGGING=1 \
    -e MIN_SUP=30 -e THREAD=10 \
    remenberl/autophrase

./autophrase.sh
```
