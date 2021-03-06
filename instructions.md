# Todo

- [ ]  ***iOS***
- [ ] ?? Add daily notification for hk cases
- [ ] [gov](https://data.gov.hk/en-data/dataset/hk-dh-chpsebcddr-novel-infectious-agent) api to show location of cases
- [ ] Bug: Fix deaths scale
- [ ] Change countries.dart to json file
- [ ] Create interchangeable themes
- [ ] Preserve current country when switching between pages in PageView
- [ ] Check if data is corect in HK cases info
- [ ] ?? Add an *all countries* dashboard
- [ ] Make list of stops editable when choosing which to add
- [ ] ?? Be able to edit stops
- [ ] Add more stops

##### Completed

- [ ] ~~Use google maps api~~
- [x] fix Search function in filter.dart
- [x] App Icon
- [ ]  ~~Use [DataTable](https://www.youtube.com/watch?v=ktTajqbhIcY&vl=en) for Bottom Sheet~~
- [x]  Optimize data loading (sorting, ...) which causes frames to jump when loading more info for hk
- [x] Complete filter functionality for cases info (dates / days ago, ...) :
  - [x] Choose which districts
  - [x] Link cases
  - [x] Remove Case Range slider
- [x]  Error: setState() called after dispose() - when screen is disposed of before page is done loading
- [x] Add multiple stop functionality
- [x] Fix onset Date
- [x] Why some cases have duplicates (e.g. case 3397 - 3368)
- [x] Show Dropdowns over case list to choose which fields to show
- [x] Use [tootltip](https://www.youtube.com/watch?v=EeEfD5fI-5Q)
- [x] show map in district info
- [x] add district numbers next to each district
- [x] Optimise Loading of data from owid by saving in memory for 1 day (Time of update ~= 17:15 HK)
      TimeOfDay.utc()  
- [ ] ~~Use [smaller data set](https://covid.ourworldindata.org/data/ecdc/full_data.csv)~~
- [x] fix shadow on dropdowns for districts
- [x] Make filter function for cases info
- [x] Wrap Reminders and Covid Apps in PageView
