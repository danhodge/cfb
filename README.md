# cfb

# Usage

## Before the Games Start

Generate the picks template and empty results file

1. scripts/scrape_picks -> results_YYYY.json
2. scripts/scape_fox_lines -> point_spreads_YYYY.json
3. scripts/merge_lines_and_schedule point_spreads_YYYY.json results_YYYY.json -> picks_YYYY.csv
4. scripts/auto_pick picks_YYYY.csv > points_2018.csv
5.

## After the Games Start

Generate the participants file

1. scripts/scrape_picks -> results_YYYY.json & participants_YYYY.json
