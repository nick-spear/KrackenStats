To get requiried packages and libraries, run the following commands:
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'
sudo apt-get update
sudo apt-get install r-base
sudo apt-get install libpq-dev
R
install.packages("RPostgreSQL")
install.packages("rjson")

To start script, run the following command:
Rscript KrackenStats.R