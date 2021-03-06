% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/S3Operator.R
\name{OPERATOR-Object}
\alias{OPERATOR-Object}
\alias{META}
\alias{NIL}
\alias{SQRT}
\title{OPERATOR object class constructor}
\usage{
META(value, type = NULL)

NIL(type)

SQRT(value)
}
\arguments{
\item{value}{string identifying name of metadata attribute}

\item{type}{string identifying the type of the attribute value;
it must be: INTEGER, DOUBLE or STRING. 
For NIL() function, only INTEGER and DOUBLE are allowed}
}
\value{
Operator object
}
\description{
This class constructor is used to create instances of OPERATOR object,
to be used in GMQL functions that require operator on value.
}
\details{
\itemize{
\item{META: It prepares input parameter to be passed to library function 
meta, performing all the type conversions needed}
\item{SQRT: It prepares input parameter to be passed to library function 
sqrt, performing all the type conversions needed}
\item{NIL: It prepares input parameter to be passed to library function 
null, performing all the type conversions needed}
}
}
\examples{
## This statement initializes and runs the GMQL server for local execution 
## and creation of results on disk. Then, with system.file() it defines 
## the path to the folder "DATASET" in the subdirectory "example" 
## of the package "RGMQL" and opens such folder as a GMQL dataset 
## named "exp"

init_gmql()
test_path <- system.file("example", "DATASET", package = "RGMQL")
exp = read_gmql(test_path)

## This statement allows to select, in all input samples, all those regions 
## for which the region attribute score has a value which is greater 
## than the metadata attribute value "avg_score" in their sample.

data = filter(exp, r_predicate = score > META("avg_score"))

## This statement defines new numeric region attributes with "null" value. 
## The syntax for creating a new attribute with null value is 
## attribute_name = NULL(TYPE), where type may be INTEGER or DOUBLE.

out = select(exp, regions_update = list(signal = NIL("INTEGER"), 
    pvalue = NIL("DOUBLE")))

## This statement allows to build an output dataset named 'out' such that 
## all the samples from the input dataset 'exp' are conserved, 
## as well as their region attributes (and their values) 
## and their metadata attributes (and their values). 
## The new metadata attribute 'concSq' is added to all output samples 
## with value correspondent to the mathematical squared root 
## of the pre-existing metadata attribute 'concentration'.

out = select(exp, metadata_update = list(concSq = SQRT("concentration")))

}
