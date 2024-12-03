import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../config/serverApi.dart';
import '../models/car_team.dart';
import '../models/user.dart';
import '../notifier_models/user_model.dart';
import '../widgets/custom_elevated_button.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {

  // final String lineId;
  final bool isEdit;
  // const Register({Key? key, required this.isEdit, required this.lineId}) : super(key: key);
  const Register({Key? key, required this.isEdit}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

enum DriverGender { male, female }

class _RegisterState extends State<Register> {

  final _formKey = GlobalKey<FormState>();

  TextEditingController driverNameController = TextEditingController();
  TextEditingController nickNameController = TextEditingController();
  TextEditingController idLast5NumberController = TextEditingController();
  TextEditingController carPlateController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController idNumberController = TextEditingController();
  TextEditingController carModelController = TextEditingController();
  TextEditingController carColorController = TextEditingController();
  TextEditingController seatNumberController = TextEditingController();
  // TextEditingController carMemoController = TextEditingController();
  TextEditingController pwdController = TextEditingController();

  DriverGender? _driverGender = DriverGender.male;

  List<CarTeam> carTeams=[];
  List<String> carTeamsString =['----'];
  String dropdownValue = '----';


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.isEdit){
      var userModel = context.read<UserModel>();
      User user = userModel.user!;
      driverNameController.text = user.name!;
      if(user.nickName == '' || user.nickName == null){
        nickNameController.text = '';
      } else {
        nickNameController.text = user.nickName!;
      }
      carPlateController.text = user.vehicalLicence!;
      phoneNumberController.text  = user.phone!;
      if(user.idNumber == '' || user.idNumber == null){
        idNumberController.text = '';
      } else {
        idNumberController.text = user.idNumber!;
      }
      carColorController.text = user.carColor!;
      seatNumberController.text = user.numberSites!.toString();
      // carMemoController.text = user.carMemo!;

      if(user.gender == '女'){
        _driverGender = DriverGender.female;
      }

    }
    getCarTeams();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: (widget.isEdit)?true:false,
          title: const Text('基本資料'),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                widget.isEdit ?
                Container()
                    :
                Column(
                  children: [
                    const SizedBox(height: 20,),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('*選擇車隊'),
                          const SizedBox(width: 15,),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.black54,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isDense: true,
                                value: dropdownValue,
                                items: carTeamsString.map<DropdownMenuItem<String>>((String value){
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child:Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                },
                              ),
                            ),
                          )
                        ],),
                    )],
                ),
                const SizedBox(height: 20,),
                validatorTextFormField('*真實姓名','',driverNameController, false, !widget.isEdit),
                validatorTextFormField('*Line名稱','',nickNameController, false, !widget.isEdit),
                validatorTextFormField('*手機號碼','',phoneNumberController, false, !widget.isEdit),
                widget.isEdit?Container():validatorTextFormField('*密碼','',pwdController, true, true),
                registerTextField('身份證字號','',idNumberController, !widget.isEdit),
                getDriverGender(!widget.isEdit),
                const SizedBox(height: 10,),
                validatorTextFormField('*車號(ABC-1234,請填 1234)','',carPlateController, false, !widget.isEdit),
                registerTextField('顏色','白',carColorController, !widget.isEdit),
                registerTextField('座位數','4',seatNumberController, !widget.isEdit),
                // Container(
                //   margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text.rich(
                //           TextSpan(children: [
                //             TextSpan(text: '駕駛備註'),
                //             TextSpan(text: '  車上禁菸、檳榔', style: TextStyle(color: Colors.red))
                //           ])
                //       ),
                //       Container(
                //         margin: const  EdgeInsets.symmetric(vertical: 6),
                //         height: 46,
                //         decoration: BoxDecoration(
                //           border: Border.all(
                //             color: Colors.black54,
                //             width: 1,),
                //           borderRadius: BorderRadius.circular(4),),
                //         child: TextField(
                //           style: const TextStyle(fontSize: 18),
                //           controller: carMemoController,
                //           decoration: InputDecoration(
                //             hintText: '車上不可飲食',
                //             hintStyle: TextStyle(color: Colors.grey.shade400),
                //             isDense: true,
                //             contentPadding: const EdgeInsets.symmetric(horizontal: 13,vertical: 10),
                //             focusedBorder: InputBorder.none,
                //             enabledBorder: InputBorder.none,
                //           ),
                //         ),
                //       ),
                //     ],),
                // ),
                widget.isEdit? Container():Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30,vertical: 20),
                  child: CustomElevatedButton(
                    title: '確認註冊',
                    theHeight: 46,
                    onPressed: (){

                        if (_formKey.currentState!.validate()) {
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //       backgroundColor: Colors.black26,
                          //       content: Text('資料填寫成功')),
                          // );

                          var userModel = context.read<UserModel>();
                          User user = User();
                          if(userModel.user!=null){
                            user = userModel.user!;
                          }
                          user.name = driverNameController.text;
                          user.nickName = nickNameController.text;
                          user.phone = phoneNumberController.text;
                          user.vehicalLicence = carPlateController.text;
                          user.idNumber = idNumberController.text;
                          if(_driverGender == DriverGender.male){
                            user.gender = '男';
                          }else{
                            user.gender = '女';
                          }
                          user.carModel = carModelController.text;
                          user.carColor = carColorController.text;
                          if(seatNumberController.text!='') {
                            user.numberSites = int.parse(seatNumberController.text);
                          }else{
                            user.numberSites = 4;
                          }
                          // user.carMemo = carMemoController.text;
                          // String userCarMemo = carMemoController.text;
                          // if(userCarMemo.contains('車上禁菸、檳榔')){
                          //   user.carMemo = carMemoController.text;
                          // } else {
                          //   user.carMemo = '車上禁菸、檳榔 ' + carMemoController.text;
                          // }

                          if(widget.isEdit) {
                            _putUpdateUserData(userModel.token!, user, user.isOnline!);
                          }else{
                            // _postCreateUser(user, widget.lineId);
                            if(dropdownValue!='----') {
                              _postCreateUser(user, phoneNumberController.text, pwdController.text);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('註冊中，請稍待~')));
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('車隊必須選擇！')));
                            }
                          }
                          // Navigator.pushAndRemoveUntil(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => const MyHomePage()), (Route<dynamic> route) => false, );
                        }},
                  ),
                ),
                widget.isEdit? const SizedBox():TextButton(onPressed: (){ Navigator.pop(context);}, child: const Text('返回上一頁',)),
                const SizedBox(height: 250)
              ],
            ),
          ),
        ));
  }

  validatorTextFormField(String title, String hintText, TextEditingController controller, bool isObscure, bool enabled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            height: 62,
            child: TextFormField(
              obscureText: isObscure,
              enabled: enabled,
              readOnly: !enabled, // 為了讓不可編輯時仍可顯示下底線
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '此欄必填';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 18,
                color: enabled ? Colors.black : Colors.grey, // 不可編輯時文字顏色變灰
              ),
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                disabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54), // 不可編輯時顯示下底線
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  registerTextField(String title, String hintText, TextEditingController controller, bool enabled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 46,
            child: TextField(
              enabled: enabled,
              readOnly: !enabled, // 為了讓不可編輯時仍可顯示下底線
              style: TextStyle(
                fontSize: 18,
                color: enabled ? Colors.black : Colors.grey, // 不可編輯時文字顏色變灰
              ),
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                disabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54), // 不可編輯時顯示下底線
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  getDriverGender(bool isEditable) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('性別', style: TextStyle(height: 1.8)),
          Row(
            children: [
              Radio<DriverGender>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: DriverGender.male,
                groupValue: _driverGender,
                onChanged: isEditable
                    ? (DriverGender? value) {
                  setState(() {
                    _driverGender = value;
                  });
                }
                    : null, // 當 isEditable 為 false 時，禁用按鈕
                activeColor: Colors.black54,
              ),
              Text(
                '男',
                style: TextStyle(
                  color: isEditable ? Colors.black : Colors.grey, // 顯示灰色文字
                ),
              ),
              const SizedBox(width: 20),
              Radio<DriverGender>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: DriverGender.female,
                groupValue: _driverGender,
                onChanged: isEditable
                    ? (DriverGender? value) {
                  setState(() {
                    _driverGender = value;
                  });
                }
                    : null, // 當 isEditable 為 false 時，禁用按鈕
                activeColor: Colors.black54,
              ),
              Text(
                '女',
                style: TextStyle(
                  color: isEditable ? Colors.black : Colors.grey, // 顯示灰色文字
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future _putUpdateUserData(String token, User user, bool isOnline) async {
    String path = ServerApi.PATH_USER_DATA;
    print(token);
    print(user.phone);

    try {
      Map queryParameters = {
        'phone': user.phone,
        'name': user.name,
        'nick_name':user.nickName,
        'vehicalLicence': user.vehicalLicence,
        'idNumber': user.idNumber,
        'gender': user.gender,
        'car_color': user.carColor,
        'number_sites': user.numberSites,
        'is_online': isOnline,
        // 'car_memo':user.carMemo,
      };

      if(dropdownValue!="----"){
        int carTeamId = carTeams.where((element) => element.name == dropdownValue).first.id!;
        print('carTeamId $carTeamId');
        queryParameters['car_team'] = carTeamId;
      }

      final response = await http.put(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
          body: jsonEncode(queryParameters)
      );
      print(response.body);

      if(response.statusCode == 200){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('資料更新成功~')));
      }else{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('資料更新失敗!')));
      }

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      User theUser = User.fromJson(map);

      var userModel = context.read<UserModel>();
      userModel.setUser(theUser);

      Navigator.pop(context);
    } catch (e) {
      print(e);
      return "error";
    }
  }

  // Future _postCreateUser(User user, String lineId) async{
  Future _postCreateUser(User user, String phone, String password) async{

    String path = ServerApi.PATH_CREATE_USER;

    int carTeamId = carTeams.where((element) => element.name == dropdownValue).first.id!;
    print('carTeamId $carTeamId');

    // try {
      Map queryParameters = {
        'phone': user.phone,
        'name': user.name,
        'nick_name': user.nickName,
        'vehicalLicence': user.vehicalLicence,
        'idNumber': user.idNumber,
        'gender': user.gender,
        'car_color': user.carColor,
        'number_sites': user.numberSites,
        // 'line_id': lineId,
        // 'car_memo':user.carMemo,
        // 'password': "00000",
        'password': password,
        'car_team':carTeamId,
      };

      final response = await http.post(ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            // 'Authorization': 'Token $token',
          },
          body: jsonEncode(queryParameters)
      );

      print(response.statusCode);
      print(response.body);
      _printLongString(response.body);

      if(response.statusCode == 201) {
        var userModel = context.read<UserModel>();
        // Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
        // User theUser = User.fromJson(map);

        // String token = await _getUserToken(lineId);
        String token = await _getUserToken(phone, password);
        userModel.token = token;

        User? theUser = await _getUserData(token);
        userModel.setUser(theUser!);

        Navigator.of(context).pushNamed('/main');
      }else{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未成功註冊~')));
      }
    // } catch (e) {
    //   print(e);
    //   return "error";
    // }

  }

  // Future<String> _getUserToken(String line_id) async {
  Future<String> _getUserToken(String phone, String password) async {
      String path = ServerApi.PATH_USER_TOKEN;
    try {
      Map queryParameters = {
        'phone': phone,
        'password': password,
        // 'phone': '0000000000',
        // 'password': '00000',
        // 'line_id': line_id,
      };

      final response = await http.post(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(queryParameters)
      );

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['token']!=null){
        String token = map['token'];
        return token;
      }else{
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("無法取得Token！"),));
        return "error";
      }
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future<User?> _getUserData(String token) async {
    String path = ServerApi.PATH_USER_DATA;
    try {
      final response = await http.get(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );

      print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      User theUser = User.fromJson(map);

      return theUser;

    } catch (e) {
      print(e);

      // return null;
      // return User(phone: '0000000000', name: 'test test', isGottenLineId: false, token: '4b36f687579602c485093c868b6f2d8f24be74e2',isOwner: false);

    }
    return null;
  }

  Future getCarTeams() async{
    String path = ServerApi.PATH_CAR_TEAMS;
    try {
      final response = await http.get(ServerApi.standard(
        path: path,
      ));

      if (response.statusCode == 200) {
        List<dynamic> parsedListJson = json.decode(utf8.decode(response.body.runes.toList()));
        setState(() {
          carTeams = List<CarTeam>.from(parsedListJson.map((i) => CarTeam.fromJson(i)));

          for(var carTeam in carTeams){
            print(carTeam.name!);
            carTeamsString.add(carTeam.name!);
          }
          dropdownValue = carTeamsString.first;

        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }
}

