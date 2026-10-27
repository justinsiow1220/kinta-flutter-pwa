import 'package:flutter/material.dart'
    show ChangeNotifier, Color, Colors, VoidCallback;
import 'package:shared_preferences/shared_preferences.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _projectType = prefs.getString('ff_projectType') ?? _projectType;
    });
    _safeInit(() {
      _jwtToken = prefs.getString('ff_jwtToken') ?? _jwtToken;
    });
    _safeInit(() {
      _userID = prefs.getString('ff_userID') ?? _userID;
    });
    _safeInit(() {
      _userRole = prefs.getString('ff_userRole') ?? _userRole;
    });
    _safeInit(() {
      _companyID = prefs.getString('ff_companyID') ?? _companyID;
    });
    _safeInit(() {
      _userName = prefs.getString('ff_userName') ?? _userName;
    });
    _safeInit(() {
      _isAdmin = prefs.getString('ff_isAdmin') ?? _isAdmin;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _projectType = 'high_rise';
  String get projectType => _projectType;
  set projectType(String value) {
    _projectType = value;
    prefs.setString('ff_projectType', value);
  }

  String _jwtToken = '';
  String get jwtToken => _jwtToken;
  set jwtToken(String value) {
    _jwtToken = value;
    prefs.setString('ff_jwtToken', value);
  }

  String _userID = '';
  String get userID => _userID;
  set userID(String value) {
    _userID = value;
    prefs.setString('ff_userID', value);
  }

  String _userRole = '';
  String get userRole => _userRole;
  set userRole(String value) {
    _userRole = value;
    prefs.setString('ff_userRole', value);
  }

  String _companyID = '';
  String get companyID => _companyID;
  set companyID(String value) {
    _companyID = value;
    prefs.setString('ff_companyID', value);
  }

  bool _refreshList = false;
  bool get refreshList => _refreshList;
  set refreshList(bool value) {
    _refreshList = value;
  }

  String _userName = '';
  String get userName => _userName;
  set userName(String value) {
    _userName = value;
    prefs.setString('ff_userName', value);
  }

  String _isAdmin = '';
  String get isAdmin => _isAdmin;
  set isAdmin(String value) {
    _isAdmin = value;
    prefs.setString('ff_isAdmin', value);
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
