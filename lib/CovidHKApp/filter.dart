import 'package:flutter/material.dart';
import 'package:hkinfo/CovidHKApp/case.dart';

class CaseFilter {
  List<Case> cases;

  // filters
  // RangeValues range;
  // RangeValues dateRange;
  String textSearch;
  String district;
  bool fourTeenDaysAgo;
  // int maxDaysAgo;
  bool ascending = true;
  String caseClassification;
  //
  double max;
  double min;
  //

  DateTime firstDay = DateTime(2020, 7, 5);
  CaseFilter(this.cases) {
    // this.max = this.cases.last.caseNum.toDouble();
    // this.min = this.cases[0].caseNum.toDouble();
    resetFilter();
  }

  List<Case> getCases() {
    List<Case> nCases = this.cases;
    // if (!(this.range.start == this.min && this.range.end == this.max)) {
    //   nCases = nCases.where((Case cAse) {
    //     return cAse.caseNum >= this.range.start &&
    //         cAse.caseNum <= this.range.end;
    //   }).toList();
    // }

    // Search

    if (textSearch != null) {
      nCases = nCases.where((Case cAse) {
        return (cAse.district
                .toLowerCase()
                .contains(this.textSearch.trim().toLowerCase()) ||
            cAse.building
                .toLowerCase()
                .contains(this.textSearch.trim().toLowerCase()) ||
            cAse.caseNum
                .toString()
                .contains(this.textSearch.trim().toLowerCase()) ||
            this
                .textSearch
                .trim()
                .toLowerCase()
                .contains(cAse.caseNum.toString()) ||
            this
                .textSearch
                .trim()
                .toLowerCase()
                .contains(cAse.building.toLowerCase()) ||
            this
                .textSearch
                .trim()
                .toLowerCase()
                .contains(cAse.district.toLowerCase()));
      }).toList();
    }

    if (this.fourTeenDaysAgo) {
      DateTime now = DateTime.now();
      nCases = nCases
          .where((Case cAse) => now.difference(cAse.reportDate).inDays < 15)
          .toList();
    }

    if (this.district != 'All' &&
        this.district != '' &&
        this.district != null) {
      nCases = nCases.where((Case cAse) => cAse.district == district).toList();
    }

    if (this.caseClassification != 'All' &&
        this.caseClassification != '' &&
        this.caseClassification != null) {
      nCases = nCases
          .where((Case cAse) => cAse.classification
              .toLowerCase()
              .contains(this.caseClassification.toLowerCase()))
          .toList();
    }
    return nCases;
  }

  void resetFilter() {
    // this.range = RangeValues(this.min, this.max);
    this.district = 'All';
    this.fourTeenDaysAgo = false;
    this.textSearch = '';
    this.caseClassification = 'All';
  }

  static List<String> get districts => [
        'All',
        'Islands',
        'Kwai Tsing',
        'North',
        'Sai Kung',
        'Sha Tin',
        'Tai Po',
        'Tsuen Wan',
        'Tuen Mun',
        'Yuen Long',
        'Kowloon City',
        'Kwun Tong',
        'Sham Shui Po',
        'Wong Tai Sin',
        'Yau Tsim Mong',
        'Central & Western',
        'Eastern',
        'Southern',
        'Wan Chai'
      ];
  static List<String> get caseTypes => [
        'All',
        'Local',
        'Imported',
      ];
}
