##### ISSUES DATA PREPARATION
#  date filter (GDPR: since April 14th, 2016, CCPA: since June 28th, 2018, CPRA: since November 3rd, 2020)
df1 <- read.csv(file="data/issues_ccpa.csv", header=TRUE, sep=",") # Repeat for each law file (final file provided in dataset)
df1 <- df1[!duplicated(df1$html_url), ]
library(dplyr)
filtereddf1 <- transform(df1,date=as.character(df1$created_at) %>%
                           strsplit("T") %>%
                           sapply( "[", 1 )) 
filtereddf1$date <- as.Date(filtereddf1$date, format= "%Y-%m-%d")
ndf <- filtereddf1 %>% filter(date > '2016-04-13')
write.csv(ndf, file='data/issues_ccpa-date.csv', row.names=FALSE)

#### only closed issues
df <- read.csv(file="data/issues_ccpa-date.csv", header=TRUE, sep=",") # Repeat for each law file
df <- df[df$state == 'closed',]
write.csv(df, file='data/issues_ccpa-date-closed.csv', row.names=FALSE)

#### only user created issues
df <- read.csv(file="data/issues_ccpa-date-closed.csv", header=TRUE, sep=",") # Repeat for each law file
df <- df[df$user.type == 'User',]
patterns <- c("bot")
df <- dplyr::filter(df, !grepl(paste(patterns, collapse="|"), user.login))
write.csv(df, file='data/issues_ccpa-date-closed-user.csv', row.names=FALSE)

#  bind all laws together
df1 <- read.csv(file="data/issues_gdpr-final.csv", header=TRUE, sep=",")
df2 <- read.csv(file="data/data/issues_ccpa-date-closed-user.csv", header=TRUE, sep=",")
df3 <- read.csv(file="data/cpra-final.csv", header=TRUE, sep=",")
df4 <- read.csv(file="data/Data_Protection_Act-final.csv", header=TRUE, sep=",")
df <- rbind(df1, df2, df3, df4)

### At this point use the Python script (bert-trained-classify-new.py:) to filter out non-law relevant issues. The result file is available here: data/issues_ALL_BERT_final.csv

### Final file to use after merging keywords: data/issues_ALL_BERT_final.csv

# sample for manual verification
df1 <- read.csv(file="data/issues_ALL_BERT_final.csv", header=TRUE, sep=",")
df1.sample <- df1[sample(nrow(df1), 100), ] # change sample size accordingly

#### RQ1 - dataset summary
ndf <- df %>% 
  group_by(repository_url) %>% 
  summarise(count = n()) 

df$date_diff <- as.Date(as.character(df$closed_at), format="%Y-%m-%d")-
  as.Date(as.character(df$created_at), format="%Y-%m-%d")
df$date_diff<-as.numeric(df$date_diff)

nndf <- df %>% 
  summarise(mean_comments= mean(as.numeric(comments)),
            max_comments= max(as.numeric(comments)),
            mean_days= mean(as.numeric(date_diff))
  )

## RQ1 - dataset summary - plot with issues per year
library(dplyr)
yeardf <- transform(df,year=as.character(df$date) %>%
                      strsplit("/|-| ") %>%
                      sapply( "[", 3 )) 
df_year <- df %>%
  mutate(year = lubridate::year(created_at)) %>%
  group_by(year) %>%
  summarise(yearly_freq = n()) %>%
  ungroup()

library(ggplot2)
q <- df_year %>%
  ggplot(aes(x = as.character(year), y = yearly_freq)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = "Year", y = "Issues per year") +
  theme(text = element_text(size = 14), axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
q

# RQ1 - comparison with other datasets
dfm <- read.csv(file="data/issues-nonGDPR.csv", header=TRUE, sep=",") # final file provided in dataset
dfm$titlebody <- tolower(paste(dfm$title,dfm$body))
patterns <- c("gdpr", "general data protection regulation", "data protection act", "data-protection-act", "cpra", "ccpa", 
              "california consumer privacy act", "california privacy rights act")
dfk <- dplyr::filter(dfm, !grepl(paste(patterns, collapse="|"), titlebody))
dfk$date_diff <- as.Date(as.character(dfk$closed_at), format="%Y-%m-%d")-
  as.Date(as.character(dfk$created_at), format="%Y-%m-%d")
dfk$date_diff<-as.numeric(dfk$date_diff)
dfk$lawrelevant <- rep(0,nrow(dfk))
#### only user created issues
dfk <- dfk[dfk$user.type == 'User',]
patterns <- c("bot")
dfk <- dplyr::filter(dfk, !grepl(paste(patterns, collapse="|"), user.login))
write.csv(dfk, file='data/issues-nonlaw.csv', row.names=FALSE)

df <- read.csv(file="data/issues_ALL_BERT_final.csv", header=TRUE, sep=",")
df$date_diff <- as.Date(as.character(df$closed_at), format="%Y-%m-%d")-
  as.Date(as.character(df$created_at), format="%Y-%m-%d")
df$date_diff<-as.numeric(df$date_diff)
df$lawrelevant <- rep(1,nrow(df))

common_cols <- intersect(colnames(dfk), colnames(df))
dfx <- rbind(
  subset(dfk, select = common_cols), 
  subset(df, select = common_cols)
)
write.csv(dfx, file='data/issues-law-issues-nonlaw.csv', row.names=FALSE)
### statistical test in SPSS

#### RQ2 - keywords search within issues (repeat for each user right and principle, using the separate files in folder data/law-principles/)
rightsandprinciples <- 
  read.csv(file="data/law-principles/law-keywords-data-minimization.csv", sep=",", stringsAsFactors=FALSE) 
#law-keywords.csv can be created by merging all files in folder data/law-principles/ 
df$titlebody <- tolower(paste(issues$title,issues$body,sep=" "))

kvector <- c(as.character(tolower(rightsandprinciples$allkeywords)))
bvector <- c(as.character(tolower(df$titlebody)))

ndf <- data.frame(df$html_url, df$id, df$comments, df$created_at, df$updated_at, df$closed_at, df$law, df$keyword, 
                  lapply(kvector, function(word) {
  as.numeric(grepl(word, bvector, fixed = TRUE))
}))

### RQ2, RQ3 - sample for manual analysis - only issues with title/body indicating the law
df$titlebody <- tolower(paste(df$title,df$body))
patterns <- c("gdpr", "general data protection regulation", "data protection act", "data-protection-act", "cpra", "ccpa", 
              "california consumer privacy act", "california privacy rights act")
df2 <- dplyr::filter(df, grepl(paste(patterns, collapse="|"), titlebody))
df2.sample <- df2[sample(nrow(df2), 1206), ] 

#### RQ2 - rights/principles search within issues (sample from manual - CODE AS IN: RQ2 - keywords search within issues)

#### RQ2, RQ3 - Cohen's kappa calculation in SPSS

#### RQ3 - categorization frequencies calculation
issues <- read.csv(file="results/rq2-rq3-issues-ALL-till-June-2024-full-term-sample-new-2-coders.csv", header=TRUE, sep=",")
categories <- read.csv(file="results/rq3-categories.csv", sep=",", stringsAsFactors=FALSE)
kvector <- c(as.character(tolower(categories$categories)))
bvector <- c(as.character(tolower(issues$CONCERN.FINAL)))

ndf <- data.frame(issues$html_url, issues$RELEVANT, issues$HAS.RIGHTS, issues$RIGHTS.PRINCIPLES, 
                  issues$CONCERNS.coder.1, issues$CONCERNS.coder.2, issues$CONCERN.FINAL,
                  issues$id, issues$comments, 
                  issues$created_at, issues$updated_at, issues$closed_at, issues$law, issues$keyword, 
                  lapply(kvector, function(word) {
                    as.numeric(grepl(word, bvector, fixed = TRUE))
                  }))
names(ndf) <- c("html_url","RELEVANT", "HAS.RIGHTS","RIGHTS.PRINCIPLES","CONCERNS.coder.1",
                "CONCERNS.coder.2","CONCERN.FINAL",
                "id","comments","created_at","updated_at","closed_at",
                "law", "keyword", kvector)

#### RQ3 - statistical test between categories in SPSS