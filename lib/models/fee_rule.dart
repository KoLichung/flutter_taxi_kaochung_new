class FeeRule {
  int? id;
  String? title;
  int? startFee;
  String? fifteenSecondFee;
  String? twoHundredMeterFee;

  FeeRule(
      {this.id,
        this.title,
        this.startFee,
        this.fifteenSecondFee,
        this.twoHundredMeterFee});

  FeeRule.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    startFee = json['start_fee'];
    fifteenSecondFee = json['fifteen_second_fee'];
    twoHundredMeterFee = json['two_hundred_meter_fee'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['start_fee'] = this.startFee;
    data['fifteen_second_fee'] = this.fifteenSecondFee;
    data['two_hundred_meter_fee'] = this.twoHundredMeterFee;
    return data;
  }
}