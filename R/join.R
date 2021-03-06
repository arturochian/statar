#' Join two data.tables together 
#' 
#' @param x The master data.table
#' @param y The using data.table
#' @param on Character vectors specifying variables to match on. Default to common names between x and y. 
#' @param kind The kind of (SQL) join among "outer" (default), "left", "right", "inner", "semi", "anti" and "cross". 
#' @param suffixes A character vector of length 2 specifying suffix of overlapping columns. Defaut to ".x" and ".y".
#' @param check A formula checking for the presence of duplicates. Specifying 1~m (resp m~1, 1~1) checks that joined variables uniquely identify observations in x (resp y, both).
#' @param gen Name of new variable to mark result, or the boolean FALSE (default) if no such variable should be created. The variable equals 1 for rows in master only, 2 for rows in using only, 3 for matched rows.
#' @param inplace A boolean. In case "kind"= "left" and RHS of check is 1, the merge can be one in-place. 
#' @param update A boolean. For common variables in x and y not specified in "on", replace missing observations by the non missing observations in y. 
#' @param type Deprecated
#' @return A data.table that joins rows in master and using datases. Importantly, if x or y are not keyed, the join may change their row orders.
#' @examples
#' library(data.table)
#' x <- data.table(a = rep(1:2, each = 3), b=1:6)
#' y <- data.table(a = 0:1, bb = 10:11)
#' join(x, y, kind = "outer")
#' join(x, y, kind = "left", gen = "_merge")
#' join(x, y, kind = "right", gen = "_merge")
#' join(x, y, kind = "inner", check = m~1)
#' join(x, y, kind = "semi")
#' join(x, y, kind = "anti")
#' setnames(y, "bb", "b")
#' join(x, y, on = "a")
#' join(x, y, on = "a", suffixes = c("",".i"))
#' y <- data.table(a = 0:1, bb = 10:11)
#' join(x, y, kind = "left", check = m~1, inplace = TRUE)
#' x <- data.table(a = c(1,2), b=c(NA, 2))
#' y <- data.table(a = c(1,2), b = 10:11)
#' join(x, y, kind = "left", on = "a",  update = TRUE)
#' join(x, y, kind = "left", on = "a", chec = m~1, inplace = TRUE,  update = TRUE)

#' @export
join =  function(x, y, on = intersect(names(x),names(y)), kind = "outer" , suffixes = c(".x",".y"), check = m~m,  gen = FALSE, inplace = FALSE, update = FALSE, type){

  #kind
  if (!missing(type)){
    warning("type is deprecated, please use the option kind")
    kind <- type
  }

  if (anyDuplicated(names(x))) stop("Duplicate names in x are not allowed")
  if (anyDuplicated(names(y))) stop("Duplicate names in y are not allowed")

  kind <- match.arg(kind, c("outer", "left", "right", "inner", "cross", "semi", "anti"))

  if (!is.data.table(x)){
    stop(paste0("x is not a data.table. Convert it first using setDT(x)"))
  }
  if (!is.data.table(y)){
    stop(paste0("y is not a data.table. Convert it first using setDT(y)"))
  }
  
  # check inplace possible
  if (inplace & !((kind =="left") & check[[3]]==1)){
      stop("inplace = TRUE but kind is not left or formula is not ~1)")
  }

  # check gen
  if (gen != FALSE & !(kind %in% c("left", "right", "outer"))){
    stop(" The option gen only makes sense for left, right and outer joins", call. = FALSE)
  }

  if (inplace){
      xx<-x
    } else{
     xx <- shallow(x)
  }
  yy <- shallow(y)


    # find names and  check no common names
    if (kind == "cross"){
      vars <- character(0)
    } else{
      vars <- on
      message(paste0("Join based on : ", paste(vars, collapse = " ")))
    }

  #  if (!length(setdiff(names(y), vars))) stop("No column in y beyond the one used in the merge")
    if (!(kind== "semi" | kind == "anti")){
      common_names <- setdiff(intersect(names(x),names(y)), vars)
      if (length(intersect(paste0(common_names, suffixes[1]), setdiff(names(x),common_names)))>0) stop(paste("Adding the suffix",suffixes[1],"in", common_names,"would create duplicates names in x"), call. = FALSE)
      if (length(intersect(paste0(common_names, suffixes[2]), setdiff(names(y),common_names)))>0) stop(paste("Adding the suffix",suffixes[2],"in", common_names,"would create duplicates names in y"), call. = FALSE)
      if (length(common_names)>0){
        setnames(xx, common_names, paste0(common_names, suffixes[1]))
        setnames(yy, common_names, paste0(common_names, suffixes[2]))
      }
    }

    # set keys and check duplicates
    key_xx <- key(xx)
    key_yy <- key(yy)
    if (!kind == "cross"){
      setkeyv(xx, vars)
      setkeyv(yy, vars)
    }
    on.exit(setkeyv(xx, key_xx), add = TRUE)
    on.exit(setkeyv(yy, key_yy), add = TRUE)
    
 

    if (kind == "cross"){
          idm <- tempname(c(names(xx),names(yy)))
          xx[, c(idm) := 1L]
          setkeyv(xx, idm)
          yy[, c(idm) := 1L]
          setkeyv(yy, idm)
          DT_output <- xx[yy, allow.cartesian = TRUE]
          DT_output[, c(idm) := NULL]
          return(DT_output[])
    } else {
    if (check[[2]] == 1){
       if (anyDuplicated(xx)){ 
         stop(paste0("Variable(s) ",paste(vars, collapse = " ")," don't uniquely identify observations in x"), call. = FALSE)
       }
     }

    if (check[[3]] == 1){
     if (anyDuplicated(yy)){ 
       stop(paste0("Variable(s) ",paste(vars, collapse = " ")," don't uniquely identify observations in y"), call. = FALSE)
     }
    }
    if (kind %in% c("left", "right", "outer", "inner")){
      if (!gen == FALSE){
        if (gen %chin% names(xx)){
          stop(paste0(gen," alreay exists in master"))
        }
        if (gen %chin% names(yy)){
          stop(paste0(gen," alreay exists in using"))
        }
        idm <- tempname(c(names(xx),names(yy),gen))
        xx[, c(idm) := 1L]
        idu <- tempname(c(names(xx),names(yy),gen,idm))
        yy[, c(idu) := 1L]
      }

      if (inplace){
        lhs = setdiff(names(yy), vars)
        v <- lapply(paste0("i.",lhs), as.name)
        call <- as.call(c(quote(list), v)) 
        call <- substitute(x[yy,(lhs) := v], list(v = call))
        eval(call)
        if (!gen == FALSE){
          x[, c(gen) := 3L]
          eval(substitute(x[is.na(v), c(gen) := 1L], list(v = as.name(idu))))
          x[, c(idu) := NULL]
        }
        DT_output <- x
      } else{
        all.x <- FALSE
        all.y <- FALSE
        if (kind == "left"| kind == "outer"){
          all.x = TRUE
        }
        if (kind == "right" | kind == "outer"){
          all.y = TRUE
        }
        DT_output <- merge(xx, yy, all.x = all.x, all.y= all.y, allow.cartesian= TRUE)
        if (gen != FALSE){
          DT_output[, c(gen) := 3L]
          eval(substitute(DT_output[is.na(v), c(gen) := 1L], list(v = as.name(idu))))
          eval(substitute(DT_output[is.na(v), c(gen) := 2L], list(v = as.name(idm))))
          DT_output[, c(idm) := NULL]
          DT_output[, c(idu) := NULL]
        }
      }
      if (update){
        for (v in common_names){
          newvx <- paste0(v,suffixes[1])
          newvy <- paste0(v,suffixes[2])
          condition <- DT_output[is.na(get(newvx)) & !is.na(get(newvy)), which = TRUE]
          message(paste("Update of", v, ":", length(condition), "row(s) are updated"))
          DT_output[condition, (newvx) := get(newvy)]
          DT_output[, (newvy) := NULL]
        }
        setnames(DT_output, paste0(common_names, suffixes[1]), common_names)
      }
      return(DT_output[])
    } else if (kind == "semi"){
        w <- unique(xx[yy, which = TRUE, allow.cartesian = TRUE])
        w <- w[!is.na(w)]
        DT_output <- xx[w]
        return(DT_output[])
    } else if (kind == "anti"){
        DT_output <- xx[!yy, allow.cartesian = TRUE]
        return(DT_output[])
    }
  }


}

