#' Check on key when create cubble from two components (spatial/temporal)
#'
#' When creating a cubble from separate spatial and temporal component,
#' [cubble::make_cubble()] will informed users about potential disagreement
#' of the key values in the two datasets (some sites appear in one table
#' but not the other). This function summarises the key values into those
#'  match, potentially can be matched, and can't be matched.
#'
#' @inheritParams make_cubble
#' @export
#' @return a list with three elements: 1) paired: a tibble of paired ID from
#' spatial and temporal data, 2) potential_pairs: a tibble of pairs that could
#' potentially match from both datasets, 3) others: other key values that can't
#' be matched in a list: others$temporal and others$spatial
#' @examples
#' check_key(stations, meteo)
#'
#' # make_cubble() will prompt to use check_key if there are key mis-match:
#' colnames(lga) <- c("lga", "geometry")
#' cb <- make_cubble(spatial = lga, temporal = covid)
#' (check_res <- check_key(lga, covid))
#' make_cubble(spatial = lga, temporal = covid, potential_match = check_res)
check_key <- function(spatial, temporal, by = NULL) {
  common_cols <- intersect(names(spatial), names(temporal))
  if (!is_null(by)) {
    if (by %in% names(temporal) && names(by) %in% names(spatial)) {
      # rename the common column to have the same name
      names(spatial)[names(spatial) == names(by)] <- by
    }
  } else if (length(common_cols) != 0) {
    # use the first common column
    by <- intersect(names(spatial), names(temporal))[1]
  } else{
    cli::cli_abort("No shared column found.
    Please supply the shared key using the {.code by} argument")
  }

  slvl <- spatial[[by]]
  tlvl <- temporal[[by]]
  matched_tbl <-
    tibble::tibble(spatial = intersect(unique(tlvl), slvl)) |> 
    mutate(temporal = spatial)
  if (nrow(matched_tbl) == 0) {
    matched_tbl <- tibble::tibble()
  }

  only_spatial <- setdiff(slvl, tlvl)
  only_temporal <- setdiff(tlvl, slvl)
  spatial_v <- intersect(spatial[[by]], only_spatial)
  temporal_v <- intersect(temporal[[by]], only_temporal)
  t <- gsub("\\s\\(.+\\)", "", temporal_v)
  s <- gsub("\\s\\(.+\\)", "", spatial_v)
  t_idx <- grep(paste0(s, collapse = "|"), t)
  s_idx <- grep(paste0(t, collapse = "|"), s)


  if (length(t_idx) == 0 | length(s_idx) == 0) {
    others <- list(temporal = temporal_v, spatial = spatial_v)
    potential <-  tibble::tibble()
  } else{
    potential <- tibble::tibble(spatial = sort(spatial_v[s_idx]),
                                temporal = sort(temporal_v[t_idx]))

    others <-
      list(spatial = spatial_v[-s_idx], temporal = temporal_v[-t_idx])
  }

  res <- list(
    paired = matched_tbl,
    potential_pairs = potential,
    others = others
  )

  class(res) <- c("key_tbl", class(res))
  return(res)

}
