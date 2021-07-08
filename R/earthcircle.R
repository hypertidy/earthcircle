.prj <- function(z, proj.out, ..., proj.in = NULL) {
  if (is.null(proj.in)) {
    #message("assuming WGS84 for unprojected angular coordinates")
    proj.in <- "OGC:CRS84"
  }
  dat <- matrix(z, ncol = 2)
  ## NAs come out *zero* aargh
  bad <- is.na(dat[,1L]) | is.na(dat[,2L])

  capture.output(out <- PROJ::proj_trans(dat, proj.out, source = proj.in))
  out <- do.call(cbind, out)
  if (any(bad)) out[bad, ] <- NA
  out
}

#' Ellipse
#'
#' @param center center
#' @param axes axes
#' @param scale scale
#' @param n n
#' @param from from
#' @param to to
#'
#' @return matrix
#' @author Bill Huber
#' @noRd
#' @examples
#' base <- .ellipse()
.ellipse <- function(center = c(0.5, 0.5), axes = matrix(c(0.5,0,0,0.5), 2), scale=1, n=36, from=0, to=2*pi) {
  # Vector representation of an ellipse at "center" with axes in the *rows* of "axes".
  # Returns an "n" by 2 array of points, one per row.
  theta <- seq(from=from, to=to, length.out=n)
  t((scale * t(axes))  %*% rbind(cos(theta), sin(theta)) + center)
}

local_proj <- function(lonlat) {
  sprintf("+proj=laea +lon_0=%f +lat_0=%f +datum=WGS84", lonlat[1], lonlat[2])
}

#' Generate coordinates of an "earth" circle.
#'
#' A circle on the ground for every input longitude,latitude.
#'
#' @param x longitude of central location for circle, or lon,lat together in matrix, data frame, or list
#' @param y latitude of location (ignored if 'x' includes y)
#' @param scale the scale of the circle, large enough default to see on world maps
#' @param ... ignored currently
#' @param n the number of coordinates to provide each circle
#' @param from the minimum radial angle (default 0)
#' @param to the maximum radial angle
#'
#' @return matrix of circle coordinates (separated by NA rows)
#' @export
#'
#' @examples
#' x <- earthcircle(cbind(c(0, -50), c(0, -90)), scale = 1e6, from = 0, to = pi)
#' plot(earthcircle:::.prj(x, "+proj=laea +lat_0=-90"), asp = 1, type = "l")
earthcircle <- function(x, y = NULL, scale = 3 * 1852 * 60, ..., n = 36, from=0, to=2*pi) {
  if (is.null(y) && is.numeric(x) && length(x) == 2L) x <- matrix(x, ncol = 2L)
  xt <- do.call(rbind, xy.coords(x, y, recycle = TRUE)[1:2])

  aa <- do.call(rbind, lapply(split(xt, rep(seq_len(dim(xt)[2L]), each = 2L)), function(pt) {
    rbind(.prj(.ellipse(pt, scale = scale, n = n, from = from, to = to), proj.in = local_proj(pt), proj.out = "OGC:CRS84"), NA)
  }))
  aa[-dim(aa)[1], ]
}

