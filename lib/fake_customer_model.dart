class FakeCustomerModel{
  String distance;
  String name;
  String phoneNumber;
  String destination;
  bool isOnboard;

  FakeCustomerModel({required this.distance, required this.name, required this.phoneNumber, required this.destination, required this.isOnboard});
}

// List<FakeCustomerModel> customerList = [
//   FakeCustomerModel(distance: '400', name: '小王',phoneNumber: '0912345678',destination: '新竹市勝利一街2號',isOnboard: false),
//   FakeCustomerModel(distance: '200', name: '小美',phoneNumber: '0922345666',destination: '新竹市武昌街8號',isOnboard: false),
//   FakeCustomerModel(distance: '5', name: '小劉',phoneNumber: '0989123888',destination: '新竹市香山街66號',isOnboard: false),
// ];