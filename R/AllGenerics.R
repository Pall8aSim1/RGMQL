#' Method cover
#' 
#' Wrapper to GMQL COVER operator
#' 
#' @name cover
#' @rdname cover
#' @aliases cover
#' 
setGeneric("cover", function(.data, ...) standardGeneric("cover"))

#' Method map
#' 
#' Wrapper to GMQL MAP operator
#' 
#' @name map
#' @rdname map
#' @aliases map,GMQLDataset-method
#' 
setGeneric("map", function(x, y, ...) standardGeneric("map"))


#' Method take
#' 
#' Wrapper to TAKE operation
#' 
#' @name take
#' @rdname take
#' @aliases take,GMQLDataset-method
#' 
setGeneric("take", function(.data, ...) standardGeneric("take"))


#' Method extend
#' 
#' Wrapper to GMQL EXTEND operator 
#' 
#' @name extend
#' @rdname extend
#' @aliases extend,GMQLDataset-method
#' 
setGeneric("extend", function(.data, ...) standardGeneric("extend"))

