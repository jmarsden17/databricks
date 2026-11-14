# TFL Cycling data project - Databricks Fundamentals

## CSVs
These files contain TFL cycling data.
- 01-15 Jan 2026
- 15-31 Jan 2026
- 01-14 Feb 2026
- 14-28 Feb 2026
- 01-15 Mar 2026
- 15-31 Mar 2026

## Data Issues
The data is mostly good, but on the upper bound of hire time some periods run into the days and weeks, with the longest period being 49 days. 

Not only is this an obvious outlier that seems hard to believe is real, the end date for this ride ends in April, long after the end of this data set.

Columns are named vaguely.


## Cleaning Rules
- Removed journeys with a duration of less than one second (Removed 6).
- Removed all journeys with hire times of over twenty four hours (Removed 841).
- Dropped all duplicate rows (Removed 0).

## Sanjay's Questions

What data quality problems did you find, and how did you handle each one?

The data was mostly to a high quality, however there were some issues around column names not being to the level of detail I liked. For example 'number', which I changed to 'rental_id'. I also changed start and end station 'number' to 'id' to fit the naming style, as well as start and date 'date' to 'timestamp'. Finally, I added 'name' to the end of start and end station to improve the level of detail in column names.

The data was also all in string format due to the CSV files, so I swapped datatypes to timestamps and integers where appropriate.

How many rows did you drop or fix at each stage, and why?

In the silver phase I dropped 6 rows that had less then 1 second of hire time, and 841 rows that had a journey time over 24 hours. These were arbritary cut off points I chose as they seemed like obvious outliers, however you could change these values as data I kept in could be considered outliers still.

I also checked for any duplicate rows but this did not return any rows.

What would need to change to load next month's files?

The filepaths in the bronze read would need to be changed for the next data set, as I set these manually. The rest of the pipeline however is just set to read the 'bronze' and 'silver' tables. Though this means that next months data could be added without changing anything else, it would overwrite what is already in the tables. So a new naming convention that includes the file dates would be needed to keep old data along with adding the new.

## How to run

1. Enter your file paths in the `02_bronze` notebook in the second cell.

2. Click 'Run All' for the `02_bronze` notebook.

3. Click 'Run All' for the `03_silver` notebook.

4. Click 'Run All' for the `04_gold` notebook.

5. You can explore the tables in `workspace.tfl`
