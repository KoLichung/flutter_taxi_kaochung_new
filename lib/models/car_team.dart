class CarTeam {
  int? id;
  String? name;
  int? dayCaseCount;

  CarTeam({this.id, this.name, this.dayCaseCount});

  CarTeam.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    dayCaseCount = json['day_case_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['day_case_count'] = this.dayCaseCount;
    return data;
  }
}