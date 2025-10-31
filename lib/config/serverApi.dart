class ServerApi{
  static const _HOST ='127.0.0.1:8000';

  // static const _HOST ='app.24hcartaiwan.com';

  static const PATH_CREATE_USER = '/api/user/create/';
  static const PATH_USER_TOKEN = '/api/user/token/';
  static const PATH_USER_DATA = '/api/user/me/';
  static const PATH_DELETE_USER = '/api/user/deleteuser/';
  static const PATH_USER_LEFT_MONEY = '/api/user/left_money/';
  static const PATH_REGISTER_DEVICE = '/fcm/device_register';
  static const PATH_UPDATE_FEE_RULE = '/api/user/update_fee_rule/';

  static const PATH_UPDATE_ONLINE_STATE = '/api/update_user_online_state';
  static const PATH_STORE_MONEYS = '/api/user_store_moneys/';
  static const PATH_USER_CASE = '/api/user_cases/';
  static const PATH_UPDATE_LAT_LNG = '/api/update_lat_lng';
  static const PATH_GET_CASES = '/api/v2_get_cases/';
  static const PATH_GET_CASE_DETAIL = '/api/case_detail';
  static const PATH_GET_CASE_STATE_WITH_NEXT_CASE = '/api/case_state_with_next_case';
  static const PATH_GET_FEE_RULES = '/api/fee_rules/';

  static const PATH_CASE_CONFIREM = '/api/case_confirm';
  static const PATH_CASE_ARRIVE = '/api/case_arrived';
  static const PATH_CASE_CATCHED = '/api/case_catched';
  static const PATH_CASE_FINISH = '/api/case_finished';
  static const PATH_CASE_CANCEL = '/api/case_canceled';
  static const PATH_CASE_NOTIFY_CUSTOMER = '/api/case_notify_customer';
  static const PATH_CASE_REFUSE = '/api/case_refuse';
  static const PATH_OPEN_CASES = '/api/open_cases/';

  static const PATH_CAR_TEAMS = '/api/car_teams';

  static const PATH_GEOCODE = 'https://maps.googleapis.com/maps/api/geocode/json?address=';

  static const PATH_GET_CURRENT_VERSION= '/api/get_current_version';

  // Case Message API (注意: base URL 是 /api/dispatch/)
  static const PATH_CASE_MESSAGES = '/api/dispatch/case-messages/';
  static const PATH_CASE_MESSAGE_LIST = '/api/dispatch/cases/{case_id}/messages/';
  static const PATH_CASE_MESSAGE_UNREAD_COUNT = '/api/dispatch/cases/{case_id}/messages/unread-count/';
  static const PATH_CASE_MESSAGE_MARK_READ = '/api/dispatch/cases/{case_id}/messages/mark-read/';
  static const PATH_CASE_MESSAGE_UPLOAD_URL = '/api/dispatch/cases/{case_id}/messages/upload-url/';
  static const PATH_CASE_MESSAGE_CREATE = '/api/dispatch/cases/{case_id}/messages/';

  static Uri standard({String? path, Map<String, String>? queryParameters}) {
    print(Uri.http(_HOST, '$path', queryParameters));
    return Uri.http(_HOST, '$path', queryParameters);
  }

}
