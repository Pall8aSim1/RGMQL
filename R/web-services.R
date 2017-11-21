if(getRversion() >= "2.15.1")
    utils::globalVariables("authToken")

if(getRversion() >= "3.1.0")
    utils::suppressForeignCheck("authToken")


#############################
#     WEB AUTHENTICATION   #
############################



#' Login to GMQL
#'
#' Login to GMQL REST services suite as a registered user, specifying username 
#' and password, or as guest using the proper GMQL web service available 
#' on a remote server
#' 
#' @import httr
#' @importFrom rJava J
#' 
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param username string name used during signup
#' @param password string password used during signup
#'
#' @seealso \code{\link{logout_gmql}}
#'
#' @details
#' if both username and password are NULL you will be logged as guest
#' After login you will receive an authentication token.
#' As token remains vaild on server (until the next login / registration) 
#' a user can safely use a token fora previous session as a convenience, 
#' this token is saved in Global environment to perform subsequent REST call 
#' even on complete R restart (if is environemnt has been saved, of course ...)
#' If error occures a specific error is printed
#'
#' @return None
#'
#' @examples
#' ## login as guest
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' 
#' @name login_gmql
#' @rdname login_gmql
#' @export
#' 
login_gmql <- function(url, username = NULL, password = NULL)
{
    if(exists("authToken",envir = .GlobalEnv))
    {
        print("You are already logged")
        return(invisible(NULL))
    }
    as_guest <- TRUE
    
    if(!is.null(username) || !is.null(password))
        as_guest <- FALSE
    
    if(as_guest)
    {
        url <- sub("/*[/]$","",url)
        h <- c('Accept' = "Application/json")
        URL <- paste0(url,"/guest")
        req <- httr::GET(URL,httr::add_headers(h))
    }
    else
    {
        req <- httr::GET(url)
        real_URL <- req$url
        h <- c('Accept'="Application/json",'Content-Type'='Application/json')
        URL <- paste0(real_URL,"login")
        body <- list('username' = username,'password' = password)
        req <- httr::POST(URL,httr::add_headers(h),body = body,encode = "json")
    }
    
    content <- httr::content(req)
    
    if(req$status_code !=200)
        stop(content$errorString)
    else
    {
        assign("authToken",content$authToken,.GlobalEnv)
        WrappeR <- J("it/polimi/genomics/r/Wrapper")
        WrappeR$save_tokenAndUrl(authToken,url)
        print(paste("your Token is",authToken))
    }
}

#' Logout from GMQL
#' 
#' Logout from GMQL REST services suite
#' using the proper GMQL web service available on a remote server
#' 
#' @import httr
#' @importFrom rJava J
#' 
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#'
#' @details
#' After logout the authentication token will be invalidated.
#' The authentication token is removed from Global environment
#' If error occures a specific error is printed
#' 
#' @examples
#' 
#' ## login as guest, then logout
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' logout_gmql(remote_url)
#' 
#' @return None
#'
#' @name logout_gmql
#' @rdname logout_gmql
#' @export
#'
logout_gmql <- function(url)
{
    if(!exists("authToken",envir = .GlobalEnv))
        stop("you need to log in before")
    
    url <- sub("/*[/]$","",url)
    
    URL <- paste0(url,"/logout")
    h <- c('X-Auth-Token' = authToken)
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req)
    
    if(req$status_code !=200)
        stop(content$error)
    else
    {
        #delete token from environment
        WrappeR <- J("it/polimi/genomics/r/Wrapper")
        WrappeR$delete_token()
        if(exists("authToken",envir = .GlobalEnv))
            rm(authToken, envir = .GlobalEnv)
        
        print(content)
    }
}

#############################
#       WEB BROWSING       #
############################

#' Shows all Queries
#'
#' It shows all the GMQL query saved on repository 
#' using the proper GMQL web service available on a remote server
#' 
#' @import httr
#'
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#'
#' @return list of queries
#' Every query in the list is identified by:
#' \itemize{
#' \item{name: name of query}
#' \item{text: text of GMQL query}
#' }
#'
#' @details
#' if error occures, a specific error is printed
#'
#' @examples 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' list <- show_queries_list(remote_url)
#' 
#' @name show_queries_list
#' @rdname show_queries_list
#' @export
#'
show_queries_list <- function(url)
{
    url <- sub("/*[/]$","",url)
    
    URL <- paste0(url,"/query")
    h <- c('Accept' = 'Application/json', 'X-Auth-Token' = authToken)
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code==200)
        return(content)
    else
        stop(content$error)
}


#' Save GMQL query
#'
#' It saves the GMQL query into repository taken from file or insert as text 
#' string, using the proper GMQL web service available on a remote server
#' 
#' @import httr
#'
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param queryName string name of query
#' @param queryTxt string text of GMQL query
#'
#' @return None
#'
#' @details
#' if you save a query with the same name of an other query already stored 
#' in repository you will overwrite it,
#' if no error occures print "Saved" otherwise print the content error
#'
#' @examples
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r/"
#' login_gmql(remote_url)
#' save_query(remote_url, "dna_query", "DATASET = SELECT() HG19_TCGA_dnaseq; 
#' MATERIALIZE DATASET INTO RESULT_DS;")
#' 
#' test_path <- system.file("example", package = "RGMQL")
#' test_query <- file.path(test_path, "query1.txt")
#' save_query_fromfile(remote_url, "query1", test_query)
#' 
#' @name save_query
#' @rdname save_query
#' @export
#'
save_query <- function(url, queryName, queryTxt)
{
    req <- httr::GET(url)
    real_URL <- req$url
    URL <- paste0(real_URL,"query/",queryName,"/save")
    h <- c('Accept' = 'text/plain', 'X-Auth-Token' = authToken,
                'Content-Type' = 'text/plain')
    req <- httr::POST(URL, httr::add_headers(h),body = queryTxt)
    content <- httr::content(req)
    
    if(req$status_code==200)
        print(content) # print Saved
    else
        stop(content$error)
}

#' @param filePath string local file path of txt file containing a GMQL query
#' 
#' @name save_query_fromfile
#' @rdname save_query
#' @export
#' 
save_query_fromfile <- function(url, queryName, filePath)
{
    if(!file.exists(filePath))
        stop("file does not exist")
    
    queryTxt <- readLines(filePath)
    save_query(url,queryName,queryTxt)
}


#############################
#       WEB OPERATION      #
############################

#' Run a GMQL query
#' 
#' It runs the GMQL query into repository taken from file or insert as text 
#' string, using the proper GMQL web service available on a remote server
#' 
#' @import httr
#' 
#' @param url url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param fileName name of the file
#' @param query text of the query
#' @param output_gtf logical value indicating file format used for 
#' storing samples generated by the query.
#' The possiblities are: 
#' \itemize{
#' \item{GTF}
#' \item{TAB}
#' }
#'
#' @return None
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' 
#' \dontrun{
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r/"
#' login_gmql(remote_url)
#' run_query(remote_url, "query_1", "DATASET = SELECT() HG19_TCGA_dnaseq;
#' MATERIALIZE DATASET INTO RESULT_DS;", output_gtf = FALSE)
#' 
#' test_path <- system.file("example", package = "RGMQL")
#' test_query <- file.path(test_path, "query1.txt")
#' run_query(remote_url, "query_1", test_query, output_gtf = FALSE)
#' }
#' 
#' @rdname run_query
#' @name run_query
#' @export
#'
run_query <- function(url, fileName, query, output_gtf = TRUE)
{
    if(output_gtf)
        out <- "GTF"
    else
        out <- "TAB"
    
    req <- httr::GET(url)
    real_URL <- req$url
    URL <- paste0(real_URL,"queries/run/",fileName,"/",out)
    h <- c('Accept' = "Application/json",
                'Content-Type' = 'text/plain','X-Auth-Token' = authToken)
    
    req <- httr::POST(URL,body = query ,httr::add_headers(h),encode = "json")
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
}

#' @import httr
#' @param filePath string path of txt files containing a GMQL query
#' 
#' @rdname run_query
#' @name run_query
#' @export
#' 
run_query_fromfile <- function(url, fileName, filePath, output_gtf = TRUE)
{
    if(!file.exists(filePath))
        stop("file does not exist")
    
    query <- readLines(filePath)
    run_query(url,fileName,query,output_gtf)
}


#' Compile GMQL query
#'
#' It compiles the GMQL query into repository taken from file or insert as text 
#' string, using the proper GMQL web service available on a remote server
#' 
#' 
#' @import httr
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param query string text of the query
#'
#' @return None
#'
#' @examples
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r/"
#' login_gmql(remote_url)
#' compile_query(remote_url, "DATASET = SELECT() HG19_TCGA_dnaseq;
#' MATERIALIZE DATASET INTO RESULT_DS;")
#' 
#' \dontrun{
#' test_path <- system.file("example", package = "RGMQL")
#' test_query <- file.path(test_path, "query1.txt")
#' compile_query_fromfile(remote_url, test_query)
#' }
#' 
#' @name compile_query
#' @rdname compile_query
#' @export
#'
compile_query <- function(url, query)
{
    h <- c('Accept' = "Application/json",
                'Content-Type' = 'text/plain','X-Auth-Token' = authToken)
    req <- httr::GET(url)
    real_URL <- req$url
    URL <- paste0(real_URL,"queries/compile")
    req <- httr::POST(URL,body = query ,httr::add_headers(h),encode = "json")
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
}


#' @param filePath string path of txt files containing a GMQL query
#'
#' @name compile_query
#' @rdname compile_query
#' @export
#'
compile_query_fromfile <- function(url ,filePath)
{
    if(!file.exists(filePath))
        stop("file does not exist")
    
    query <- readLines(filePath)
    compile_query(url,query)
}


#' Stop a job
#'
#' It stops a specific current query job
#' 
#' @import httr
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param job_id string id of the job
#'
#' @return None
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' 
#' \dontrun{
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' list_jobs <- show_jobs_list(remote_url)
#' jobs_1 <- list_jobs$jobs[[1]]
#' stop_job(remote_url, jobs_1)
#' }
#' 
#' @name stop_job
#' @rdname stop_job
#' @export
#'
stop_job <- function(url, job_id)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/jobs/",job_id,"/stop")
    h <- c('X-Auth-Token' = authToken,'Accept'= 'text/plain')
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content)
    else
        print(content)
}


#' Show a job log or trace
#'
#' It show a job log or traces a specific job
#'
#' @import httr
#' @param url string url of server: It must contain the server address
#' and base url; service name is added automatically
#' @param job_id string id of the job
#'
#' @return log or trace text
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' \dontrun{
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' 
#' ## list all jobs
#' list_jobs <- show_jobs_list(remote_url)
#' jobs_1 <- list_jobs$jobs[[1]]
#' 
#' ## show job log
#' show_job_log(remote_url, jobs_1)
#' 
#' ## trace job
#' trace_job(remote_url, jobs_1)
#' 
#' }
#' 
#' @name log_job
#' @rdname log_job
#' @export
#'
show_job_log <- function(url, job_id)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/jobs/",job_id,"/log")
    h <- c('X-Auth-Token' = authToken,'Accept'= 'Application/json')
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        print(unlist(content,use.names = FALSE))
}



#' @import httr
#' 
#' @name trace_job
#' @rdname log_job
#' @export
#'
trace_job <- function(url, job_id)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/jobs/",job_id,"/trace")
    h <- c('X-Auth-Token' = authToken,'Accept'= 'Application/json')
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
    
}


#' Show all jobs
#'
#' It show all Jobs (run, succeded or failed) invoked by user
#' @import httr
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#'
#' @return list of jobs
#' Every job in the list is identified by:
#' \itemize{
#' \item{id: unique job identifier}
#' }
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' list_jobs <- show_jobs_list(remote_url)
#' 
#' @rdname show_jobs_list
#' @name show_jobs_list
#' @export
#' 
show_jobs_list <- function(url)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/jobs")
    h <- c('X-Auth-Token' = authToken)
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
}


#############################
#       WEB DATASET        #
############################

#' Show Datasets
#'
#' It show all GMQL dataset stored in repository using the proper GMQL 
#' web service available on a remote server
#' 
#' @import httr
#' @param url single string url of server: It must contain the server address 
#' and base url; service name is added automatically
#'
#' @return list of datasets.
#'
#' Every dataset in the list is identified by:
#' \itemize{
#' \item{name: name of dataset}
#' \item{owner: public or name of the user}
#' }
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' list <- show_datasets_list(remote_url)
#' @name show_dataset
#' @rdname show_dataset
#' @export
#'
show_datasets_list <- function(url)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/datasets")
    h <- c('X-Auth-Token' = authToken)
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed") #JSON
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
}


#' Show dataset samples
#'
#' It show all sample from a specific GMQL dataset using the proper 
#' GMQL web service available on a remote server
#' 
#' @import httr
#'
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param datasetName name of dataset to get
#' if the dataset is a public dataset, we have to add "public." as prefix, 
#' as shown in the example below otherwise no prefix is needed
#'
#' @return list of samples in dataset.
#'
#' Every sample in the list is identified by:
#' \itemize{
#' \item{id: id of sample}
#' \item{name: name of sample}
#' \item{path: sample repository path}
#' }
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' list <- show_samples_list(remote_url, "public.HG19_BED_ANNOTATION")
#' 
#' @name show_samples_list
#' @rdname show_samples_list
#' @export
show_samples_list <- function(url,datasetName)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/datasets/",datasetName)
    h <- c('X-Auth-Token' = authToken)
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
}

#' Show dataset schema
#'
#' It shows the region attribute schema of a specific GMQL dataset using 
#' the proper GMQL web service available on a remote server
#' 
#' @import httr
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param datasetName name of dataset to get
#' if the dataset is a public dataset, we have to add "public." as prefix, 
#' as shown in the example below otherwise no prefix is needed
#'
#' @return list of region schema fields.
#'
#' Every field in the list is identified by:
#' \itemize{
#' \item{name: name of field (e.g. chr, start, end, strand ...)}
#' \item{fieldType: (e.g STRING, DOUBLE ...)}
#' }
#'
#' @details
#' If error occures a specific error is printed
#' 
#' @examples
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' list <- show_schema(remote_url, "public.HG19_BED_ANNOTATION")
#' 
#' @name show_schema
#' @rdname show_schema
#' @export
#'
show_schema <- function(url,datasetName)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/datasets/",datasetName,"/schema")
    h <- c('X-Auth-Token' = authToken)
    #req <- GET(url, add_headers(h),verbose(data_in = TRUE,info = TRUE))
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed")
    if(req$status_code != 200)
        stop(content$error)
    else
        return(content)
}

#' Upload dataset
#'
#'
#' It uploads a folder (GMQL or not) containing sample files using 
#' the proper GMQL web service available on a remote server: 
#' a new dataset is created on repository
#' 
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param datasetName name of dataset to get
#' @param folderPath string local path to the folder containing the samples
#' @param schemaName string name of schema used to parse the samples
#' schemaName available are:
#' \itemize{
#' \item{NARROWPEAK}
#' \item{BROADPEAK}
#' \item{VCF}
#' \item{BED}
#' \item{BEDGRAPH}
#' }
#' if schema is NULL it's looking for a XML schema file to read
#' @param isGMQL logical value indicating whether is GMQL dataset or not
#'
#' @return None
#'
#' @details
#' If no error occures print "Upload Complete", otherwise a specific error 
#' is printed
#'
#' @examples
#'
#' \dontrun{
#' 
#' ### upload of GMQL dataset with no schema selection
#' test_path <- system.file("example", "DATASET_GDM", package = "RGMQL")
#' remote_url <- "http://genomic.elet.polimi.it/gmql-rest-r/"
#' login_gmql(remote_url)
#' upload_dataset(remote_url, "dataset1", folderPath = test_path)
#' }
#' @name upload_dataset
#' @rdname upload_dataset
#' @export
#'
upload_dataset <- function(url,datasetName,folderPath,schemaName=NULL,
                                isGMQL=TRUE)
{
    if(isGMQL)
        folderPath <- paste0(folderPath,"/files")
    
    files <- list.files(folderPath,full.names = TRUE)
    if(length(files)==0)
        stop("no files present")
    count = .counter(0)
    
    list_files <- lapply(files, function(x) {
        file <- httr::upload_file(x)
    })
    
    list_files_names <- sapply(list_files, function(x) {
        paste0("file",count())
    })
    
    names(list_files) <- list_files_names
    req <- httr::GET(url)
    real_URL <- req$url
    URL <- paste0(real_URL,"datasets/",datasetName,"/uploadSample")
    h <- c('X-Auth-Token' = authToken, 'Accept:' = 'Application/json')
    
    schema_name <- tolower(schemaName)
    
    if(is.null(schemaName))
    {
        schema_name <- list.files(folderPath, pattern = "*.schema$",
                                    full.names = TRUE)
        if(length(schema_name)==0)
            stop("schema must be present")
        
        list_files <- list(list("schema" = httr::upload_file(schema_name)),
                                    list_files)
        list_files <- unlist(list_files,recursive = FALSE)
        URL <- paste0(real_URL,"datasets/",datasetName,"/uploadSample")
    }
    else
    {
        schema_name <- tolower(schemaName)
        if(identical(schema_name,"customparser"))
        {
            schema_name <- list.files(folderPath, pattern = "*.schema$",
                                        full.names = TRUE)
            if(length(schema_name)==0)
                stop("schema must be present")
            
            list_files <- list(list("schema" = httr::upload_file(schema_name)),
                                    list_files)
            list_files <- unlist(list_files,recursive = FALSE)
            
            URL <- paste0(real_URL,"datasets/",datasetName,"/uploadSample")
        }
        else
        {
            if(!identical(schema_name,"narrowpeak") && 
                !identical(schema_name,"vcf") && 
                !identical(schema_name,"broadpeak") && 
                !identical(schema_name,"bed")  && 
                !identical(schema_name,"bedgraph"))
                stop("schema not admissable")
            
            URL <- paste0(real_URL,"datasets/",datasetName,
                            "/uploadSample?schemaName=",schema_name)
        }
    }
    
    req <- httr::POST(URL, body = list_files ,httr::add_headers(h))
    content <- httr::content(req)
    if(req$status_code !=200)
        print(content)
    else
        print("upload Complete")
}

#' Delete dataset
#'
#' It deletes single private dataset specified by name from repository 
#' using the proper GMQL web service available on a remote server
#' 
#' @import httr
#'
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param datasetName string name of dataset to delete
#'
#' @return None
#' 
#' @details
#' If no error occur, print "Deleted Dataset", otherwise a specific error 
#' is printed
#'
#' @seealso \code{\link{download_dataset}}
#'
#' @examples
#'
#' \dontrun{
#' 
#' ## This dataset does not exist
#' 
#' remote_url <- "http://genomic.elet.polimi.it/gmql-rest-r/"
#' login_gmql(remote_url)
#' delete_dataset(remote_url, "job_test1_test101_20170604_180908_RESULT_DS")
#' 
#' }
#' 
#' @name delete_dataset
#' @rdname delete_dataset
#' @export
#'
delete_dataset <- function(url,datasetName)
{
    req <- httr::GET(url)
    real_URL <- req$url
    URL <- paste0(real_URL,"datasets/",datasetName)
    h <- c('X-Auth-Token' = authToken, 'Accept:' = 'application/json')
    req <- httr::DELETE(URL, httr::add_headers(h))
    content <- httr::content(req,"parsed") #JSON
    
    if(req$status_code !=200)
        stop(content$error)
    else
        print(content$result)
}

#' Download Dataset
#'
#' It donwloads private dataset as zip file from repository to local path or
#' donwloads saving it into R environemnt as GrangesList using the proper 
#' GMQL web service available on a remote server
#' 
#' @import httr
#' @importFrom utils unzip
#'
#' @param url string url of server: It must contain the server address 
#' and base url; service name will be added automatically
#' @param datasetName string name of dataset we want to get
#' @param path string local path folder where store dataset,
#' by defualt is R working directory
#' @return None
#'
#' @details
#' If error occures a specific error is printed
#'
#'
#' @examples
#'
#' ## download dataset in r working directory
#' ## in this case we try to download public dataset
#' 
#' \dontrun{
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' download_dataset(remote_url, "public.HG19_BED_ANNOTATION", path = getwd())
#' 
#' ## create grangeslist from public dataset HG19_BED_ANNOTATION got 
#' ## from repository
#' 
#' download_as_GRangesList(remote_url, "public.HG19_BED_ANNOTATION")
#' }
#' 
#' @name download_dataset
#' @rdname download_dataset
#' @export
#'
download_dataset <- function(url,datasetName,path = getwd())
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/datasets/",datasetName,"/zip")
    h <- c('X-Auth-Token' = authToken, 'Accept' = 'application/zip')
    req <- httr::GET(URL,httr::add_headers(h))
    
    content <- httr::content(req)
    if(req$status_code !=200)
        print(content)
    else
    {
        zip_path <- paste0(path,"/",datasetName,".zip")
        dir_out <-paste0(path,"/")
        writeBin(content,zip_path)
        unzip(zip_path,exdir=dir_out)
        print("Download Complete")
    }
}

#' @import httr
#' @importClassesFrom GenomicRanges GRangesList
#' @importFrom S4Vectors metadata
#' 
#' @return GrangesList containing all GMQL sample in dataset
#' 
#' @name download_as_GRangesList
#' @rdname download_dataset
#' @export
#'
download_as_GRangesList <- function(url,datasetName)
{
    list <- show_samples_list(url,datasetName)
    samples <- list$samples
    sample_list_name <- sapply(samples, function(x){
        name <- x$name
    })
    
    sampleList <- lapply(samples, function(x){
        name <- x$name
        range <- sample_region(url,datasetName,name)
    })
    
    names(sampleList) <- sample_list_name
    gRange_list <- GenomicRanges::GRangesList(sampleList)
    
    meta_list <- lapply(samples, function(x){
        name <- x$name
        meta <- sample_metadata(url,datasetName,name)
    })
    names(meta_list) <- sample_list_name
    S4Vectors::metadata(gRange_list) <- meta_list
    return(gRange_list)
}




#' Shows metadata list from dataset sample
#'
#' It retrieves metadata for a specific sample in dataset using the proper 
#' GMQL web service available on a remote server
#' 
#' @import httr
#'
#' @param url string url of server: It must contain the server address 
#' and base url; service name is added automatically
#' @param datasetName string name of dataset to get
#' @param sampleName string sample name to get
#'
#' @return list of metadata in the form 'key = value'
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' 
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' sample_metadata(remote_url, "public.HG19_BED_ANNOTATION", "promoters")
#' 
#'
#' @name sample_metadata
#' @rdname sample_metadata
#' @export
#'
sample_metadata <- function(url, datasetName,sampleName)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/datasets/",datasetName,"/",sampleName,"/metadata")
    h <- c('X-Auth-Token' = authToken, 'Accpet' = 'text/plain')
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req, 'text',encoding = "UTF-8")
    
    #trasform text to list
    metadata <- strsplit(content, "\n")
    metadata <- strsplit(unlist(metadata), "\t")
    names(metadata) <- sapply(metadata, `[[`, 1)
    listMeta <- lapply(metadata, `[`, -1)
    
    if(req$status_code !=200)
        stop(content)
    else
        return(listMeta)
}


#' Shows regions from a dataset sample
#' 
#' It retrieves regions for a specific sample 
#' (whose name is specified in the paramter "sampleName")
#' in a specific dataset 
#' (whose name is specified in the parameter "datasetName") 
#' using the proper GMQL web service available on a remote server
#' 
#' @import httr
#' @importFrom rtracklayer import
#' @importFrom data.table fread
#' @importFrom GenomicRanges makeGRangesFromDataFrame
#' @importFrom utils write.table
#'
#' @param url string url of server: it must contain the server address
#' and base url; service name is added automatically
#' @param datasetName string name of dataset to get
#' @param sampleName string sample name to get
#'
#' @return Granges data containing regions of sample
#'
#' @details
#' If error occures a specific error is printed
#'
#' @examples
#' 
#' \dontrun{
#' remote_url = "http://genomic.elet.polimi.it/gmql-rest-r"
#' login_gmql(remote_url)
#' sample_region(remote_url, "public.HG19_BED_ANNOTATION", "promoters")
#' }
#' 
#' @name sample_region
#' @rdname sample_region
#' @export
#'
sample_region <- function(url, datasetName,sampleName)
{
    url <- sub("/*[/]$","",url)
    URL <- paste0(url,"/datasets/",datasetName,"/",sampleName,"/region")
    h <- c('X-Auth-Token' = authToken, 'Accpet' = 'text/plain')
    req <- httr::GET(URL, httr::add_headers(h))
    content <- httr::content(req, 'parsed',encoding = "UTF-8")
    
    if(req$status_code !=200)
        stop(content)
    else
    {
        list <- show_schema(url,datasetName)
        schema_type <- list$type
        
        temp <- tempfile("temp") #use temporary files
        write.table(content,temp,quote = FALSE,sep = '\t',col.names = FALSE,
                        row.names = FALSE)
        if(schema_type=="gtf")
            samples <- rtracklayer::import(temp,format = "gtf")
        else
        {
            vector_field <- sapply(list$fields,function(x){
                name <- x$name
            })
            df <- data.table::fread(temp,header = FALSE,sep = "\t")
            a <- df[1,2]
            if(is.na(as.numeric(a)))
                df <- df[-1]
            data.table::setnames(df,vector_field)
            samples <- GenomicRanges::makeGRangesFromDataFrame(df,
                                        keep.extra.columns = TRUE,
                                        start.field = "left",
                                        end.field = "right",
                                        strand.field="strand")
        }
        unlink(temp)
        return(samples)
    }
}


#############################
#        WEB UTILS         #
############################


# no export
serialize_query <- function(url,output_gtf,base64)
{
    if(output_gtf)
        out <- "gtf"
    else
        out <- "tab"
    
    req <- httr::GET(url)
    real_URL <- req$url
    
    URL <- paste0(real_URL,"queries/dag/",out)
    h <- c('Accept' = "Application/json",
            'Content-Type' = 'text/plain','X-Auth-Token' = authToken)
    
    req <- httr::POST(URL,body = base64 ,httr::add_headers(h),encode = "json")
    content <- httr::content(req,"parsed")
    if(req$status_code !=200)
        stop(content$error)
    else
        return(content)
}
