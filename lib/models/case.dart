import 'dart:ffi';

class Case {
  int? id;
  int? carTeamId;
  String? caseState;
  String? customerName;
  String? customerPhone;
  String? onLat;
  String? onLng;
  String? onAddress;
  String? offLat;
  String? offLng;
  String? offAddress;
  int? caseMoney;
  String? createTime;
  String? confirmTime;
  String? arrivedTime;
  String? catchedTime;
  String? offTime;
  int? customer;
  int? owner;
  int? user;
  String? shipState;
  // int? countdownSecond;
  DateTime? dispatchTime;
  int? expectSecond;

  String? memo;
  String? timeMemo;
  String? carTeamName;

  String? feeTitle;
  int? feeStartFee;
  double? feeFifteenSecondFee;
  double? feeTwoHundredMeterFee;

  int? userExpectSecond;
  bool? isNextCase;

  Case(
      {this.id,
        this.carTeamId,
        this.caseState,
        this.customerName,
        this.customerPhone,
        this.onLat,
        this.onLng,
        this.onAddress,
        this.offLat,
        this.offLng,
        this.offAddress,
        this.caseMoney,
        this.createTime,
        this.confirmTime,
        this.arrivedTime,
        this.catchedTime,
        this.offTime,
        this.customer,
        this.owner,
        this.user,
        this.shipState,
        this.dispatchTime,
        this.expectSecond,
        this.memo,
        this.timeMemo,
        this.carTeamName,
        this.feeTitle,
        this.feeStartFee,
        this.feeFifteenSecondFee,
        this.feeTwoHundredMeterFee,
        this.userExpectSecond,
        this.isNextCase,
      });

  Case.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    carTeamId = json['carTeam'];
    caseState = json['case_state'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    onLat = json['on_lat'];
    onLng = json['on_lng'];
    onAddress = json['on_address'];
    offLat = json['off_lat'];
    offLng = json['off_lng'];
    if(json['off_address']!=null) {
      offAddress = json['off_address'];
    }else{
      offAddress = "";
    }
    caseMoney = json['case_money'];
    createTime = json['create_time'];
    confirmTime = json['confirm_time'];
    arrivedTime = json['arrived_time'];
    catchedTime = json['catched_time'];
    offTime = json['off_time'];
    customer = json['customer'];
    owner = json['owner'];
    user = json['user'];
    if(json['ship_state']!=null){
      if(json['ship_state']=='state1'){
        shipState = '正承接';
      }else if(json['ship_state']=='state2'){
        shipState = '副承接';
      }else{
        shipState = '';
      }
    }else{
      shipState = '';
    }
    if(json['dispatch_time']!=null){
      dispatchTime = DateTime.parse(json['dispatch_time']);
    }
    if(json['expect_second']!=null){
      expectSecond = json['expect_second'];
    }else{
      expectSecond = 0;
    }
    if(json['memo']!=null) {
      memo = json['memo'];
    }else{
      memo = "";
    }
    if(json['time_memo']!=null) {
      timeMemo = json['time_memo'];
    }else{
      timeMemo = "";
    }
    if(json['carTeamName']!=null) {
      carTeamName = json['carTeamName'];
    }else{
      carTeamName = "";
    }
    feeTitle = json['fee_title'];
    feeStartFee = json['fee_start_fee'];
    feeFifteenSecondFee = double.parse(json['fee_fifteen_second_fee']);
    feeTwoHundredMeterFee = double.parse(json['fee_two_hundred_meter_fee']);
    if(json['user_expect_second']!=null){
      userExpectSecond = json['user_expect_second'];
    }else{
      userExpectSecond = 0;
    }
    isNextCase = json['is_next_case'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['case_state'] = this.caseState;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['on_lat'] = this.onLat;
    data['on_lng'] = this.onLng;
    data['on_address'] = this.onAddress;
    data['off_lat'] = this.offLat;
    data['off_lng'] = this.offLng;
    data['off_address'] = this.offAddress;
    data['case_money'] = this.caseMoney;
    data['memo'] = this.memo;
    data['create_time'] = this.createTime;
    data['confirm_time'] = this.confirmTime;
    data['arrived_time'] = this.arrivedTime;
    data['catched_time'] = this.catchedTime;
    data['off_time'] = this.offTime;
    data['customer'] = this.customer;
    data['owner'] = this.owner;
    data['user'] = this.user;
    return data;
  }
}