import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start Protected API Group Code

class ProtectedAPIGroup {
  static String getBaseUrl({
    String? jwtToken = '',
  }) =>
      'https://staging.mydefix.com/api/';
  static Map<String, String> headers = {
    'Authorization': 'Bearer [jwtToken]',
  };
  static GetActivePlansCall getActivePlansCall = GetActivePlansCall();
  static CreateProjectCall createProjectCall = CreateProjectCall();
  static ChangePasswordCall changePasswordCall = ChangePasswordCall();
  static CreateCompanyCall createCompanyCall = CreateCompanyCall();
  static CreateCheckoutCall createCheckoutCall = CreateCheckoutCall();
  static GetLatestCreditsCall getLatestCreditsCall = GetLatestCreditsCall();
  static GetInvoiceListCall getInvoiceListCall = GetInvoiceListCall();
  static GetCompanyDetailsCall getCompanyDetailsCall = GetCompanyDetailsCall();
  static UpdateCompanyCall updateCompanyCall = UpdateCompanyCall();
  static GetProjectListCall getProjectListCall = GetProjectListCall();
  static GetStaffListCall getStaffListCall = GetStaffListCall();
  static CheckCreditCall checkCreditCall = CheckCreditCall();
  static AddCaseCall addCaseCall = AddCaseCall();
  static GetCasesByProjectCall getCasesByProjectCall = GetCasesByProjectCall();
  static GetAreasCall getAreasCall = GetAreasCall();
  static GetElementsCall getElementsCall = GetElementsCall();
  static GetCategoriesCall getCategoriesCall = GetCategoriesCall();
  static GetProblemsCall getProblemsCall = GetProblemsCall();
  static AddAreaCall addAreaCall = AddAreaCall();
  static AddElementCall addElementCall = AddElementCall();
  static AddDefectCategoriesCall addDefectCategoriesCall =
      AddDefectCategoriesCall();
  static AddDefectProblemsCall addDefectProblemsCall = AddDefectProblemsCall();
  static AddDefectCall addDefectCall = AddDefectCall();
  static GetDefectsCall getDefectsCall = GetDefectsCall();
  static UpdateDefectCall updateDefectCall = UpdateDefectCall();
  static SubmitCaseCall submitCaseCall = SubmitCaseCall();
  static GetCaseImageCall getCaseImageCall = GetCaseImageCall();
  static CheckStatusCall checkStatusCall = CheckStatusCall();
  static UpdateStaffCall updateStaffCall = UpdateStaffCall();
  static GetCasesByStaffCall getCasesByStaffCall = GetCasesByStaffCall();
  static GetCaseByIdCall getCaseByIdCall = GetCaseByIdCall();
  static GetProjectByIdCall getProjectByIdCall = GetProjectByIdCall();
  static ViewCaseReportCall viewCaseReportCall = ViewCaseReportCall();
  static ApprovedCaseCall approvedCaseCall = ApprovedCaseCall();
  static GetNextSequenceCall getNextSequenceCall = GetNextSequenceCall();
  static GenerateReportCall generateReportCall = GenerateReportCall();
  static GetCaseCountsByProjectCall getCaseCountsByProjectCall =
      GetCaseCountsByProjectCall();
  static AddDefectPhotosCall addDefectPhotosCall = AddDefectPhotosCall();
  static DeleteDefectPhotoCall deleteDefectPhotoCall = DeleteDefectPhotoCall();
  static RemoveCaseCall removeCaseCall = RemoveCaseCall();
  static DeleteProjectCall deleteProjectCall = DeleteProjectCall();
  static UpdateProjectCall updateProjectCall = UpdateProjectCall();
  static GetStaffCountSummaryCall getStaffCountSummaryCall =
      GetStaffCountSummaryCall();
  static CheckProfileCall checkProfileCall = CheckProfileCall();
}

class GetActivePlansCall {
  Future<ApiCallResponse> call({
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getActivePlans',
      apiUrl: '${baseUrl}getActivePlans',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateProjectCall {
  Future<ApiCallResponse> call({
    String? projectName = '',
    String? projectType = '',
    String? userID = '',
    String? projectLogo = '',
    String? companyID = '',
    String? country = '',
    String? city = '',
    String? state = '',
    String? postalCode = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_name": ${projectName == null ? 'null' : '"${escapeStringForJson(projectName)}"'},
  "project_type": ${projectType == null ? 'null' : '"${escapeStringForJson(projectType)}"'},
  "user_id": ${userID == null ? 'null' : '"${escapeStringForJson(userID)}"'},
  "projectLogo": ${projectLogo == null ? 'null' : '"${escapeStringForJson(projectLogo)}"'},
  "companyID": ${companyID == null ? 'null' : '"${escapeStringForJson(companyID)}"'},
  "country": ${country == null ? 'null' : '"${escapeStringForJson(country)}"'},
  "city": ${city == null ? 'null' : '"${escapeStringForJson(city)}"'},
  "state": ${state == null ? 'null' : '"${escapeStringForJson(state)}"'},
  "postal_code": ${postalCode == null ? 'null' : '"${escapeStringForJson(postalCode)}"'}
}
''';
    return ApiManager.instance.makeApiCall(
      callName: 'createProject',
      apiUrl: '${baseUrl}projects',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ChangePasswordCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? existingPassword = '',
    String? newPassword = '',
    String? confirmPassword = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId == null ? 'null' : '"${escapeStringForJson(userId)}"'},
  "existing_password": ${existingPassword == null ? 'null' : '"${escapeStringForJson(existingPassword)}"'},
  "new_password": ${newPassword == null ? 'null' : '"${escapeStringForJson(newPassword)}"'},
  "confirm_password": ${confirmPassword == null ? 'null' : '"${escapeStringForJson(confirmPassword)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'changePassword',
      apiUrl: '${baseUrl}changePassword',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateCompanyCall {
  Future<ApiCallResponse> call({
    String? companyName = '',
    String? country = '',
    String? address = '',
    String? city = '',
    String? state = '',
    String? postalcode = '',
    String? email = '',
    String? companyType = '',
    String? userId = '',
    String? companyRegNo = '',
    String? companyLogo = '',
    String? addressFull = '',
    String? fax = '',
    String? contact = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "company_name": ${companyName == null ? 'null' : '"${escapeStringForJson(companyName)}"'},
  "country": ${country == null ? 'null' : '"${escapeStringForJson(country)}"'},
  "address": ${address == null ? 'null' : '"${escapeStringForJson(address)}"'},
  "city": ${city == null ? 'null' : '"${escapeStringForJson(city)}"'},
  "state": ${state == null ? 'null' : '"${escapeStringForJson(state)}"'},
  "postalcode": ${postalcode == null ? 'null' : '"${escapeStringForJson(postalcode)}"'},
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'},
  "companyType": ${companyType == null ? 'null' : '"${escapeStringForJson(companyType)}"'},
  "user_id": ${userId == null ? 'null' : '"${escapeStringForJson(userId)}"'},
  "company_reg_no": ${companyRegNo == null ? 'null' : '"${escapeStringForJson(companyRegNo)}"'},
  "companyLogo": ${companyLogo == null ? 'null' : '"${escapeStringForJson(companyLogo)}"'},
  "address_full": ${addressFull == null ? 'null' : '"${escapeStringForJson(addressFull)}"'},
  "fax": ${fax == null ? 'null' : '"${escapeStringForJson(fax)}"'},
  "contact": ${contact == null ? 'null' : '"${escapeStringForJson(contact)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createCompany ',
      apiUrl: '${baseUrl}createCompany',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateCheckoutCall {
  Future<ApiCallResponse> call({
    String? planId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "plan_id": ${planId == null ? 'null' : '"${escapeStringForJson(planId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createCheckout',
      apiUrl: '${baseUrl}create-checkout',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetLatestCreditsCall {
  Future<ApiCallResponse> call({
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getLatestCredits',
      apiUrl: '${baseUrl}getLatestCredits',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetInvoiceListCall {
  Future<ApiCallResponse> call({
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getInvoiceList',
      apiUrl: '${baseUrl}getInvoiceList',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCompanyDetailsCall {
  Future<ApiCallResponse> call({
    String? companyID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "companyID": ${companyID == null ? 'null' : '"${escapeStringForJson(companyID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCompanyDetails',
      apiUrl: '$baseUrl/getCompanyDetails',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? companyType(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.type''',
      ));
}

class UpdateCompanyCall {
  Future<ApiCallResponse> call({
    String? companyName = '',
    String? country = '',
    String? address = '',
    String? city = '',
    String? companyLogo = '',
    String? companyType = '',
    String? companyRegNo = '',
    String? email = '',
    String? postalCode = '',
    String? state = '',
    String? userId = '',
    String? companyId = '',
    String? fullAddress = '',
    String? fax = '',
    String? contact = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "address": ${address == null ? 'null' : '"${escapeStringForJson(address)}"'},
  "company_name": ${companyName == null ? 'null' : '"${escapeStringForJson(companyName)}"'},
  "country": ${country == null ? 'null' : '"${escapeStringForJson(country)}"'},
  "city": ${city == null ? 'null' : '"${escapeStringForJson(city)}"'},
  "companyLogo": ${companyLogo == null ? 'null' : '"${escapeStringForJson(companyLogo)}"'},
  "companyType": ${companyType == null ? 'null' : '"${escapeStringForJson(companyType)}"'},
  "company_reg_no": ${companyRegNo == null ? 'null' : '"${escapeStringForJson(companyRegNo)}"'},
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'},
  "postal_code": ${postalCode == null ? 'null' : '"${escapeStringForJson(postalCode)}"'},
  "state": ${state == null ? 'null' : '"${escapeStringForJson(state)}"'},
  "user_id": ${userId == null ? 'null' : '"${escapeStringForJson(userId)}"'},
  "company_id": ${companyId == null ? 'null' : '"${escapeStringForJson(companyId)}"'},
  "full_address": ${fullAddress == null ? 'null' : '"${escapeStringForJson(fullAddress)}"'},
  "fax": ${fax == null ? 'null' : '"${escapeStringForJson(fax)}"'},
  "contact": ${contact == null ? 'null' : '"${escapeStringForJson(contact)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'updateCompany',
      apiUrl: '$baseUrl/updateCompany',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetProjectListCall {
  Future<ApiCallResponse> call({
    String? compID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "companyID": ${compID == null ? 'null' : '"${escapeStringForJson(compID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getProjectList',
      apiUrl: '${baseUrl}getProjectList',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetStaffListCall {
  Future<ApiCallResponse> call({
    String? companyId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "company_id": ${companyId == null ? 'null' : '"${escapeStringForJson(companyId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getStaffList',
      apiUrl: '${baseUrl}getStaffList',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckCreditCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? companyID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "companyID": ${companyID == null ? 'null' : '"${escapeStringForJson(companyID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'checkCredit',
      apiUrl: '${baseUrl}checkCredit',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddCaseCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? unitName = '',
    String? ownerName = '',
    String? ownerContact = '',
    String? projectType = '',
    String? email = '',
    String? address = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "unit_name": ${unitName == null ? 'null' : '"${escapeStringForJson(unitName)}"'},
  "owner_name": ${ownerName == null ? 'null' : '"${escapeStringForJson(ownerName)}"'},
  "owner_contact": ${ownerContact == null ? 'null' : '"${escapeStringForJson(ownerContact)}"'},
  "project_type": ${projectType == null ? 'null' : '"${escapeStringForJson(projectType)}"'},
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'},
  "address": ${address == null ? 'null' : '"${escapeStringForJson(address)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addCase',
      apiUrl: '${baseUrl}addCase',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCasesByProjectCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCasesByProject',
      apiUrl: '${baseUrl}getCasesByProject',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data[:].status''',
      ));
  List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class GetAreasCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getAreas',
      apiUrl: '${baseUrl}getAreas',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetElementsCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? areaId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getElements',
      apiUrl: '${baseUrl}getElements',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCategoriesCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? defectElementId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "defect_element_id": ${defectElementId == null ? 'null' : '"${escapeStringForJson(defectElementId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCategories',
      apiUrl: '${baseUrl}getCategories',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetProblemsCall {
  Future<ApiCallResponse> call({
    String? defectCategoriesId = '',
    String? projectId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "defect_categories_id": ${defectCategoriesId == null ? 'null' : '"${escapeStringForJson(defectCategoriesId)}"'},
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getProblems',
      apiUrl: '${baseUrl}getProblems',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddAreaCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? areaName = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "area_name": ${areaName == null ? 'null' : '"${escapeStringForJson(areaName)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addArea',
      apiUrl: '${baseUrl}addArea',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddElementCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? title = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "title": ${title == null ? 'null' : '"${escapeStringForJson(title)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addElement',
      apiUrl: '${baseUrl}addElement',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddDefectCategoriesCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? title = '',
    String? defectElementId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "title": ${title == null ? 'null' : '"${escapeStringForJson(title)}"'},
  "defect_element_id": ${defectElementId == null ? 'null' : '"${escapeStringForJson(defectElementId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addDefectCategories',
      apiUrl: '${baseUrl}addDefectCategories',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddDefectProblemsCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? title = '',
    String? defectCategoriesId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "title": ${title == null ? 'null' : '"${escapeStringForJson(title)}"'},
  "defect_categories_id": ${defectCategoriesId == null ? 'null' : '"${escapeStringForJson(defectCategoriesId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addDefectProblems',
      apiUrl: '${baseUrl}addDefectProblems',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddDefectCall {
  Future<ApiCallResponse> call({
    String? defectCasesId = '',
    String? defectAreaId = '',
    String? defectCategoryId = '',
    String? defectProblemId = '',
    String? remarks = '',
    String? defectElementId = '',
    dynamic listImageJson,
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final listImage = _serializeJson(listImageJson, true);
    final ffApiRequestBody = '''
{
  "defect_cases_id": ${defectCasesId == null ? 'null' : '"${escapeStringForJson(defectCasesId)}"'},
  "defect_area_id": ${defectAreaId == null ? 'null' : '"${escapeStringForJson(defectAreaId)}"'},
  "defect_category_id": ${defectCategoryId == null ? 'null' : '"${escapeStringForJson(defectCategoryId)}"'},
  "defect_problem_id": ${defectProblemId == null ? 'null' : '"${escapeStringForJson(defectProblemId)}"'},
  "remarks": ${remarks == null ? 'null' : '"${escapeStringForJson(remarks)}"'},
  "defect_element_id": ${defectElementId == null ? 'null' : '"${escapeStringForJson(defectElementId)}"'},
  "list_images": $listImage
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addDefect',
      apiUrl: '${baseUrl}addDefect',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetDefectsCall {
  Future<ApiCallResponse> call({
    String? caseID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "caseID": ${caseID == null ? 'null' : '"${escapeStringForJson(caseID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getDefects',
      apiUrl: '${baseUrl}getDefects',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? apiError(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.error''',
      ));
  String? apiStatus(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
}

class UpdateDefectCall {
  Future<ApiCallResponse> call({
    String? caseId = '',
    String? defectAreaId = '',
    String? defectCategoryId = '',
    String? defectProblemId = '',
    String? defectElementId = '',
    String? remarks = '',
    dynamic listImageJson,
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final listImage = _serializeJson(listImageJson, true);
    final ffApiRequestBody = '''
{
  "case_id": ${caseId == null ? 'null' : '"${escapeStringForJson(caseId)}"'},
  "defect_area_id": ${defectAreaId == null ? 'null' : '"${escapeStringForJson(defectAreaId)}"'},
  "defect_category_id": ${defectCategoryId == null ? 'null' : '"${escapeStringForJson(defectCategoryId)}"'},
  "defect_problem_id": ${defectProblemId == null ? 'null' : '"${escapeStringForJson(defectProblemId)}"'},
  "remarks": ${remarks == null ? 'null' : '"${escapeStringForJson(remarks)}"'},
  "defect_element_id": ${defectElementId == null ? 'null' : '"${escapeStringForJson(defectElementId)}"'},
  "list_image": $listImage
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'updateDefect',
      apiUrl: '${baseUrl}updateDefect',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class SubmitCaseCall {
  Future<ApiCallResponse> call({
    String? caseId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "case_id": ${caseId == null ? 'null' : '"${escapeStringForJson(caseId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'submitCase',
      apiUrl: '${baseUrl}submitCase',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCaseImageCall {
  Future<ApiCallResponse> call({
    String? caseID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "case_id": ${caseID == null ? 'null' : '"${escapeStringForJson(caseID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCaseImage',
      apiUrl: '${baseUrl}getCaseImage',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckStatusCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? defectId = '',
    String? companyId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "defect_id": ${defectId == null ? 'null' : '"${escapeStringForJson(defectId)}"'},
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'},
  "company_id": ${companyId == null ? 'null' : '"${escapeStringForJson(companyId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'checkStatus',
      apiUrl: '${baseUrl}checkStatus',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UpdateStaffCall {
  Future<ApiCallResponse> call({
    String? staffId = '',
    String? username = '',
    String? position = '',
    String? contact = '',
    String? email = '',
    String? isAdmin = '',
    String? staffPhoto = '',
    String? staffStatus = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "staff_id": ${staffId == null ? 'null' : '"${escapeStringForJson(staffId)}"'},
  "username": ${username == null ? 'null' : '"${escapeStringForJson(username)}"'},
  "position": ${position == null ? 'null' : '"${escapeStringForJson(position)}"'},
  "contact": ${contact == null ? 'null' : '"${escapeStringForJson(contact)}"'},
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'},
  "is_admin": ${isAdmin == null ? 'null' : '"${escapeStringForJson(isAdmin)}"'},
  "staff_photo": ${staffPhoto == null ? 'null' : '"${escapeStringForJson(staffPhoto)}"'},
  "staff_status": ${staffStatus == null ? 'null' : '"${escapeStringForJson(staffStatus)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'updateStaff',
      apiUrl: '${baseUrl}updateStaff',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCasesByStaffCall {
  Future<ApiCallResponse> call({
    String? staffId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "staff_id": ${staffId == null ? 'null' : '"${escapeStringForJson(staffId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCasesByStaff',
      apiUrl: '${baseUrl}getCasesByStaff',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCaseByIdCall {
  Future<ApiCallResponse> call({
    String? caseId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "case_id": ${caseId == null ? 'null' : '"${escapeStringForJson(caseId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCaseById',
      apiUrl: '${baseUrl}getCaseById',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetProjectByIdCall {
  Future<ApiCallResponse> call({
    String? projectID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "projectID": ${projectID == null ? 'null' : '"${escapeStringForJson(projectID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getProjectById',
      apiUrl: '${baseUrl}getProjectById',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ViewCaseReportCall {
  Future<ApiCallResponse> call({
    String? caseID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "caseID": ${caseID == null ? 'null' : '"${escapeStringForJson(caseID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'viewCaseReport',
      apiUrl: '${baseUrl}viewCaseReport',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApprovedCaseCall {
  Future<ApiCallResponse> call({
    String? caseId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "case_id": ${caseId == null ? 'null' : '"${escapeStringForJson(caseId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'approvedCase',
      apiUrl: '${baseUrl}approvedCase',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetNextSequenceCall {
  Future<ApiCallResponse> call({
    String? caseId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "case_id": ${caseId == null ? 'null' : '"${escapeStringForJson(caseId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getNextSequence',
      apiUrl: '${baseUrl}getNextSequence',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GenerateReportCall {
  Future<ApiCallResponse> call({
    String? caseId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'generateReport',
      apiUrl: '${baseUrl}generateReport/$caseId',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCaseCountsByProjectCall {
  Future<ApiCallResponse> call({
    String? projectId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "project_id": ${projectId == null ? 'null' : '"${escapeStringForJson(projectId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getCaseCountsByProject',
      apiUrl: '${baseUrl}getCaseCountsByProject',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddDefectPhotosCall {
  Future<ApiCallResponse> call({
    String? casesDetailsId = '',
    dynamic listImagesJson,
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final listImages = _serializeJson(listImagesJson, true);
    final ffApiRequestBody = '''
{
  "cases_details_id": ${casesDetailsId == null ? 'null' : '"${escapeStringForJson(casesDetailsId)}"'},
  "list_images": $listImages
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'addDefectPhotos',
      apiUrl: '${baseUrl}addDefectPhotos',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteDefectPhotoCall {
  Future<ApiCallResponse> call({
    String? photoId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "photo_id": ${photoId == null ? 'null' : '"${escapeStringForJson(photoId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'deleteDefectPhoto',
      apiUrl: '${baseUrl}deleteDefectPhoto',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RemoveCaseCall {
  Future<ApiCallResponse> call({
    String? casesID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "casesID": ${casesID == null ? 'null' : '"${escapeStringForJson(casesID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'removeCase',
      apiUrl: '${baseUrl}removeCase',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteProjectCall {
  Future<ApiCallResponse> call({
    String? projectID = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "projectID": ${projectID == null ? 'null' : '"${escapeStringForJson(projectID)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'deleteProject',
      apiUrl: '${baseUrl}deleteProject',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UpdateProjectCall {
  Future<ApiCallResponse> call({
    String? projectName = '',
    String? projectID = '',
    String? projectLogo = '',
    String? country = '',
    String? city = '',
    String? state = '',
    String? postalCode = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "projectName": ${projectName == null ? 'null' : '"${escapeStringForJson(projectName)}"'},
  "projectID": ${projectID == null ? 'null' : '"${escapeStringForJson(projectID)}"'},
  "projectLogo": ${projectLogo == null ? 'null' : '"${escapeStringForJson(projectLogo)}"'},
  "country": ${country == null ? 'null' : '"${escapeStringForJson(country)}"'},
  "city": ${city == null ? 'null' : '"${escapeStringForJson(city)}"'},
  "state": ${state == null ? 'null' : '"${escapeStringForJson(state)}"'},
  "postal_code": ${postalCode == null ? 'null' : '"${escapeStringForJson(postalCode)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'updateProject',
      apiUrl: '${baseUrl}updateProject',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetStaffCountSummaryCall {
  Future<ApiCallResponse> call({
    String? companyId = '',
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    final ffApiRequestBody = '''
{
  "company_id": ${companyId == null ? 'null' : '"${escapeStringForJson(companyId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'getStaffCountSummary',
      apiUrl: '${baseUrl}getStaffCountSummary',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckProfileCall {
  Future<ApiCallResponse> call({
    String? jwtToken = '',
  }) async {
    final baseUrl = ProtectedAPIGroup.getBaseUrl(
      jwtToken: jwtToken,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'checkProfile',
      apiUrl: '${baseUrl}checkProfile',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End Protected API Group Code

class RegisterUserCall {
  static Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
    String? role = '',
    String? username = '',
    String? contact = '',
    String? isAdmin = '',
    String? companyID = '',
    String? staffPhotoBase64 = '',
    String? passwordConfirm = '',
    String? page = '',
  }) async {
    final ffApiRequestBody = '''
{
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'},
  "password": ${password == null ? 'null' : '"${escapeStringForJson(password)}"'},
  "password_confirm": ${passwordConfirm == null ? 'null' : '"${escapeStringForJson(passwordConfirm)}"'},
  "role": ${role == null ? 'null' : '"${escapeStringForJson(role)}"'},
  "username": ${username == null ? 'null' : '"${escapeStringForJson(username)}"'},
  "contact": ${contact == null ? 'null' : '"${escapeStringForJson(contact)}"'},
  "is_admin": ${isAdmin == null ? 'null' : '"${escapeStringForJson(isAdmin)}"'},
  "companyID": ${companyID == null ? 'null' : '"${escapeStringForJson(companyID)}"'},
  "staffPhoto": ${staffPhotoBase64 == null ? 'null' : '"${escapeStringForJson(staffPhotoBase64)}"'},
  "page": ${page == null ? 'null' : '"${escapeStringForJson(page)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'registerUser',
      apiUrl: 'https://staging.mydefix.com/api/register',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? apiErrorMessage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.messages.error''',
      ));
}

class LoginUserCall {
  static Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
  }) async {
    final ffApiRequestBody = '''
{
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'},
"password": ${password == null ? 'null' : '"${escapeStringForJson(password)}"'}

}''';
    return ApiManager.instance.makeApiCall(
      callName: 'loginUser',
      apiUrl: 'https://staging.mydefix.com/api/login',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckVerificationStatusCall {
  static Future<ApiCallResponse> call({
    String? userId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "user_id": ${userId == null ? 'null' : '"${escapeStringForJson(userId)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'CheckVerificationStatus',
      apiUrl: 'https://staging.mydefix.com/api/checkVerificationStatus',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ForgotPasswordCall {
  static Future<ApiCallResponse> call({
    String? email = '',
  }) async {
    final ffApiRequestBody = '''
{
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ForgotPassword ',
      apiUrl: 'https://staging.mydefix.com/api/forgotPassword',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ResendVerificationCall {
  static Future<ApiCallResponse> call({
    String? email = '',
  }) async {
    final ffApiRequestBody = '''
{
  "email": ${email == null ? 'null' : '"${escapeStringForJson(email)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ResendVerification',
      apiUrl: 'https://staging.mydefix.com/api/resendVerification',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCountriesCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetCountries',
      apiUrl: 'https://staging.mydefix.com/api/getCountries',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? countryList(dynamic response) => (getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetStatesCall {
  static Future<ApiCallResponse> call({
    String? selectedCountry = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getStates',
      apiUrl: 'https://staging.mydefix.com/api/getStates',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'country': selectedCountry,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? getStates(dynamic response) => (getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetTermsAndConditionsPdfCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'getTermsAndConditionsPdf',
      apiUrl: 'https://staging.mydefix.com/api/getTermsAndConditionsPdf',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  final encoded = jsonEncode(input);
  return encoded.substring(1, encoded.length - 1);
}
