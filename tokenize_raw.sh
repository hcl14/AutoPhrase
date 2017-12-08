#!/bin/bash

# please provide input text as a command line parameter, i.e. "$ bash tokenize_raw.sh input.txt"

STANFORD_POS_TAGGER_PATH="/home/hcl/Documents/work/keyword-algorithms/stanford-corenlp-full-2017-06-09/stanford-postagger-full-2017-06-09"

TEMPDIR="tmp"

STOPWORDS="data/EN/stopwords.txt"

WIKI_ALL="data/EN/wiki_all.txt"

WIKI_QUALITY="data/EN/wiki_quality.txt"

TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer"

TOKENIZED_ALL=$TEMPDIR/tokenized_all.txt
TOKENIZED_QUALITY=$TEMPDIR/tokenized_quality.txt
THREAD=${THREAD:- 10}


echo "POS tagging..." &&

SECONDS=0 &&

#pos tagging

#Another way to deal with bad characters is to pass either the "firstKeep" option which should print first warning and then convert unknown characters into distinct tags according to the documentation, or leave default "firstDelete" which deletes them. But both might shift the POS tags sequence depending on whether special character is a part of a word or not, so I guess this will produce wrong output.

#Providing "-encoding ascii" parameters as well as additionally passing `raw_tokenized_train.txt` to `inconv` didn't help (perhaps it leaves those characters intact).

#you can try to remove ascii encoding for non-Englist text, default is UTF-8

#but if input is ascii, better to leave it intact, because Stanford POS tagger sometimes reads other encodings and UTF (yes, ascii should be read normally, but I want to avoid any possible bugs) https://mailman.stanford.edu/pipermail/java-nlp-user/2009-November/000312.html

java -cp "$STANFORD_POS_TAGGER_PATH/*" edu.stanford.nlp.tagger.maxent.MaxentTagger -nthreads 10 -tokenizerOptions='untokenizable=firstDelete, encoding=ascii' -encoding ascii -model $STANFORD_POS_TAGGER_PATH/models/english-left3words-distsim.tagger -textFile $1 -outputFormat tsv -outputFile $TEMPDIR/text.tag &&


duration=$SECONDS &&
echo "Pos tagging took $(($duration / 60)) minutes and $(($duration % 60)) seconds" &&



echo "Preparing cleaned text..." &&

# extract text which matches tags exactly from POS tag output (first column from tab-separated file, line breaks were preserved as empty lines):
awk -F"\t" '{print $1}' $TEMPDIR/text.tag > $TEMPDIR/1st_col.txt &&


echo "Constructing case_tokenized_train.txt..."

# at first check and preserve the empty line
# then check first for being number (4), then - for being all uppercase or punctuation (3), then - for being first uppercase (1) (we can go simple now and just check first letter)
# the last category is "uncetegorized" and assumed to be all lower (0)
awk '{if($1 == ""){printf "\n"}else{if($1 == $1+0){print "4";}else{  if($1 == toupper($1)){print "3";}else{ if($1 ~ /^[A-Z].*/){print "1";}else{ print "0";  }   } } } }' $TEMPDIR/1st_col.txt > $TEMPDIR/case_1st_col.txt &&

#construct file
# empty line is a line break

#awk '{if($1 ~ /^\s*$/){printf "\n"}else{printf $1}}' case_1st_col.txt > case_tokenized_train.txt &&

# wc-l somewhy gives different number of lines for case_tokenized_train.txt  and raw_tokenized_train.txt , but algorithm seems working correctly
awk '{if($1 == ""){printf "\n"}else{printf $1}}' $TEMPDIR/case_1st_col.txt > $TEMPDIR/case_tokenized_train.txt 


# lowercase all the 1st_col.txt
awk '{ print tolower($1) }' $TEMPDIR/1st_col.txt > $TEMPDIR/1st_col_lower.txt &&
rm $TEMPDIR/1st_col.txt &&
mv $TEMPDIR/1st_col_lower.txt  $TEMPDIR/1st_col.txt &&


# Looks like this file is not needed
### Construct "raw_tokenized_train.txt" :
echo "Constructing raw_tokenized_train.txt" &&
# empty line is a line break
awk -v RS= '$1=$1' $TEMPDIR/1st_col.txt > $TEMPDIR/raw_tokenized_train.txt &&





### Extract token conversion table "token_mapping.txt"

echo "Constructing token conversion table" &&


# awk is 8 times faster than uniq 
awk '{!seen[$0]++};END{for(i in seen) print i}' $TEMPDIR/1st_col.txt > $TEMPDIR/uniq_words.txt &&

# remove empty line(s)
sed -i '/^$/d' $TEMPDIR/uniq_words.txt &&

# numerate
awk '{print NR-1 "\t" $0}' $TEMPDIR/uniq_words.txt > $TEMPDIR/token_mapping.txt &&



### Extract "pos_tags_tokenized_train.txt" :
echo "Constructing pos_tags_tokenized_train.txt" &&


#extract second column with POS tags from tab-separated file
awk -F"\t" '{print $2}' $TEMPDIR/text.tag > $TEMPDIR/text.tag_cleaned.txt &&

#remove empty lines which were line breaks
sed -i '/^$/d' $TEMPDIR/text.tag_cleaned.txt &&

mv $TEMPDIR/text.tag_cleaned.txt $TEMPDIR/pos_tags_tokenized_train.txt &&



### Construct "tokenized_train.txt" based on `raw_tokenized_train.txt` and conversion table `token_mapping.txt`
echo "Constructing tokenized_train.txt" &&

# make fast replacaments according to the conversion table
# https://stackoverflow.com/questions/14234907/replacing-values-in-large-table-using-conversion-table
# all the values should exist in the table !!!
awk 'NR==0 { next } FNR==NR { a[$2]=$1; next } $1 in a { $1=a[$1] }1' $TEMPDIR/token_mapping.txt $TEMPDIR/1st_col.txt > $TEMPDIR/1st_col.tokenized.txt &&
# generate file
# empty line is a line break
awk -v RS= '$1=$1' $TEMPDIR/1st_col.tokenized.txt > $TEMPDIR/tokenized_train.txt &&


### Tokenizing stopwords
echo "Tokenizing stopwords" &&
# make fast replacements according to the conversion table
# not all stopwords may exist in the corpus
awk 'NR==0 { next } FNR==NR { a[$2]=$1; next } ($1 in a == 1) { print a[$1] } ($1 in a == 0) {print "-1111"}' $TEMPDIR/token_mapping.txt $STOPWORDS > $TEMPDIR/tokenized_stopwords.txt  &&

### Tokenizing wikipedia 
echo "Tokenizing Wikipedia" &&

## convert to ASCII with transliteration
iconv -f UTF8 -t ASCII//TRANSLIT $WIKI_ALL > $TEMPDIR/wiki_all_ascii.txt &&
iconv -f UTF8 -t ASCII//TRANSLIT $WIKI_QUALITY > $TEMPDIR/wiki_quality_ascii.txt 


#it's quite tricky to replace words in unknown number of columns with awk, so I will use existing tokenizer 

java $TOKENIZER -m test -i $TEMPDIR/wiki_all_ascii.txt -o $TOKENIZED_ALL -t $TEMPDIR/token_mapping.txt -c N -thread $THREAD
java $TOKENIZER -m test -i $TEMPDIR/wiki_quality_ascii.txt -o $TOKENIZED_QUALITY -t $TEMPDIR/token_mapping.txt -c N -thread $THREAD
