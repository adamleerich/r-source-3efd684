% File src/library/utils/man/read.DIF.Rd
% Part of the R package, https://www.R-project.org
% Copyright 1995-2014 R Core Team
% Distributed under GPL 2 or later

\name{read.DIF}
\alias{read.DIF}
\title{Data Input from Spreadsheet}
\description{
  Reads a file in Data Interchange Format (\abbr{DIF}) and creates a
  data frame from it.  \abbr{DIF} is a format for data matrices such as
  single spreadsheets. 
}
\usage{
read.DIF(file, header = FALSE,
         dec = ".", numerals = c("allow.loss", "warn.loss", "no.loss"),
         row.names, col.names, as.is = !stringsAsFactors,
         na.strings = "NA", colClasses = NA, nrows = -1,
         skip = 0, check.names = TRUE, blank.lines.skip = TRUE,
         stringsAsFactors = FALSE,
         transpose = FALSE, fileEncoding = "")
}
\arguments{
  \item{file}{the name of the file which the data are to be read from,
    or a \link{connection}, or a complete URL.

    The name \code{"clipboard"} may also be used on Windows, in which
    case \code{read.DIF("clipboard")} will look for a \abbr{DIF} format entry
    in the Windows clipboard.
  }

  \item{header}{a logical value indicating whether the spreadsheet contains the
    names of the variables as its first line.  If missing, the value is
    determined from the file format: \code{header} is set to \code{TRUE}
    if and only if the first row contains only character values and
    the top left cell is empty.}

  \item{dec}{the character used in the file for decimal points.}

  \item{numerals}{string indicating how to convert numbers whose conversion
    to double precision would lose accuracy, see \code{\link{type.convert}}.}

  \item{row.names}{a vector of row names.  This can be a vector giving
    the actual row names, or a single number giving the column of the
    table which contains the row names, or character string giving the
    name of the table column containing the row names.

    If there is a header and the first row contains one fewer field than
    the number of columns, the first column in the input is used for the
    row names.  Otherwise if \code{row.names} is missing, the rows are
    numbered.

    Using \code{row.names = NULL} forces row numbering.
  }

  \item{col.names}{a vector of optional names for the variables.
    The default is to use \code{"V"} followed by the column number.}

  \item{as.is}{controls conversion of character variables (insofar as
    they are not converted to logical, numeric or complex) to factors,
    if not otherwise specified by \code{colClasses}.
    Its value is either a vector of logicals (values are recycled if
    necessary), or a vector of numeric or character indices which
    specify which columns should not be converted to factors.

    Note: In releases prior to \R{} 2.12.1, cells marked as being of
    character type were converted to logical, numeric or complex using
    \code{\link{type.convert}} as in \code{\link{read.table}}.

    Note: to suppress all conversions including those of numeric
    columns, set \code{colClasses = "character"}.

    Note that \code{as.is} is specified per column (not per
    variable) and so includes the column of row names (if any) and any
    columns to be skipped.
  }

  \item{na.strings}{a character vector of strings which are to be
    interpreted as \code{\link{NA}} values.  Blank fields are also
    considered to be missing values in logical, integer, numeric and
    complex fields.}

  \item{colClasses}{character.  A vector of classes to be assumed for
    the columns.  Recycled as necessary, or if the character vector is
    named, unspecified values are taken to be \code{NA}.

    Possible values are \code{NA} (when \code{\link{type.convert}} is
    used), \code{"NULL"} (when the column is skipped), one of the atomic
    vector classes (logical, integer, numeric, complex, character, raw),
    or \code{"factor"}, \code{"Date"} or \code{"POSIXct"}.  Otherwise
    there needs to be an \code{as} method (from package \pkg{methods})
    for conversion from \code{"character"} to the specified formal
    class.

    Note that \code{colClasses} is specified per column (not per
    variable) and so includes the column of row names (if any).
  }

  \item{nrows}{the maximum number of rows to read in.  Negative values
    are ignored.}

  \item{skip}{the number of lines of the data file to skip before
    beginning to read data.}

  \item{check.names}{logical.  If \code{TRUE} then the names of the
    variables in the data frame are checked to ensure that they are
    syntactically valid variable names.  If necessary they are adjusted
    (by \code{\link{make.names}}) so that they are, and also to ensure
    that there are no duplicates.}

  \item{blank.lines.skip}{logical: if \code{TRUE} blank lines in the
    input are ignored.}

  \item{stringsAsFactors}{logical: should character vectors be converted
    to factors?}

  \item{transpose}{logical, indicating if the row and column
    interpretation should be transposed.  Microsoft's Excel has been
    known to produce (non-standard conforming) \abbr{DIF} files which would
    need \code{transpose = TRUE} to be read correctly.}
  
  \item{fileEncoding}{character string: if non-empty declares the
    encoding used on a file (not a connection or clipboard) so the
    character data can be re-encoded.  See the \sQuote{Encoding} section
    of the help for \code{\link{file}}, the \sQuote{R Data Import/Export}
    manual and \sQuote{Note}.}
}
\value{
  A data frame (\code{\link{data.frame}}) containing a representation of
  the data in the file.  Empty input is an error unless \code{col.names}
  is specified, when a 0-row data frame is returned: similarly giving
  just a header line if \code{header = TRUE} results in a 0-row data frame.
}

\note{
  The columns referred to in \code{as.is} and \code{colClasses} include
  the column of row names (if any).

  Less memory will be used if \code{colClasses} is specified as one of
  the six atomic vector classes.
}
\author{R Core; \code{transpose} option by Christoph Buser, ETH Zurich}
\seealso{
  The \emph{R Data Import/Export} manual.

  \code{\link{scan}}, \code{\link{type.convert}},
  \code{\link{read.fwf}} for reading \emph{f}ixed \emph{w}idth
  \emph{f}ormatted input;
  \code{\link{read.table}};
  \code{\link{data.frame}}.
}
\references{
  The DIF format specification can be found by searching on
  \url{http://www.wotsit.org/}; the optional header fields are ignored.
  See also
  \url{https://en.wikipedia.org/wiki/Data_Interchange_Format}.

  The term is likely to lead to confusion: Windows will have a
  \sQuote{Windows Data Interchange Format (DIF) data format} as part of
  its WinFX system, which may or may not be compatible.
}
\examples{
## read.DIF() may need transpose = TRUE for a file exported from Excel
udir <- system.file("misc", package = "utils")
dd <- read.DIF(file.path(udir, "exDIF.dif"), header = TRUE, transpose = TRUE)
dc <- read.csv(file.path(udir, "exDIF.csv"), header = TRUE)
stopifnot(identical(dd, dc), dim(dd) == c(4,2))
}
\keyword{file}
\keyword{connection}
