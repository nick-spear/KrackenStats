# loads words into a list from a given file (path)
def load_censor_list(path):
	with open(path, "r") as file:
		bad = []
		for line in file:
			bad.append(line.strip())
	return bad

# given a word to censor and a filter_list of bad words, censor the word
def censor(word, filter_list, mark_censored=False):
	orig = word
	for bad_word in filter_list:
		if bad_word in word:
                        if mark_censored:
                            word = ' '.join([word.replace(bad_word[1:(len(bad_word)-1)], "*" * (len(bad_word)-2)), "[Censored]"])
                        else:
                            word = word.replace(bad_word[1:(len(bad_word)-1)], "*" * (len(bad_word)-2))
	return word

def censor_list(word_list, filter_list, mark_censored=False):
        for i in range(len(word_list)):
                word_list[i][0] = censor(word_list[i][0], filter_list, mark_censored)
        return word_list

if __name__ == "__main__":
        bad = [ ["pussy", 10], ["boob", 9], ["fuck", 8] ]
        print(censor_list(bad, load_censor_list("censor_list.txt"), mark_censored=True))
