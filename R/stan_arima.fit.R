# Part of the rstanarm package for estimating model parameters
# Copyright (C) 2013, 2014, 2015, 2016, 2017 Trustees of Columbia University
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#' Workhorse function for Bayesian ARIMA modeling of time series
#' @export
#' @param x,order,seasonal,xreg,include.mean Same as \code{\link[stats]{arima}}.

stan_arima.fit <- function(yy,
                           x,
                           X,
                           order,
                           ...,
                           has_intercept,
                           time_periods,
                           p,
                           q,
                           prior,
                           prior_intercept,
                           # prior_PD,
                           algorithm,
                           adapt_delta
                           # QR = QR
                           ) {
  
  # needed since we don't pass the white-noise matrix into Stan
  if (p > 0) 
    K <- p
  else
    K <- 1
  
  standata <- list(T = time_periods - p,
                   lb = min(yy),
                   ub = max(yy),
                   yy = yy,
                   X = X,
                   K = K,
                   p = p,  # number of AR lags
                   q = q,  # number of MA lags
                   delta_AR = 1,
                   delta_MA = 1,
                   has_intercept = has_intercept)
  prior <- NULL
  pars <- c(if (has_intercept) "mu",
            "phi", 
            "theta", 
            "sigma")
  stanfit <- stanmodels$arima
  
  if (algorithm == "sampling") {
    sampling_args <- set_sampling_args(
      object = stanfit, 
      prior = prior, 
      user_dots = list(...), 
      user_adapt_delta = adapt_delta, 
      data = standata, 
      pars = pars, 
      show_messages = FALSE)
    stanfit <- do.call(sampling, sampling_args)
  }
  else {
    stop("Only algorithm == 'sampling' is supported.")
  }
  new_names <- c(if (has_intercept) "(Intercept)",
                 if (p >= 1) paste0("ar", 1:p), 
                 if (q >= 1) paste0("ma", 1:q),
                 "sigma",
                 "log-posterior")
  stanfit@sim$fnames_oi <- new_names
  # return(structure(stanfit, prior.info = prior_info))
  return(stanfit)
}
