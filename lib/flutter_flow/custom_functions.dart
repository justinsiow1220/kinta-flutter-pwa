import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';

List<dynamic> filterProjects(
  List<dynamic> projectList,
  String? searchString,
) {
  print('Searching for: $searchString');
  // If search is empty or null, show the full list
  if (searchString == null || searchString.isEmpty) {
    return projectList;
  }

  // Filter based on the project_name field
  return projectList.where((project) {
    final projectName = project['project_name']?.toString().toLowerCase() ?? '';
    return projectName.contains(searchString.toLowerCase());
  }).toList();
}

List<dynamic> filterStaff(
  List<dynamic> staffList,
  String? searchString,
  String? staffStatus,
) {
  return staffList.where((staff) {
    // 1. Get values from JSON safely
    final staffName = staff['username']?.toString().toLowerCase() ?? '';
    final dbStatus = staff['status']?.toString() ?? ''; // "1" or "0"
    final isEmailVerified =
        staff['is_email_verified']?.toString() ?? '0'; // "1" or "0"

    // 2. Determine the Calculated Status for this staff member
    String computedStatus;
    if (isEmailVerified != '1') {
      computedStatus = 'pending';
    } else {
      computedStatus = (dbStatus == '1') ? 'active' : 'inactive';
    }

    // 3. Status Filter Logic
    bool matchesStatus = true;
    if (staffStatus != null && staffStatus.toLowerCase() != 'all') {
      matchesStatus = (computedStatus == staffStatus.toLowerCase());
    }

    // 4. Search Filter Logic
    bool matchesSearch = true;
    if (searchString != null && searchString.isNotEmpty) {
      matchesSearch = staffName.contains(searchString.toLowerCase());
    }

    // Return true only if both conditions are met
    return matchesStatus && matchesSearch;
  }).toList();
}

List<dynamic> findExistingDefectOptions(
  List<dynamic>? masterList,
  String? searchTerm,
) {
  if (searchTerm == null || searchTerm.isEmpty || masterList == null) {
    return [];
  }

  return masterList
      .where((item) => item['title']
          .toString()
          .toLowerCase()
          .contains(searchTerm.toLowerCase().trim()))
      .toList();
}

List<dynamic> filterDefects(
  List<dynamic> defectLists,
  String? searchString,
) {
  print(searchString);
  // 1. If search is null or just empty spaces, return the full list
  // (or return an empty list [] if you prefer it to be empty until they type)
  if (searchString == null || searchString.trim().isEmpty) {
    print(searchString);
    return defectLists;
  }

  final query = searchString.toLowerCase().trim();

  final filteredList = defectLists.where((defect) {
    print(defect);
    // 2. Extract and safely handle all fields
    final areaName = defect['area_name']?.toString().toLowerCase() ?? '';
    final categoryName =
        defect['category_name']?.toString().toLowerCase() ?? '';
    final problemName = defect['problem_name']?.toString().toLowerCase() ?? '';
    final sequenceName = defect['sequence']?.toString().toLowerCase() ?? '';

    // 3. Match logic
    return areaName.contains(query) ||
        categoryName.contains(query) ||
        sequenceName.contains(query) ||
        problemName.contains(query);
  }).toList();

  return filteredList;
}

List<dynamic> filterCases(
  List<dynamic> fullList,
  String? statusFilter,
  String? searchKeyword,
) {
  // 1. Guard clause: Return empty list if source data is null
  List<dynamic> targetList = fullList;
  if (fullList.isNotEmpty && fullList.first is List) {
    targetList = fullList.first as List<dynamic>;
  }

  // 3. Filter by Status first (if a filter is active and not 'all')
  var statusFiltered = targetList;
  if (statusFilter != null &&
      statusFilter.isNotEmpty &&
      statusFilter.toLowerCase() != 'all') {
    final statusQuery = statusFilter.toLowerCase().trim();

    statusFiltered = targetList.where((item) {
      if (item is! Map) return false;

      final itemStatus = item['status']?.toString().toLowerCase().trim() ?? '';

      if (statusQuery == 'pending') {
        return itemStatus == 'pending';
      }
      if (statusQuery == 'draft') {
        return itemStatus == 'draft';
      }
      if (statusQuery == 'approved') {
        return itemStatus == 'approved';
      }
      return itemStatus == statusQuery;
    }).toList();
  }

  // 4. Filter by Search Keyword (Matching your working filterDefects logic)
  if (searchKeyword == null || searchKeyword.trim().isEmpty) {
    return statusFiltered;
  }

  final query = searchKeyword.toLowerCase().trim();

  final finalFilteredList = statusFiltered.where((item) {
    if (item is! Map) return false;

    final ownerName = item['owner_name']?.toString().toLowerCase() ?? '';

    final unitName = item['unit_name']?.toString().toLowerCase() ?? '';
    final refNo = item['ref_no']?.toString().toLowerCase() ?? '';

    return ownerName.contains(query) ||
        unitName.contains(query) ||
        refNo.contains(query);
  }).toList();

  return finalFilteredList;
}

int? getJsonCount(List<dynamic>? jsonList) {
  // If the list is null or empty, return 0
  if (jsonList == null) {
    return 0;
  }
  return jsonList.length;
}

String? getTitleFromId(
  String? idParam,
  List<dynamic> listParam,
) {
  for (var item in listParam) {
    // Check both string and integer IDs safely
    if (item['id'].toString() == idParam.toString()) {
      return item['title']?.toString() ?? 'Unknown';
    }
  }

  return 'Unknown';
}

String? breakAfterFirstSpace(String? title) {
  return (title ?? '').replaceFirst(' ', '\n');
}

double checkTrial(String? refno) {
// 1. If the text is empty or null, it's not a trial, return 0.0
  if (refno == null || refno.isEmpty) {
    return 0.0;
  }

  // 2. Check if the text contains the word 'Trial'
  if (refno.contains('Trial')) {
    return 1.0; // Word found
  }

  return 0.0; // Word not found
}
