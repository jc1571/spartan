% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/robustness_utilities.R
\name{oat_countResponsesOfDesiredValue}
\alias{oat_countResponsesOfDesiredValue}
\title{Counts the number of simulation responses where a output response equals a desired result, for a specified parameter.}
\usage{
oat_countResponsesOfDesiredValue(FILEPATH, PARAMETERS, RESULTFILENAME,
  OUTPUTCOLSTART, OUTPUTCOLEND, PARAMETER, NUMRUNSPERSAMPLE, MEASURE,
  DESIREDRESULT, OUTPUTFILENAME, BASELINE, PMIN = NULL, PMAX = NULL,
  PINC = NULL, PARAMVALS = NULL, TIMEPOINTS = NULL,
  TIMEPOINTSCALE = NULL)
}
\arguments{
\item{FILEPATH}{Directory where either the simulation runs or single CSV file result can be found}

\item{PARAMETERS}{Array containing the names of the parameters for which local analyses are being conducted}

\item{RESULTFILENAME}{Name of the simulation results file. In the current version, XML and CSV files can be processed. If performing this analysis over multiple timepoints, it is assumed that the timepoint follows the file name, e.g. trackedCells_Close_12.csv.}

\item{OUTPUTCOLSTART}{Column number in the simulation results file where output begins - saves (a) reading in unnecessary data, and (b) errors where the first column is a label, and therefore could contain duplicates.}

\item{OUTPUTCOLEND}{Column number in the simulation results file where the last output measure is. Only required if running the first method.}

\item{PARAMETER}{Current parameter being analysed in this loop}

\item{NUMRUNSPERSAMPLE}{The number of runs performed for each parameter subset. This figure is generated through Aleatory Analysis}

\item{MEASURE}{Current simulation output measure being analysed in this loop}

\item{DESIREDRESULT}{The specific requirement to match when counting simulation responses}

\item{OUTPUTFILENAME}{CSV file name to contain the counts where simulation responses meet a specific requirement}

\item{BASELINE}{Array containing the values assigned to each of these parameters in the calibrated baseline}

\item{PMIN}{Array containing the minimum value that should be used for each parameter.  Sets a lower bound on sampling space}

\item{PMAX}{Array containing the maximum value that should be used for each parameter.  Sets an upper bound on sampling space}

\item{PINC}{Array containing the minimum value that should be used for each parameter.  Sets a lower bound on sampling space}

\item{PARAMVALS}{Array containing a list of strings for each parameter, each string containing comma separated values that should be assigned to that parameter. Thus sampling can be performed for specific values for each parameter, rather than a uniform incremented value. This replaces the PMIN, PMAX, and PINC where this method is used}

\item{TIMEPOINTS}{Implemented so this method can be used when analysing multiple simulation timepoints. If only analysing one timepoint, this should be set to NULL. If not, this should be an array of timepoints, e.g. c(12,36,48,60)}

\item{TIMEPOINTSCALE}{Implemented so this method can be used when analysing multiple simulation timepoints. Sets the scale of the timepoints being analysed, e.g. "Hours"}
}
\description{
For example, how many simulations produce a value of 0 as the output. Outputs this information as a CSV file.
}
