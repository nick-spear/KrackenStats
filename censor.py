# loads words into a list from a given file (path)
def load_censor_list(path):
	with open(path, "r") as file:
		bad = []
		for line in file:
			bad.append(line.strip())
	return bad
	
# given a word to censor and a filter_list of bad words, censor the word
def censor(word, filter_list):
	orig = word
	for bad_word in filter_list:
		if bad_word in word:
			word = word.replace(bad_word[1:(len(bad_word)-1)], "*" * (len(bad_word)-2))
	return word