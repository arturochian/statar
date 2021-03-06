#' @export
spread_.data.table <- function(data, key_col, value_col, fill = NA, convert = FALSE, drop = TRUE ) {
  id <- setdiff(names(data), c(key_col, value_col))
  length_lhs <- length(id)
  if (!length_lhs) {
    id <- tempname("temp", data)
    data <- shallow(data)
    data[, (id) := 1:.N] 
  }
  else if (anyDuplicated(data, by = c(id, key_col))){
        overall <- dplyr::id(data[,c(id, key_col), with = FALSE])
        groups <- split(seq_along(overall), overall)
        groups <- groups[vapply(groups, length, integer(1)) > 1]
        str <- vapply(groups, function(x) paste0("(", paste0(x, collapse = ", "), ")"),
             character(1))
        stop("Duplicate identifiers for rows ", paste(str, collapse = ", "),
             call. = FALSE)
  }
  formula <- as.formula(paste(paste(id, collapse = "+"), paste(key_col, collapse = "+"), sep = "~"))
  data2 <- dcast.data.table(data, formula, value.var = value_col, fill = fill, drop = drop)
  if (!length_lhs) {
    data2[, (id) := NULL]
  }
  if (convert) {
     data2[, names(data2) := lapply(.SD,type.convert, as.is = TRUE), .SDcols = names(data2)]
   }
  data2
}

#' @export
spread_.tbl_dt <- function(data, key_col, value_col, fill = NA,
                           convert = FALSE) {
  dplyr::tbl_dt(NextMethod())
}
