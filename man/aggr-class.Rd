% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/S3Aggregates.R
\name{AGGREGATES-Object}
\alias{AGGREGATES-Object}
\alias{SUM}
\alias{COUNT}
\alias{COUNTSAMP}
\alias{MIN}
\alias{MAX}
\alias{AVG}
\alias{MEDIAN}
\alias{STD}
\alias{BAG}
\alias{BAGD}
\alias{Q1}
\alias{Q2}
\alias{Q3}
\title{AGGREGATES object class constructor}
\usage{
SUM(value)

COUNT()

COUNTSAMP()

MIN(value)

MAX(value)

AVG(value)

MEDIAN(value)

STD(value)

BAG(value)

BAGD(value)

Q1(value)

Q2(value)

Q3(value)
}
\arguments{
\item{value}{string identifying name of metadata or region attribute}
}
\value{
Aggregate object
}
\description{
This class constructor is used to create instances of AGGREGATES object,
to be used in GMQL functions that require aggregate on value.
}
\details{
\itemize{
\item{SUM: It prepares input parameter to be passed to the library 
function sum, performing all the type conversions needed  }
\item{COUNT: It prepares input parameter to be passed to the library 
function count, performing all the type conversions needed }
\item{COUNTSAMP: It prepares input parameter to be passed to the library 
function countsamp, performing all the type conversions needed.
It is used only with group_by functions}
\item{MIN: It prepares input parameter to be passed to the library 
function minimum, performing all the type conversions needed  }
\item{MAX: It prepares input parameter to be passed to the library 
function maximum, performing all the type conversions needed }
\item{AVG: It prepares input parameter to be passed to the library 
function mean, performing all the type conversions needed }
\item{MEDIAN: It prepares input parameter to be passed to the library 
function median, performing all the type conversions needed }
\item{STD: It prepares input parameter to be passed to the library 
function standard deviation, performing all the type conversions needed}
\item{BAG: It prepares input parameter to be passed to the library 
function bag; this function creates comma-separated strings of 
attribute values, performing all the type conversions needed}
\item{BAGD: It prepares input parameter to be passed to the library 
function bagd; this function creates comma-separated strings of distinct 
attribute values, performing all the type conversions needed}
\item{Q1: It prepares input parameter to be passed to the library 
function fist quartile, performing all the type conversions needed}
\item{Q2: It prepares input parameter to be passed to the library 
function second quartile, performing all the type conversions needed }
\item{Q3: It prepares input parameter to be passed to the library 
function third quartile, performing all the type conversions needed }
}
}
\examples{

## This statement initializes and runs the GMQL server for local execution 
## and creation of results on disk. Then, with system.file() it defines 
## the path to the folder "DATASET" in the subdirectory "example"
## of the package "RGMQL" and opens such folder as a GMQL dataset 
## named "exp" using CustomParser

init_gmql()
test_path <- system.file("example", "DATASET", package = "RGMQL")
exp = read_gmql(test_path)

## This statement copies all samples of exp dataset into res dataset, and 
## then calculates new metadata attribute sum_score for each of them: 
## sum_score is the sum of score values of the sample regions.

res = extend(exp, sum_score = SUM("score"))

## This statement copies all samples of exp dataset into res dataset, 
## and then calculates new metadata attribute min_pvalue for each of them: 
## min_pvalue is the minimum pvalue of the sample regions.

res = extend(exp, min_pvalue = MIN("pvalue"))

## This statement copies all samples of exp dataset into res dataset, 
## and then calculates new metadata attribute max_score for each of them: 
## max_score is the maximum score of the sample regions.

res = extend(exp, max_score = MAX("score"))

## The following cover operation produces output regions where at least 2 
## and at most 3 regions of exp dataset overlap, having as resulting region 
## attribute the average signal of the overlapping regions; 
## the result has one sample for each input cell value.

res = cover(exp, 2, 3, groupBy = conds("cell"), avg_signal = AVG("signal"))

## This statement copies all samples of 'exp' dataset into 'out' dataset, 
## and then for each of them it adds another metadata attribute, allScore, 
## which is the aggregation comma-separated list of all the values 
## that the region attribute score takes in the sample.

out = extend(exp, allScore = BAG("score"))

## This statement counts the regions in each sample and stores their number 
## as value of the new metadata RegionCount attribute of the sample.

out = extend(exp, RegionCount = COUNT())

## This statement copies all samples of exp dataset into res dataset, 
## and then calculates new metadata attribute std_score for each of them: 
## std_score is the standard deviation of the score values of the sample 
## regions.

res = extend(exp, std_score = STD("score"))

## This statement copies all samples of exp dataset into res dataset, 
## and then calculates new metadata attribute m_score for each of them: 
## m_score is the median score of the sample regions.

res = extend(exp, m_score = MEDIAN("score"))


}
