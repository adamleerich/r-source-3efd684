#  File src/library/utils/R/sourceutils.R
#  Part of the R package, https://www.R-project.org
#
#  Copyright (C) 1995-2023 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  https://www.R-project.org/Licenses/

# move to base (!?)
removeSource <- function(fn) {

    recurse <- function(part) {
        if (is.name(part)) return(part)  # handles missing arg, PR#15957
        if (inherits(part, "srcref")) return(NULL)
        attr(part, "srcref") <- NULL
        attr(part, "wholeSrcref") <- NULL
        attr(part, "srcfile") <- NULL

        if (is.pairlist(part)) { # source references from formal arguments of sub-functions
            ## PR#18638, Andrew Simmons
            for (i in seq_along(part))
                part[i] <- list(recurse(part[[i]]))
            return(as.pairlist(part))
        }
	if (is.language(part) && is.recursive(part)) {
	    for (i in seq_along(part))
		part[i] <- list(recurse(part[[i]])) # recurse(*) may be NULL
	}
        part
    }

    if(is.function(fn)) {
        if(!is.primitive(fn)) {
            attr(fn, "srcref") <- NULL
            ## `body<-`(f, *) drops all attributes of f
            at <- attributes(fn)
            formals(fn) <- recurse(formals(fn))
            attr(body(fn), "wholeSrcref") <- NULL
            attr(body(fn), "srcfile") <- NULL
            body(fn) <- recurse(body(fn))
            if(!is.null(at)) attributes(fn) <- at
        }
        fn
    }
    else if(is.language(fn)) { # expression, call, or symbol=name
	recurse(fn)
    }
    else
	stop("argument is not a function or language object:", typeof(fn))
}


getSrcFilename <- function(x, full.names=FALSE, unique=TRUE) {
    srcref <- getSrcref(x)
    if (is.list(srcref))
    	result <- sapply(srcref, getSrcFilename, full.names, unique)
    else {
    	srcfile <- attr(srcref, "srcfile")
    	if (is.null(srcfile)) result <- character()
    	else result <- srcfile$filename
    }
    result <- if (full.names) result
              else basename(result)
    if (unique) unique(result)
    else result
}

getSrcDirectory <- function(x, unique=TRUE) {
    result <- dirname(getSrcFilename(x, full.names=TRUE, unique=unique))
    if (unique) unique(result)
    else result
}

getSrcref <- function(x) {
    if (inherits(x, "srcref"))
        x
    else if (!is.null(srcref <- attr(x, "srcref")) ||
             is.function(x) && !is.null(srcref <- getSrcref(body(x))))
        srcref
    else if (methods::is(x, "MethodDefinition"))
	getSrcref(unclass(methods::unRematchDefinition(x)))
    ## else NULL
}

getSrcLocation <- function(x, which=c("line", "column", "byte", "parse"), first=TRUE) {
    srcref <- getSrcref(x)
    if (is.null(srcref)) return(NULL)
    if (is.list(srcref)) sapply(srcref, getSrcLocation, which, first)
    else {
        if (length(srcref) == 6L) srcref <- c(srcref, srcref[c(1L,3L)])
    	which <- match.arg(which)
    	if (first) index <- c(line=1L, column=5L, byte=2L, parse=7L)[which]
    	else       index <- c(line=3L, column=6L, byte=4L, parse=8L)[which]
    	srcref[index]
    }
 }

##' Simplified version of  getSrcLocation(x, "byte", first=TRUE),
##' always returning  integer(1)
getSrcByte <- function(x) {
    srcref <- attr(x, "srcref")
    if(is.null(srcref)) -1L else srcref[2L]
}


getSrcfile <- function(x) {
    if (!is.null(r <- attr(x, "srcfile"))) return(r)
    srcref <- attr(x, "wholeSrcref")
    if (is.null(srcref)) {
	srcref <- getSrcref(x)
    	if (is.list(srcref) && length(srcref))
    	    srcref <- srcref[[length(srcref)]]
    }
    attr(srcref, "srcfile")
}

substr_with_tabs <- function(x, start, stop, tabsize = 8) {
    widths <- rep_len(1, nchar(x))
    tabs <- which(strsplit(x,"")[[1]] == "\t")
    for (i in tabs) {
	cols <- cumsum(widths)
	widths[i] <- tabsize - (cols[i] - 1) %% tabsize
    }
    cols <- cumsum(widths)
    start <- which(cols >= start)
    if (!length(start))
    	return("")
    start <- start[1]
    stop <- which(cols <= stop)
    if (length(stop)) {
    	stop <- stop[length(stop)]
    	substr(x, start, stop)
    } else
    	""
}

getParseData <- function(x, includeText = NA) {
    srcfile <- if(inherits(x, "srcfile")) x else getSrcfile(x)
    if (is.null(srcfile))
    	return(NULL)

    data <- srcfile$parseData
    if (is.null(data) && !is.null(srcfile$original))
        data <- srcfile$original$parseData
        
    if (!is.null(data)) {
        tokens <- attr(data, "tokens")
        data <- t(unclass(data))
        colnames(data) <- c( "line1", "col1",
		 	     "line2", "col2",
		 	     "terminal", "token.num", "id", "parent" )
    	data <- data.frame(data[, -c(5,6), drop = FALSE], token = tokens,
    	                   terminal = as.logical(data[,"terminal"]),
    	                   text = attr(data, "text"),
    			   stringsAsFactors = FALSE)
    	o <- order(data[,1], data[,2], -data[,3], -data[,4])
    	data <- data[o,]
    	rownames(data) <- data$id
    	attr(data, "srcfile") <- srcfile
	gettext <-
	    if(isTRUE(includeText))
		which(!nzchar(data$text))
	    else if(is.na(includeText))
		which(!nzchar(data$text) & data$terminal)
	    else {
		data$text <- NULL
		integer(0)
	    }
        if (length(gettext))
	    data$text[gettext] <- getParseText(data, data$id[gettext])
    }
    data
}

getParseText <- function(parseData, id) {
    srcfile <- attr(parseData, "srcfile")
    d <- parseData[as.character(id),]
    text <- d$text
    if (is.null(text)) {
    	text <- character(nrow(d))
    	blank <- seq_along(text)
    } else
    	blank <- which(!nzchar(text) | (d$token == "STR_CONST" & startsWith(text, "[")))
    for (i in blank) {
	lines <- getSrcLines(srcfile, d$line1[i], d$line2[i])
        n <- length(lines)
        lines[n] <- substr_with_tabs(lines[n], 1, d$col2[i])
        lines[1] <- substr_with_tabs(lines[1], d$col1[i], Inf)
        text[i] <- paste(lines, collapse="\n")
    }
    text
}
