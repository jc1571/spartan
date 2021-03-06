#' Summarise results in set folder structure into one single CSV file
#'
#' Only to be applied in cases where simulation responses are supplied in the
#' folder structure (as in all previous versions of Spartan), useful for cases
#' where the simulation is non-deterministic. Iterates through simulation runs
#' for each sample size creating a CSV file containing results for all sample
#' sizes and all subsets (in the same format as the new CSV file format
#' discussed above). Where a simulation response is comprised of a number of
#' records (for example a number of cells), the median value will be recorded
#' as the response for this subset of the sample size being analysed. This file
#' is output to a CSV file, named as stated by the parameter
#' SUMMARYFILENAME. If doing this analysis over multiple timepoints, the
#' timepoint will be appended to the filename given in SUMMARYFILENAME
#'
#' @param FILEPATH Directory where the results of the simulation runs, in folders or in single CSV file format, can be found
#' @param SAMPLESIZES The sample sizes chosen (i.e. in our case, this would be an array containing 1,5,50,100,300,800
#' @param MEASURES An array containing the names of the simulation output measures to be analysed.
#' @param RESULTFILENAME Name of the simulation results file. In the current version, XML and CSV files can be processed. If performing this analysis over multiple timepoints, it is assumed that the timepoint follows the file name, e.g. trackedCells_Close_12.csv.
#' @param ALTFILENAME In some cases, it may be relevant to read from a further results file if the initial file contains no results. This filename is set here. In the current version, XML and CSV files can be processed.
#' @param OUTPUTFILECOLSTART Column number in the simulation results file where output begins - saves (a) reading in unnecessary data, and (b) errors where the first column is a label, and therefore could contain duplicates.
#' @param OUTPUTFILECOLEND Column number in the simulation results file where the last output measure is.
#' @param SUMMARYFILENAME Name of the file generated that lists the maximum and median A-Test results for each sample size.
#' @param TIMEPOINTS Implemented so this method can be used when analysing multiple simulation timepoints. If only analysing one timepoint, this should be set to NULL. If not, this should be an array of timepoints, e.g. c(12,36,48,60)
#' @param TIMEPOINTSCALE Implemented so this method can be used when analysing multiple simulation timepoints. Sets the scale of the timepoints being analysed, e.g. "Hours"
#'
#' @export
aa_summariseReplicateRuns <- function(FILEPATH, SAMPLESIZES, MEASURES,
                                      RESULTFILENAME, ALTFILENAME,
                                      OUTPUTFILECOLSTART, OUTPUTFILECOLEND,
                                      SUMMARYFILENAME, TIMEPOINTS = NULL,
                                      TIMEPOINTSCALE = NULL) {
  if (is.null(TIMEPOINTS)) {
    SAMPLE_SIZE_RESULTS <- NULL

    for (SAMPLESIZE in 1:length(SAMPLESIZES)) {
      for (SET in 1:20) {
        print(join_strings_space(c("Processing Sample Size ",
                                   SAMPLESIZES[SAMPLESIZE], " Set ", SET)))

        SAMPLE_FILEPATH <- make_path(c(FILEPATH, SAMPLESIZES[SAMPLESIZE], SET))

        MEDIANS <- data.frame(getMediansSubset(SAMPLE_FILEPATH,
                                               SAMPLESIZES[SAMPLESIZE],
                                               MEASURES, RESULTFILENAME,
                                               ALTFILENAME,
                                               OUTPUTFILECOLSTART,
                                               OUTPUTFILECOLEND))

        # Add on the sample size and set this was generated from
        MEDIANS <- cbind(
          rep(SAMPLESIZES[SAMPLESIZE], nrow(MEDIANS)),
          rep(SET,nrow(MEDIANS)),
          MEDIANS)

          SAMPLE_SIZE_RESULTS <- rbind(SAMPLE_SIZE_RESULTS, MEDIANS)
      }
    }


    colnames(SAMPLE_SIZE_RESULTS) <- c("SampleSize", "Set", MEASURES)

    RESULTSFILE <- make_path(c(FILEPATH, SUMMARYFILENAME))
    print(join_strings_space(c("Writing Median Results to CSV File:",
                             RESULTSFILE)))
    write.csv(SAMPLE_SIZE_RESULTS, RESULTSFILE,
              quote = FALSE, row.names = FALSE)

    } else {
    for (n in 1:length(TIMEPOINTS)) {
      current_time <- TIMEPOINTS[n]
      print(join_strings_space(c("PROCESSING TIMEPOINT:", current_time)))

      resultfileformat <- check_file_extension(RESULTFILENAME)
      SIMRESULTFILENAME <- paste(substr(RESULTFILENAME, 0,
                                        nchar(RESULTFILENAME) - 4),
                                 "_", current_time, ".", resultfileformat,
                                 sep = "")

      if (!is.null(ALTFILENAME)) {
        ALTFILENAMEFULL <- paste(substr(ALTFILENAME, 0,
                                        nchar(ALTFILENAME) - 4),
                                 "_", current_time, ".",
                                 resultfileformat, sep = "")
      } else {
        ALTFILENAMEFULL <- ALTFILENAME
      }

      summaryfileformat <- check_file_extension(SUMMARYFILENAME)
      SUMMARYFILENAME_FULL <- paste(substr(SUMMARYFILENAME, 0,
                                         nchar(SUMMARYFILENAME) - 4),
                                  "_", current_time, ".",
                                  summaryfileformat, sep = "")


      aa_summariseReplicateRuns(FILEPATH, SAMPLESIZES, MEASURES,
                                SIMRESULTFILENAME, ALTFILENAMEFULL,
                                OUTPUTFILECOLSTART, OUTPUTFILECOLEND,
                                SUMMARYFILENAME_FULL,
                                TIMEPOINTS = NULL, TIMEPOINTSCALE = NULL)

    }
  }
}

#' Calculates the A-Test scores observed for all sets, for each sample size
#'
#' Examines the summary CSV file produced either by the method
#' \code{aa_summariseReplicateRuns} or provided by the user, analysing each
#' sample size independently, to determine how 'different' the results of
#' each of the subsets are. For each sampple size, the distribution of
#' responses for each subset are compared with the first subset using the
#' Vargha-Delaney A-Test. These scores are stored in a CSV file, with
#' filename as stated in parameter ATESTRESULTSFILENAME. The A-Test results
#' for a sample size are then graphed, showing how different each of the
#' subsets are. If doing this analysis over multiple timepoints, the
#' timepoint will be appended to the filename given in
#' ATESTRESULTSFILENAME and appended to the name of the graph.
#'
#' @inheritParams aa_summariseReplicateRuns
#' @param NUMSUBSETSPERSAMPLESIZE The number of subsets for each sample size (i.e in the tutorial case, 20)
#' @param AA_SIM_RESULTS Either - A: The name of the summary CSV file to be created by aa_summariseReplicateRuns or B: The name of the provided CSV file that summarises the results of all runs for this analysis.
#' @param ATESTRESULTSFILENAME Name of the file that will contain the A-Test scores for each sample size
#' @param LARGEDIFFINDICATOR The A-Test determines there is a large difference between two sets if the result is greater than 0.2 either side of the 0.5 line.  Should this not be suitable, this can be changed here
#' @param GRAPHNAME Used internally by the getATestResults method when producing graphs for multiple timepoints. Should not be set in function call.
#'
#' @export
#'
#' @importFrom utils read.csv write.csv
aa_getATestResults <- function(FILEPATH, SAMPLESIZES, NUMSUBSETSPERSAMPLESIZE,
                               MEASURES, AA_SIM_RESULTS, ATESTRESULTSFILENAME,
                               LARGEDIFFINDICATOR, TIMEPOINTS = NULL,
                               TIMEPOINTSCALE = NULL, GRAPHNAME = NULL) {

  if (is.null(TIMEPOINTS)) {
    # ALL A-TEST SCORES, FOR ALL SAMPLE SIZES
    RESULTS <- NULL

    # ATEST SCORES FOR JUST A SAMPLE SIZE - COMPILED FOR GRAPHING
    SIZE_RESULTS <- NULL

    # READ IN THE SUMMARY FILE
    RESULT <- read.csv(make_path(c(FILEPATH, AA_SIM_RESULTS)),
                       sep = ",", header = TRUE, check.names = FALSE)
    print("Generating A-Test Scores for Consistency Analysis")

    # GENERATE COLUMN HEADINGS - WE USE THIS TWICE LATER
    ATESTRESULTSHEADER <- cbind("Sample Size", "Sample")

    for (l in 1:length(MEASURES)) {
      ATESTRESULTSHEADER <- cbind(ATESTRESULTSHEADER,
                                  paste("ATest", MEASURES[l], sep = ""),
                                  paste("ATest", MEASURES[l], "Norm",
                                        sep = ""))
    }

    for (s in 1:length(SAMPLESIZES)) {
      print(join_strings_space(c("Processing Sample Size:", SAMPLESIZES[s])))

      ## GET THE FIRST SET, SO THIS CAN BE COMPARED WITH ALL THE OTHERS
      ## SO SUBSET THE RESULTS
      SUBSET_CRITERIA <- c("SampleSize", "Set")
      SET1 <- subset_results_by_param_value_set(SUBSET_CRITERIA, RESULT,
                                                c(SAMPLESIZES[s], 1))

      # RESET THE SCORES FOR EACH SAMPLE SIZE
      SIZE_RESULTS <- NULL

      for (m in 2:NUMSUBSETSPERSAMPLESIZE) {

        ALLATESTRESULTS <- cbind(SAMPLESIZES[s], m)

        COMPAREDSET <- subset_results_by_param_value_set(SUBSET_CRITERIA,
                                                         RESULT,
                                                         c(SAMPLESIZES[s], m))

        if (nrow(COMPAREDSET) > 0) {
          # Now perform the analysis for each measure
          # THEN NORMALISE (PUT ABOVE 0.5) AS DIRECTION DOES NOT MATTER
          for (l in 1:length(MEASURES)) {
            ATESTMEASURERESULT <- atest(as.numeric
                                        (as.matrix(SET1[MEASURES[l]][, 1])),
                                      as.numeric(
                                        as.matrix(COMPAREDSET[MEASURES[l]][, 1]
                                                  )))
            # the [,1] is added so the data is extracted
            ATESTMEASURENORM <- normaliseATest(ATESTMEASURERESULT)
            ALLATESTRESULTS <- cbind(ALLATESTRESULTS, ATESTMEASURERESULT,
                                     ATESTMEASURENORM)

          }
        } else {
          for (l in 1:length(MEASURES)) {
            ALLATESTRESULTS <- cbind(ALLATESTRESULTS, 1, 1)
          }
        }
        # ADD THESE TESTS TO THE RESULTS
        RESULTS <- rbind(RESULTS, ALLATESTRESULTS)

        SIZE_RESULTS <- rbind(SIZE_RESULTS, ALLATESTRESULTS)
      }

      colnames(SIZE_RESULTS) <- ATESTRESULTSHEADER

      # NOW GRAPH THIS SAMPLE SIZE
      if (is.null(GRAPHNAME))
        GRAPHOUTPUTNAME <- join_strings_nospace(c(SAMPLESIZES[s],
                                                  "Samples.pdf"))
      else
        GRAPHOUTPUTNAME <- join_strings_nospace(c(SAMPLESIZES[s],
                                                  "Samples_", GRAPHNAME,
                                                  ".pdf"))

      aa_graphATestsForSampleSize(FILEPATH, SIZE_RESULTS, MEASURES,
                                  LARGEDIFFINDICATOR,
                                  GRAPHOUTPUTNAME, NULL, NULL)

      print(join_strings_space(c("Summary Graph for Sample Size of",
                                 SAMPLESIZES[s], "Saved to", FILEPATH, "/",
                                 GRAPHOUTPUTNAME)))
    }

    colnames(RESULTS) <- c(ATESTRESULTSHEADER)

    # NOW WRITE THE FILE OUT
    write.csv(RESULTS, make_path(c(FILEPATH, ATESTRESULTSFILENAME)),
              quote = FALSE, row.names = FALSE)

  } else {
    # PROCESS EACH TIMEPOINT, AMENDING FILENAMES AND RECALLING THIS FUNCTION
    for (n in 1:length(TIMEPOINTS)) {
      current_time <- TIMEPOINTS[n]
      print(join_strings_space(c("PROCESSING TIMEPOINT:", current_time)))

      aa_sim_results_format <- check_file_extension(AA_SIM_RESULTS)
      AA_SIM_RESULTS_FULL <- paste(substr(AA_SIM_RESULTS, 0,
                                          nchar(AA_SIM_RESULTS) - 4),
                                   "_", current_time, ".",
                                   aa_sim_results_format, sep = "")

      atest_results_format <- check_file_extension(ATESTRESULTSFILENAME)
      ATESTRESULTSFILENAME_FULL <- paste(substr
                                         (ATESTRESULTSFILENAME, 0,
                                           nchar(ATESTRESULTSFILENAME) - 4),
                                         "_", current_time, ".",
                                         atest_results_format, sep = "")

      GRAPHOUTPUTNAME < -current_time

      aa_getATestResults(FILEPATH, SAMPLESIZES, NUMSUBSETSPERSAMPLESIZE,
                         MEASURES, AA_SIM_RESULTS_FULL,
                         ATESTRESULTSFILENAME_FULL, LARGEDIFFINDICATOR,
                         TIMEPOINTS = NULL, TIMEPOINTSCALE = NULL,
                         GRAPHOUTPUTNAME)
    }
  }
}


#' Determines the median and maximum A-Test score observed for each sample size
#'
#' This takes each sample size to be examined in turn, and iterates through all
#' the subsets, determining the median and maximum A-Test score observed for
#' each sample size. A CSV file is created summarising the median and maximum
#' A-Test scores for all sample sizes, named as stated in parameter
#' SUMMARYFILENAME. If doing this analysis over multiple timepoints, the
#' timepoint will be appended to the filename given in SUMMARYFILENAME.
#'
#' @inheritParams aa_summariseReplicateRuns
#' @inheritParams aa_getATestResults
#'
#' @export
aa_sampleSizeSummary <- function(FILEPATH, SAMPLESIZES, MEASURES,
                                 ATESTRESULTSFILENAME, SUMMARYFILENAME,
                                 TIMEPOINTS = NULL, TIMEPOINTSCALE = NULL) {
  if (is.null(TIMEPOINTS)) {
    ATESTMAXES <- NULL

    print("Producing Analysis Summary (aa_sampleSizeSummary)")

    if (file.exists(make_path(c(FILEPATH, ATESTRESULTSFILENAME)))) {

      ALLSUBSET_ATEST_SCORES <- read.csv(make_path(c(FILEPATH,
                                                     ATESTRESULTSFILENAME)),
                                         header = TRUE, check.names = FALSE)

      for (k in 1:length(SAMPLESIZES)) {
        SAMPLEPROCESSING <- SAMPLESIZES[k]
        print(join_strings_space(c("Processing Sample Size:",
                                   SAMPLEPROCESSING)))

        # SUBSET THE RESULTS ON THE SAMPLE SIZE
        SAMPLE_SIZE_RESULT <- subset(ALLSUBSET_ATEST_SCORES,
                                     ALLSUBSET_ATEST_SCORES[["Sample Size"]] ==
                                       as.numeric(SAMPLEPROCESSING))

        # NOW WORK OUT MAX AND MEDIAN A-TEST RESULTS FOR EACH SAMPLE SIZE
        SAMPLE_SIZE_SUMMARY <- c(SAMPLEPROCESSING)

        for (MEASURE in 1:length(MEASURES)) {
          MEASURELABEL <- join_strings_nospace(c("ATest",
                                                 MEASURES[MEASURE], "Norm"))
          MEDIANATESTMEASUREVAL <- median(
            SAMPLE_SIZE_RESULT[MEASURELABEL][, 1])
          MAXATESTMEASUREVAL <- max(SAMPLE_SIZE_RESULT[MEASURELABEL][, 1])
          SAMPLE_SIZE_SUMMARY <- cbind(SAMPLE_SIZE_SUMMARY, MAXATESTMEASUREVAL,
                                       MEDIANATESTMEASUREVAL)
        }

        ATESTMAXES <- rbind(ATESTMAXES, SAMPLE_SIZE_SUMMARY)
      }

      # NOW OUTPUT THE RESULTS
      # GENERATE COL HEADER FOR THE OUTPUT FILE
      OUTPUTCOLHEADS <- c("samplesize")

      for (l in 1:length(MEASURES)) {
        OUTPUTCOLHEADS <- cbind(OUTPUTCOLHEADS, paste(MEASURES[l],
                                                      "MaxA", sep = ""),
                                paste(MEASURES[l], "MedianA", sep = ""))
      }

      colnames(ATESTMAXES) <- c(OUTPUTCOLHEADS)

      # NOW OUTPUT THESE FOR GRAPHING LATER
      # SUMMARY FILENAME SOMETHING LIKE ATESTMAXANDMEDIANS.CSV FOR ONE TIMEPOINT
      RESULTFILE <- make_path(c(FILEPATH, SUMMARYFILENAME))
      # WRITE OUT SO HAVE THE TABLE IF NECESSARY LATER
      write.csv(ATESTMAXES, RESULTFILE, quote = FALSE, row.names = FALSE)

      print(join_strings(c("Summary file of all A-Test results output to ",
                           FILEPATH, SUMMARYFILENAME), ""))

    } else {
      print("Error: Cannot find the A-Test Results file. Check your FILEPATH
            and SAMPLESIZES parameters")
    }
  } else {

    for (n in 1:length(TIMEPOINTS)) {

      current_time <- TIMEPOINTS[n]
      print(join_strings(c("PROCESSING TIMEPOINT:", current_time), " "))

      atest_results_format <- check_file_extension(ATESTRESULTSFILENAME)
      ATESTRESULTSFILENAME_FULL <- paste(substr(ATESTRESULTSFILENAME, 0,
                                              nchar(ATESTRESULTSFILENAME) - 4),
                                       "_", current_time, ".",
                                       atest_results_format, sep = "")

      summaryfile_format <- check_file_extension(SUMMARYFILENAME)
      SUMMARYFILENAME_FULL <- paste(substr(SUMMARYFILENAME, 0,
                                         nchar(SUMMARYFILENAME) - 4),
                                  "_", current_time, ".", summaryfile_format,
                                  sep = "")

      aa_sampleSizeSummary(FILEPATH, SAMPLESIZES, MEASURES,
                           ATESTRESULTSFILENAME_FULL, SUMMARYFILENAME_FULL,
                           TIMEPOINTS = NULL, TIMEPOINTSCALE = NULL)

    }
  }
}
