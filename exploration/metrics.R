#' Evaluation metrics
#' From:
#' 
#' Coady, David, Margaret E. Grosh, and John Hoddinott. Targeting of transfers in developing countries: Review of lessons and experience. Vol. 1. World Bank Publications, 2004.
#'
#'
#' Vocabulary:
#' FP = False positive
#' FN = False negative
#' TP = True positive
#' FN = False negative
#' Positive = Guessed poor
#' B = Beneficiary.
#' TP+FP=B
#' TP+FN = True poor
#' @export


DEFAULT_THRESHOLDS <- seq(0.1, 0.9, by=0.1)


table_metric_ <- function(METRIC, joined, THRESHOLDS=DEFAULT_THRESHOLDS) {
  joined <- dplyr::filter(joined, method != "true")
  grouped <- dplyr::group_by(joined, method)
  df <- dplyr::do(grouped, metric=METRIC(., THRESHOLDS))
  bound <- data.frame(do.call("rbind", df$metric))
  bound$method <- df$method
  bound
}


plot_metric_ <- function(METRIC, joined, THRESHOLDS=DEFAULT_THRESHOLDS) {
  metric_df <- data.frame(table_metric_(METRIC, joined, THRESHOLDS))
  melted <- reshape2::melt(metric_df, variable.name="quantile", id="method")
  ggplot2::ggplot(melted, ggplot2::aes(x=quantile, y=value, color=method)) + 
    ggplot2::geom_point()
}

plot_metric <- function(METRIC, ..., THRESHOLDS=DEFAULT_THRESHOLDS) {
  dfs <- list(dfs)
  joined <- join_dfs(dfs)
  plot_metric_(joined)
}

#' FP / B
leakage <- function(df, THRESHOLDS=DEFAULT_THRESHOLDS) {
  quantiles <- quantile(df$raw, THRESHOLDS)
  mapply(function(consumption_threshold, df) {
    b <- filter(df, predicted < consumption_threshold)
    sum(b$raw > consumption_threshold) / nrow(b)},
  quantiles,
  list(df)
  )
}

#' FN / (TP + FN)
undercoverage <- function(df, THRESHOLDS=DEFAULT_THRESHOLDS) {
  quantiles <- quantile(df$raw, THRESHOLDS)
  mapply(function(consumption_threshold, df) {
    true_poor <- filter(df, raw < consumption_threshold)
    sum(true_poor$predicted > consumption_threshold) / nrow(true_poor)},
  quantiles,
  list(df)
  )
}

#' % BUGDGET TO QUANTILE / QUANTILE
cgh <- function(df, THRESHOLDS=DEFAULT_THRESHOLDS) {
  quantiles <- quantile(df$raw, THRESHOLDS)
  budget_percents <- mapply(function(consumption_threshold, df) {
    b <- filter(df, predicted < consumption_threshold)
    sum(b$raw < consumption_threshold) / nrow(b)},
  quantiles,
  list(df)
  )
  budget_percents / THRESHOLDS
}

perfect_cgh <- function(thresholds) {
  1. / thresholds
}

ncgh <- function(df, THRESHOLDS=DEFAULT_THRESHOLDS) {
  cgh(df, THRESHOLDS) / perfect_cgh(THRESHOLDS)
}
