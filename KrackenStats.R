# ===========================================================#
#
#  File:        KrackenStats.R
#  Author:      Nickolas Spear
#  Updated:     July 28, 2017
#
#  (Bottom of Document: 289)
#
# = OUTLINE OF FUNCTIONS
#
#   - parseInput(string)
#        Evaluates input string and determines function 
#        calls depending on input.
#
#   - getTable()
#        Pulls database's password table as data frame.
#
#   - userStats(string, data.frame)
#        Collects and returns data regarding input 
#        password string.
#
#   - top(integer, data.frame)
#        Gets top (integer) fastest crack times, most
#        popular passwords in wild, and most popular 
#        seen passwords
#
#   - charFreq(table)
#        Gets frequency of each whitelisted character in 
#        the set of all unique input passwords
#
#   - charRelFreq(table)
#        Gets the relative frequency of each whitelisted 
#        character in the set of all unique input passwords
#
#   - charFreqSummary(data.frame)
#        Gets both the frequency and relative frequency of 
#        each whitelisted character in the set of all 
#        unique input passwords
#
#   - propotions(data.frame)
#        Gets average poportions of lowercase letters, 
#        uppercase letters, numbers, and special characters 
#        in the data.frame's population of passwords.
#
#   - passPropotions(string)
#        Gets the propotion of lowercase letters,
#        uppercase letters, numbers, and special characters 
#        of the input string.
#
#
# = ASSUMES THE FOLLOWING DATABASE COLUMN TITLES:
#     plaintext ............... Parsed Password
#     cpu_brute_time .......... Brute force crack time
#     seen_count .............. Number of times seen by front-end
#     from_public ............. From public table
#     rank_wild ............... Popularity rank in wild
#
# ===========================================================#


library(rjson)
library(RPostgreSQL)

test <- function() {
    args <- paste(commandArgs(trailingOnly = TRUE), collapse = " ")
    cat(parseInput(args))
}

parseInput <- function(input) {
	
    # Takes in user input, greedily splits on whitespace, and parses accordingly.
    args <- strsplit(input, "\\s+")[[1]]

    out <- "NULL"
    if (length(args) >= 1 ) {
        if (args[1] == "getuserstats") {
            table <- getTable()
            out <- toJSON(userStats(args[2], table[table$seen_count > 0,]))
        } else if (args[1] == "gettop") {
            table <- getTable()
            num <- strtoi(args[2], 10)
            out <- toJSON(top(num, table[table$seen_count > 0,], table[table$rank_wild > 0,]))
        }
    }

    result <- out
    
}

getTable <- function() {
    
    # Function to get current password database
    
    # Sets variables for database connection
    database_name <- "imt-admin"
    user_name <- "imt-admin"
    pass <- "1q2w3e4r"
    host_val <- "10.0.3.7"
    port_val <- "5432"

    datab_con <- dbConnect(dbDriver("PostgreSQL"), user=user_name, password=pass, dbname=database_name, host=host_val, port=port_val)
    result <- dbGetQuery(datab_con, "SELECT id,plaintext,cpu_brute_time,seen_count,rank_wild FROM rainbow WHERE rank_wild > 0 OR seen_count > 0")
    output <- result
    
}

userStats <- function(string, table) {

    # Pulls in password string value and returns a JSON containing the following:
    #     cpu_brute_time: (float) ....... Exact entry in cpu_brute_time
    #     percentile: (integer) ......... Percentile result amond all unique entered passwords
    #     rank: (integer) ............... Rank of value among all unique entered passwords sent to bruteforce
    #     unique_pass_count: (integer) .. Returns number of unique passwords entered by users
    #     average: (float) .............. Average Krack time of brute-forced population


    # Pulls Kracktime associated with password string
    Krack_time_val <- table$cpu_brute_time[match(string, table$id)]
    
    placehold <- "Neil is a bum"

    percentile_val <- placehold
    valid_Kracks <- placehold
    rank_val <- placehold
    number_of_passes_val <- placehold
    average_val <- placehold

    if (Krack_time_val > 0) {
        # Pulls percentile of value
        percentile_val <- floor(ecdf(table$cpu_brute_time)(Krack_time_val) * 100)
    
        # Gets all passwords sent to brute-force cracker
        valid_Kracks <- table[table$cpu_brute_time > 0,]

        # Sums the boolean of each value greater than string's length, returns that + 1 for rank
        rank_val <- sum(table$cpu_brute_time > Krack_time_val) + 1

        # Finds number of unique passwords entered
        number_of_passes_val <- NROW(table$seen_count)

        # Pulls current average of passwords$cpu_brute_time
        average_val <- mean(valid_Kracks$cpu_brute_time, na.rm = TRUE)
    }

    result <- list(cpu_brute_time = Krack_time_val, percentile = percentile_val, rank = rank_val, unique_pass_count = number_of_passes_val, average = average_val)
}

top <- function(numval, seen_table, wild_table) {

    # Finds the [num] fastest crack timees, [num] most popular passwords in the wild, 
    #       and [num] most popular passwords we've seen

    # Returns the sorted data in the following Javascript Object format:
    #
    # { "fastest" : [Array of object literals {"password":(string), "cpu_brute_time":(integer)} that correspond
    #               to the fastest 'num' crack times, in order of increasing time (fastest at index 0)]
    #   "wild_common" : [Array of object literals {"password":(string), "rank_wild":(integer)} that correspond
    #                    to the highest ranking popular passwords in the wild, in standard numeric order (rank 1 at index 0)]
    #   "seen_common" : [Array of object literals {"password":(string), "seen_count":(integer)} that correspond
    #                    to the most common passwords WE have seen, in order of decreasing frequency (most common at index 0)]
    # }

    worstKracksArray <- c()
    seenCommonArray <- c()
    wildCommonArray <- c()    

    numSeen <- numval
    numWild <- numval
    
    if ( nrow(seen_table) > 0 ) {
        if ( nrow(seen_table) < numval ) { numSeen <- nrow(seen_table) }

        worstKracks <- seen_table[seen_table$cpu_brute_time > 0,]
        worstKracks <- worstKracks[order(worstKracks$cpu_brute_time, decreasing = FALSE),][1:numSeen,]
        worstKracks <- subset(worstKracks, select = c("plaintext", "cpu_brute_time"))
        worstKracksArray <- split(worstKracks, seq(nrow(worstKracks)))
        names(worstKracksArray) = NULL
    
        seenCommon <- seen_table[order(seen_table$seen_count, decreasing = TRUE),][1:numSeen,]
        seenCommon <- subset(seenCommon, select = c("plaintext", "seen_count"))
        seenCommonArray <- split(seenCommon, seq(nrow(seenCommon)))
        names(seenCommonArray) = NULL
    }

    if ( nrow(wild_table) > 0 ) {
        if ( nrow(wild_table) < numval ) { numWild <- nrow(wild_table) }

        wildCommon <- wild_table[wild_table$rank_wild > 0,]
        wildCommon <- wildCommon[order(wildCommon$rank_wild, decreasing = FALSE),][1:numWild,]
        wildCommon <- subset(wildCommon, select = c("plaintext", "rank_wild"))
        wildCommonArray <- split(wildCommon, seq(nrow(wildCommon)))
        names(wildCommonArray) = NULL
    }

    finalResult <- list(fastest=worstKracksArray, wild_common=wildCommonArray, seen_common=seenCommonArray)
}

charFreq <- function(table) {

    # Splits vector of password password into a character vector, then
    # Sums the occurrences for each whitelisted character and returns the sorted result

    seen_table <- table[seen_count > 0,]
    white_list <- c("!", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~")
    password_to_chars <- unlist(strsplit(as.character(seen_table$plaintext), ""))
    result <- sort(sapply(white_list, function(x) x <- sum( x == password_to_chars )), decreasing=TRUE)
}

charRelFreq <- function(table) {

    # Finds frequency identically to as in charFreq() and divides the result vector by
    # the number of characters in the split character array

    seen_table <- table[seen_count > 0,]
    white_list <- c("!", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~")
    
    password_to_chars <- unlist(strsplit(as.character(seen_table$plaintext), ""))
    result <- sort(sapply(white_list, function(x) x <- sum( x == password_to_chars )), decreasing=TRUE)
    result <- charFreq() / length(password_to_chars)
}

charFreqSummary <- function(table) {

    # Calls charFreq() and charRelFreq() to obtain character frequency data and 
    # formats to a JSON with the following members:
    #   character : Array of whitelist characters, ordered by descending frequency
    #   frequency : Array of frequencies of characters with the corresponding index,
    #               e.g. if character[5] = 'S', then the frequency of 'S' is frequency[5]
    #   relativeFrequency : Same format as frequency[], but instead containing relative frequencies

    charFreqRes <- charFreq(table)
    charRelFreqRes <- charRelFreq(table)
    resultFrame <- data.frame(
        character = names(charFreqRes),
        frequency = as.vector(charFreqRes),
        relativeFrequency = as.vector(charRelFreqRes)      
    )
}

proportions <- function(table) {

    # Constructs empty datafram to hold proportions of each type for every password string.
    # Iterates through the pulled string vector, calls passProportions on each given string,
    # and puts those proportions in their respective string_frame row.

    length <- NROW(table)
    string_frame <- data.frame(
        lower_case = rep(NA, length),
        upper_case = rep(NA, length),
        numerals = rep(NA, length),
        specials = rep(NA, length)
    )

    seen_table <- table[seen_count > 0,]

    i <- 0
    for (pass_string in seen_table$plaintext) {
        i <- i + 1
        string_frame[i, ] <- passProportions(pass_string)
    }

    result <- list(
        lowerCase = list(mean = mean(string_frame$lower_case), std = sd(string_frame$lower_case)),
        upperCase = list(mean = mean(string_frame$upper_case), std = sd(string_frame$upper_case)),
        numerals = list(mean = mean(string_frame$numerals), std = sd(string_frame$numerals)),
        specials = list(mean = mean(string_frame$specials), std = sd(string_frame$specials))
    )
    
}

passProportions <- function(pass) {

    # Helper functions for proportion-based stats methods.
    # Takes passed 'pass' string, converts it to a vector of ascii value equivalents,
    # and finds desired proportions accordingly

    ascii_vec <- utf8ToInt(pass)
    lower <- 0
    upper <- 0
    num <- 0
    spec <- 0
    str_length <- length(ascii_vec)

    for (pass_num in ascii_vec) {
        if (pass_num < 123 && pass_num > 96) { # Lowercase Alphabe
            lower <- lower + 1
        } else if (pass_num < 91 && pass_num > 64) { # Uppercase Alphabet
            upper <- upper + 1
        } else if (pass_num < 58 && pass_num > 47) { # Numerals`
            num <- num + 1
        } else { # Remaining Specials
            spec <- spec + 1
        } 
    }
    result <- c( lower / str_length, upper / str_length, num / str_length, spec / str_length)
}

test()
