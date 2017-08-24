#just a test

server <- function(){

 while(TRUE){
  writeLines("listening...")
  con <- socketConnection(host="10.0.3.54",port=6011, blocking=FALSE, server=TRUE,open="r+")
  data <- readLines(con,1)
  print(data)
  response <- toupper(data)
  writeLines(response, con)
 close(con)
 }
}
server()
