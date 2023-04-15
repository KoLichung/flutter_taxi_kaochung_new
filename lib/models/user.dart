class User {
  int? id;
  String? phone;
  String? name;
  String? nickName;
  String? vehicalLicence;
  String? userId;
  String? idNumber;
  String? gender;
  String? type;
  String? category;
  String? carModel;
  String? carColor;
  int? numberSites;
  String? carMemo;
  bool? isOnline;
  int? leftMoney;
  bool? isPassed;

  User(
      {this.id,
        this.phone,
        this.name,
        this.nickName,
        this.vehicalLicence,
        this.userId,
        this.idNumber,
        this.gender,
        this.type,
        this.category,
        this.carModel,
        this.carColor,
        this.numberSites,
        this.isOnline,
        this.leftMoney,
        this.isPassed,
        this.carMemo
      });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phone = json['phone'];
    name = json['name'];
    nickName = json['nick_name'];
    vehicalLicence = json['vehicalLicence'];
    userId = json['userId'];
    idNumber = json['idNumber'];
    gender = json['gender'];
    type = json['type'];
    category = json['category'];
    if(json['car_model']!=null) {
      carModel = json['car_model'];
    }else{
      carModel ="";
    }
    if(json['car_color']!=null){
      carColor = json['car_color'];
    }else{
      carColor = "";
    }
    numberSites = json['number_sites'];
    isOnline = json['is_online'];
    leftMoney = json['left_money'];
    isPassed = json['is_passed'];
    carMemo = json['car_memo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['phone'] = this.phone;
    data['name'] = this.name;
    data['nick_name'] = this.nickName;
    data['vehicalLicence'] = this.vehicalLicence;
    data['userId'] = this.userId;
    data['idNumber'] = this.idNumber;
    data['gender'] = this.gender;
    data['type'] = this.type;
    data['category'] = this.category;
    data['car_model'] = this.carModel;
    data['car_color'] = this.carColor;
    data['number_sites'] = this.numberSites;
    data['is_online'] = this.isOnline;
    data['left_money'] = this.leftMoney;
    data['is_passed'] = this.isPassed;
    data['car_memo'] = this.carMemo;
    return data;
  }
}