library(grid)
library(gridGeometry)


rfdRed <- "#CC4627"
rfdYellow<- "#F29D38"
rfdGreen <- "#449331"


deg2rad <- function(degrees) {

  radians<-degrees * (2 * pi)/360
  return(radians)
}

rad2deg <- function(radians) {
  degrees <- radians * 360 / (2 * pi)
  return(deg)
}

circleFunction <- function(degrees, radius, origin) {
  # assumes an origin at (.5, .5), changes coordinate system so theta goes from l to r

  if(missing(origin)) {
    origin <- 180
  }

  degrees <- origin - degrees

  radians <- deg2rad(degrees)

  rx<- radius * cos(radians) + .5
  ry<- radius * sin(radians) + .5

  returns <- list("x" = rx, "y" = ry )
  return(returns)
}

gg_gauge_relativePct<-function(value, gMin, gMax) {
  if(value < gMin) {
    relativePct <- 0
  } else if(value > gMax) {
    relativePct <- 1
  } else {
    drange <- gMax - gMin
    pos <- value - gMin
    relativePct <- pos / drange
  }
  return(relativePct)
}

#' Half Gauge Function
#'
#' This function returns a grid gTree representing a half-gauge.
#' @param value Value to be shown on the gauge
#' @param gMin  Minimum value of the gauge
#' @param gMax  Maximum value of the gauge
#' @param breaks Breaks for color areas
#' @param gColors Colors for each break
#' @param gName Name for the gauge (optional)
#' @export
#' @examples
#' gg_gauge_half(1, 0, 2, breaks=c(1), gColors=c("green", "red"))
gg_gauge_half <- function(value, gMin, gMax, breaks, gColors, gName) {

  if(max(breaks) > gMax || min(breaks) < gMin) {
    stop("Error: breaks are outside range of gauge")
  }

  # parameterize the value and breaks to "polar"

  degreeValue <- gg_gauge_relativePct(value, gMin, gMax) * 180
  degreeBreaks <- lapply(breaks, gg_gauge_relativePct, gMin=gMin, gMax=gMax)
  degreeBreaks <- lapply(degreeBreaks, function(x) x * 180)
  degreeBreaks<-unlist(degreeBreaks)

  gaugeAreaTree<-gTree()

  if(min(degreeBreaks) != 0){
    degreeBreaks <- c(0, degreeBreaks)
  }
  if(max(degreeBreaks) != 180) {
    degreeBreaks <- c(degreeBreaks, 180)
  }
  # draw the different ranges out here, extended all the way to the outside
  # of the bounding box, then clip gaugeBack against that.

  # make clipping mask
  ox<-circleGrob(x=0.5, y=0.5, r=0.5)
  ix<-circleGrob(x=0.5, y=0.5, r=0.3)
  gaugeBack <- polyclipGrob(ox,ix, op="minus", gp=gpar(lwd=5, fill="purple"))

  clipper <- rectGrob(x=.5, y=.25, width = 1, height=.5)

  gaugeBackClipper <- polyclipGrob(gaugeBack, clipper, op="minus", gp=gpar(lwd=5))

  # draw the regions

  for(i in 1:length(degreeBreaks)) {

    if(i==length(degreeBreaks)) break

    angles<-seq(degreeBreaks[i], degreeBreaks[i+1], by=0.1)
    circlePoints<-circleFunction(angles, .5)
    circlePoints$x <- c(circlePoints$x, .5)
    circlePoints$y <- c(circlePoints$y, .5)

    arcSegment<-polygonGrob(circlePoints$x, circlePoints$y, gp=gpar(fill=gColors[i]))

    arcSegment<-polyclipGrob(gaugeBackClipper, arcSegment, gp=gpar(fill=gColors[i]))


    gaugeAreaTree<-addGrob(gaugeAreaTree, arcSegment)

  }

  #grid.draw(gaugeAreaTree)

  ######################
  gauge <- gTree()
  gauge <- addGrob(gauge, gaugeAreaTree)
  # draw the needle
  needleEnd <- circleFunction(degreeValue, 0.5)

  needle<-linesGrob(x=c(.5, needleEnd$x), y=c(.5, needleEnd$y), arrow=arrow(angle=30, ends="last"), gp=gpar(lwd=5))
  gauge<-addGrob(gauge, needle)
  # draw the value

  valueText<-textGrob(value, x=0.5, y=0.4, gp=gpar(fontsize=48))
  gauge<-addGrob(gauge, valueText)

  if(!missing(gName)) {

    nameText<-textGrob(gName, x=0.5, y=0.65,gp=gpar(fontsize=18))
    gauge<-addGrob(gauge, nameText)
  }

  return(gauge)


}

#' Dial Gauge Function
#'
#' This function returns a grid gTree representing a hdial gauge.
#' @param value Value to be shown on the gauge
#' @param gMin  Minimum value of the gauge
#' @param gMax  Maximum value of the gauge
#' @param breaks Breaks for color areas
#' @param gColors Colors for each break
#' @param gName Name for the gauge (optional)
#' @param nMajorTicks Number of major ticks (optional)
#' @param nMinorTicks Number of minor ticks (optional - ideally should be a multiple of nMajorTicks)
#' @export
#' @examples
#' gg_gauge_dial(1, 0, 2, breaks=c(1), gColors=c("green", "red"))
#'
#'
gg_gauge_dial <- function(value, gMin, gMax, breaks, gColors, gName, nMajorTicks, nMinorTicks) {

  if(max(breaks) > gMax || min(breaks) < gMin) {
    stop("Error: breaks are outside range of gauge")
  }
  # parameterize the value and breaks to "polar"

  degreeValue <- gg_gauge_relativePct(value, gMin, gMax) * 270
  degreeBreaks <- lapply(breaks, gg_gauge_relativePct, gMin=gMin, gMax=gMax)
  degreeBreaks <- lapply(degreeBreaks, function(x) x * 270)
  degreeBreaks<-unlist(degreeBreaks)

  gaugeAreaTree<-gTree()

  if(min(degreeBreaks) != 0){
    degreeBreaks <- c(0, degreeBreaks)
  }
  if(max(degreeBreaks) != 270) {
    degreeBreaks <- c(degreeBreaks, 270)
  }
  # draw the different ranges out here, extended all the way to the outside
  # of the bounding box, then clip gaugeBack against that.

  # make dial clipping mask
  ox<-circleGrob(x=0.5, y=0.5, r=0.5)
  ix<-circleGrob(x=0.5, y=0.5, r=0.3)
  gaugeBack <- polyclipGrob(ox,ix, op="minus", gp=gpar(lwd=5, fill="purple"))

  dialClip <- circleFunction(seq(0, 270, by=0.1), .5, origin=225)
  dialClip <- polygonGrob(dialClip$x, dialClip$y)

  gaugeBackClipper <- polyclipGrob(gaugeBack, dialClip, op="intersection", gp=gpar(lwd=5))


  # draw the regions

  for(i in 1:length(degreeBreaks)) {
    if(i==length(degreeBreaks)) break

    angles<-seq(degreeBreaks[i], degreeBreaks[i+1], by=0.1)
    circlePoints<-circleFunction(angles, .5, origin=225)
    circlePoints$x <- c(circlePoints$x, .5)
    circlePoints$y <- c(circlePoints$y, .5)

    arcSegment<-polygonGrob(circlePoints$x, circlePoints$y, gp=gpar(fill=gColors[i]))



    arcSegment<-polyclipGrob(gaugeBackClipper, arcSegment, gp=gpar(fill=gColors[i]))

    gaugeAreaTree<-addGrob(gaugeAreaTree, arcSegment)

  }

  #grid.draw(gaugeAreaTree)

  gauge <- gTree()
  gauge <- addGrob(gauge, gaugeAreaTree)
  # draw the needle
  needleEnd <- circleFunction(degreeValue, 0.5, origin=225)

  needle<-linesGrob(x=c(.5, needleEnd$x), y=c(.5, needleEnd$y), arrow=arrow(angle=30, ends="last"), gp=gpar(lwd=5))
  gauge<-addGrob(gauge, needle)
  # draw the value

  valueText<-textGrob(value, x=0.5, y=0.2, gp=gpar(fontsize=48))
  gauge<-addGrob(gauge, valueText)

  # draw the data point name
  if(!missing(gName)) {

    nameText<-textGrob(gName, x=0.5, y=0.65,gp=gpar(fontsize=18))
    gauge<-addGrob(gauge, nameText)
  }

  # draw some rad tick marks
  # thinking here draw a line from O to the point on the outer circle, then trimgrob
  # from -0.05 to -0.15

  # major ticks
  if(!missing(nMajorTicks)) {
    for(tick in 0:nMajorTicks) {
      tickEnd <- circleFunction(tick * (270 / nMajorTicks), 0.5, origin=225)
      tick<-linesGrob(x=c(.5, tickEnd$x), y=c(.5, tickEnd$y), gp=gpar(lwd=5))
      tick<-trimGrob(tick, from=-0.01, to=-0.18,gp=gpar(lwd=3))
      gauge<-addGrob(gauge, tick)
    }
  }

  # major ticks
  if(!missing(nMinorTicks)) {
    for(tick in 0:nMinorTicks) {
      tickEnd <- circleFunction(tick * (270 / nMinorTicks), 0.5, origin=225)
      tick<-linesGrob(x=c(.5, tickEnd$x), y=c(.5, tickEnd$y), gp=gpar(lwd=5))
      tick<-trimGrob(tick, from=-0.01, to=-0.10,gp=gpar(lwd=1))
      gauge<-addGrob(gauge, tick)
    }
  }
  return(gauge)
}

