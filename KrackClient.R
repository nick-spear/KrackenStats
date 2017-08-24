client <- function(){
  while(TRUE){
    con <- socketConnection(host="localhost", port = 20000, blocking=TRUE,
                            server=FALSE, open="r+")
    f <- file("stdin")
    open(f)
    print("Enter command, or q to quit")
    sendme <- readLines(f, n=1)
    if(tolower(sendme)=="q"){
      break
    }
    write_resp <- writeLines(sendme, con)
    server_resp <- readLines(con, 1)
    print(server_resp)
    close(con)
  }
}
client()