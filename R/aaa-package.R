#' @import graphics
#' @import rngtools
#' @import digest
#' @import stringr
#' @import stats
#' @import methods
NULL
#library(digest)

#' Defunct Functions and Classes in the NMF Package
#' 
#' @name NMF-defunct
#' @rdname NMF-defunct
NULL

#' Deprecated Functions in the Package NMF
#' 
#' @param object an R object
#' @param ... extra arguments 
#' 
#' @name NMF-deprecated
#' @rdname NMF-deprecated
NULL



#' @aliases NMF
#' @docType package
#' @useDynLib NMF, .registration = TRUE
#' 
#' @bibliography ~/Documents/articles/library.bib
#' @references
#' \url{https://cran.r-project.org/}
#' 
#' \url{https://renozao.github.io/NMF}
#' @keywords package
#' @seealso \code{\link{nmf}}
#' @examples
#' # generate a synthetic dataset with known classes
#' n <- 50; counts <- c(5, 5, 8);
#' V <- syntheticNMF(n, counts)
#' 
#' # perform a 3-rank NMF using the default algorithm
#' res <- nmf(V, 3)
#' 
#' basismap(res)
#' coefmap(res)
#' 
"_PACKAGE"

# local config info
nmfConfig <- mkoptions()

.onLoad <- function(libname, pkgname) {
		
	# set default number of cores
	if( pkgmaker::isCHECK() ){
		options(cores=2)
	}else{
		if( nchar(nc <- Sys.getenv('R_PACKAGE_NMF_CORES')) > 0 ){
			try({
				nmf.options(cores=as.numeric(nc))
			})
		}   
	}
    # use grid patch?
    if( !is.na(Sys.getenv_value('R_PACKAGE_NMF_GRID_PATCH', raw = TRUE)) )
      nmf.options(grid.patch = !isFALSE(Sys.getenv_value('R_PACKAGE_NMF_GRID_PATCH')))
    
    pkgEnv <- pkgmaker::packageEnv()
	.init.sequence <- function(){
	
		## 0. INITIALIZE PACKAGE SPECFIC OPTIONS
		#.init.nmf.options()
				
		## 1. INITIALIZE THE NMF MODELS
		.init.nmf.models()		
		
		## 2. INITIALIZE BIOC LAYER
		b <- body(.onLoad.nmf.bioc)
		bioc.loaded <- eval(b, envir=pkgEnv)
		nmfConfig(bioc=bioc.loaded)
		
		# 3. SHARED MEMORY
		if( .Platform$OS.type != 'windows' ){
			msg <- if( !require.quiet('bigmemory', character.only=TRUE) ) 'bigmemory'
					else if( !require.quiet('synchronicity', character.only=TRUE) ) 'synchronicity'
					else TRUE
			
			nmfConfig(shared.memory=msg)
		}
		#
	}
		
	# run intialization sequence suppressing messages or not depending on verbosity options
	.init.sequence()
	if( getOption('verbose') ) .init.sequence()
	else suppressMessages(.init.sequence())
	
	
	return(invisible())
}

.onUnload <- function(libpath) {
	
	# unload compiled library
	dlls <- names(base::getLoadedDLLs())
	if ( 'NMF' %in%  dlls )
		library.dynam.unload("NMF", libpath);	
}

.onAttach <- function(libname, pkgname){
	
	# build startup message
	msg <- NULL
	details <- NULL
	## 1. CHECK BIOC LAYER
	bioc.loaded <- nmfConfig('bioc')[[1L]]
	msg <- paste0(msg, 'BioConductor layer')
	if( is(bioc.loaded, 'try-error') ) msg <- paste0(msg, ' [ERROR]')
	else if ( isTRUE(bioc.loaded) ) msg <- paste0(msg, ' [OK]')
	else{
		msg <- paste0(msg, ' [NO: missing Biobase]')
		details <- c(details, "  To enable the Bioconductor layer, try: install.extras('", pkgname, "') [with Bioconductor repository enabled]")
	}
	
	# 2. SHARED MEMORY
	msg <- paste0(msg, ' | Shared memory capabilities')
	if( .Platform$OS.type != 'windows' ){
		conf <- nmfConfig('shared.memory')[[1L]]
		if( isTRUE(conf) ) msg <- paste0(msg, ' [OK]')
		else{
			msg <- paste0(msg, ' [NO: ', conf, ']')
			details <- c(details, "  To enable shared memory capabilities, try: install.extras('", pkgname, "')")
		}
	}else msg <- paste0(msg, ' [NO: windows]')
	#
	
	# 3. NUMBER OF CORES
	msg <- paste0(msg, ' | Cores ', getMaxCores(), '/', getMaxCores(limit=FALSE))
	#
	
	# FINAL. CRAN FLAG
	if( pkgmaker::isCHECK() ){
		msg <- paste0(msg, ' | CRAN check')
	}
	#
	
	# print startup message
	ver <- if( isDevNamespace() ){
		paste0(' [', utils::packageVersion(pkgname), '-devel', ']') 
	}#else{
#		utils::packageVersion(pkgname, lib.loc = libname)
#	}
	packageStartupMessage(pkgname, ver, ' - ', msg)
	if( !is.null(details) ){
		packageStartupMessage(paste(details, collapse="\n"))
	}
}

