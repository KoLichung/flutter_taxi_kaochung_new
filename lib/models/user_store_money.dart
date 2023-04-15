class UserStoreMoney {
  int? id;
  int? increaseMoney;
  int? userLeftMoney;
  int? sumMoney;
  String? date;
  int? user;

  UserStoreMoney(
      {this.id,
        this.increaseMoney,
        this.userLeftMoney,
        this.sumMoney,
        this.date,
        this.user});

  UserStoreMoney.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    increaseMoney = json['increase_money'];
    userLeftMoney = json['user_left_money'];
    sumMoney = json['sum_money'];
    date = json['date'];
    user = json['user'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['increase_money'] = this.increaseMoney;
    data['user_left_money'] = this.userLeftMoney;
    data['sum_money'] = this.sumMoney;
    data['date'] = this.date;
    data['user'] = this.user;
    return data;
  }
}