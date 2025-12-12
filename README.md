# GitHub Privacy Law Issues Analysis

The dataset and analysis code in this repository contains the replication package for analyzing GitHub issues on privacy law compliance (GDPR, CCPA, CPRA, Data Protection Act).

The dataset contains the following files:

- in folder **data/** are the datasets used that were collected using GitHub API, as long as the initial files created by the authors to be used later in the analysis:
  * **issues_ALL_BERT_final.csv**: the whole dataset (final filtered dataset) with all laws used for the subsequent analysis (without duplicates).
  * **issues-nonlaw.csv**: non-law relevant issues dataset collected for comparison purposes with the work dataset (comparison between law-relevant and non-law relevant issues). Used to answer RQ1.
  * **law-principles/**: this folder contains a number of lists with keywords for law user rights and principles. There are 2 files for each user right (1 is the keyword file created by the authors, and the other is the revised file provided by ChatGPT - GPT-5.0, e.g. law-keywords-right-to-data-portability.csv and law-keywords-right-to-data-portability-GPT-revised.csv). For the principles, there is one file per principle, apart from data minimization” and “storage limitation” principles.
  * **keywords-enrichment-prompts**: the full prompts provided to ChatGPT for the user rights and principles keywords enrichment.

- In folder **results/** results to the Research Questions are provided:
  * The confusion matrix from BERT classification of issues as privacy or non-privacy relevant (**BERT-512-privacy-law-non-privacy-law-confusion-matrix.png**)
  * user rights and principles presence results for the automated process on the whole dataset (**rights-presence.xlsx**)
  *  sample and final coding categorization for the user rights (**rq2-rights-principles-coders-output-test.csv**)
  * coding results for categorization of issues (**rq2-rq3-issues-ALL-till-June-2024-full-term-sample-new-2-coders.csv** and categories in: **rq3-categories.csv**)
  * frequencies of categories (**rq3-categorization-manual_sample.csv**)
  * other categorization results from IBM SPSS Statistics including comparison among categories (**rq3-categories-comparison-coders-output.spv**) and the Cohen's Kappa calculation results for the categorization of user rights and principles by the two coders in RQ2 (**rq2-coding-kappa-output.spv**) 
  * A codebook with definitions and examples for the issues categorization (RQ3), this file was also shared with  experts for the taxonomy validation: **concerns-descriptions-gkapi-examples.html**
  * The questionnaire given to experts for the validation of the created taxonomy: **Validation of list of privacy law developer concerns - Google Forms.pdf** (the experts were given the codebook listed previously)

- Outside the folders the analysis scripts in R and Python are provided (instructions on executing the steps are provided inside the files in comments), and some filtering clarifications:
  * **github-privacy-concerns-analysis-for-replication.R**: other analysis steps.
  * **bert-trained-classify-new.py**: for running the fine tuned BERT classifier on new GitHub issues.
 * **Repos-with-issues-removed**: indicates the reasons for removing some repository issues based on the manual verification.

The fine tuned BERT model used for the classification of the issues as privacy or non-privacy relevant is available on HuggingFace and contains a link to the labeled dataset (also on HuggingFace) used for the fine tuning: **https://huggingface.co/gkapi/bert-uncased-privacy-law-binary-model**