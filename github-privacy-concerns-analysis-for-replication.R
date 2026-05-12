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

## Dataset summary and context - plot with law mentioned per year
library(dplyr)
yeardf <- transform(df,year=as.character(df$date) %>%
                      strsplit("/|-| ") %>%
                      sapply( "[", 3 )) 
df_year <- df %>%
  mutate(year = lubridate::year(created_at)) %>%
  group_by(law, year) %>%
  summarise(yearly_freq = n()) %>%
  ungroup()
write.csv(df_year, file='/Volumes/Samsung_T5/RESEARCH/PAPERS/FLOSS/_GitHubPrivacy/issues-EMSE/rq2/issues-per-year-with-law-dupl.csv', row.names=FALSE)
library(ggplot2)
q <- df_year %>%
  ggplot(aes(x = as.character(year), y = yearly_freq, fill = law)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = "Year", y = "Law mentions per year", fill = "Law") +
  theme(text = element_text(size = 14), axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
q + 
  scale_fill_manual(values = c("#FFA07A","darkgreen", "red", "#BDB76B" ))

# Dataset summary and context - comparison with other datasets
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

#### RQ1 - keywords search within issues (repeat for each user right and principle, using the separate files in folder data/law-principles/)
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

### RQ1, RQ2 - sample for manual analysis - only issues with title/body indicating the law
df$titlebody <- tolower(paste(df$title,df$body))
patterns <- c("gdpr", "general data protection regulation", "data protection act", "data-protection-act", "cpra", "ccpa", 
              "california consumer privacy act", "california privacy rights act")
df2 <- dplyr::filter(df, grepl(paste(patterns, collapse="|"), titlebody))
df2.sample <- df2[sample(nrow(df2), 1206), ] 

#### RQ1 - rights/principles search within issues (sample from manual - CODE AS IN: RQ1 - keywords search within issues)

#### RQ1, RQ2 - Cohen's kappa calculation in SPSS

#### RQ2 - categorization frequencies calculation
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

#### RQ2 - bipartite graph
df <- read_csv(input_file, show_col_types = FALSE)
rights <- split_labels(df, "FINAL_RIGHTS", right_map, lower = TRUE) %>%
  rename(right = value)
concerns <- split_labels(df, "CONCERN.FINAL2", concern_map) %>%
  rename(concern = value)

edges <- inner_join(concerns, rights, by = "id", relationship = "many-to-many") %>%
  count(concern, right, name = "n")

left_nodes <- edges %>%
  count(concern, wt = n, name = "total") %>%
  arrange(desc(total), concern) %>%
  mutate(y = rev(seq_len(n())))
right_nodes <- edges %>%
  count(right, wt = n, name = "total") %>%
  arrange(desc(total), right) %>%
  mutate(y = rev(seq_len(n())))
edges_plot <- edges %>%
  left_join(left_nodes, by = "concern") %>%
  rename(y_left = y) %>%
  left_join(right_nodes, by = "right") %>%
  rename(y_right = y) %>%
  mutate(size = scales::rescale(n, to = c(0.4, 2.2)))

plot_obj <- ggplot() +
  geom_curve(
    data = edges_plot,
    aes(x = 0.12, y = y_left, xend = 0.88, yend = y_right, linewidth = size),
    curvature = 0.15,
    alpha = 0.7
  ) +
  geom_point(data = left_nodes, aes(x = 0, y = y), color = "#FFE4C4") +
  geom_point(data = right_nodes, aes(x = 1, y = y), color = "#53868B") +
  geom_text(data = left_nodes, aes(x = -0.02, y = y, label = concern), hjust = 1) +
  geom_text(data = right_nodes, aes(x = 1.02, y = y, label = right), hjust = 0) +
  scale_linewidth_identity() +
  coord_cartesian(xlim = c(-0.28, 1.28), clip = "off") +
  theme_void() +
  theme(plot.margin = margin(10, 120, 10, 120))

#### RQ2 - statistical test between categories in SPSS
