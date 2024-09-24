import 'dart:convert';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/config/serverApi.dart';
import 'package:flutter_taxi_chinghsien/models/user_store_money.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../color.dart';
import '../../notifier_models/user_model.dart';
import 'package:http/http.dart' as http;

class MoneyRecord extends StatefulWidget {
  const MoneyRecord({Key? key}) : super(key: key);

  @override
  _MoneyRecordState createState() => _MoneyRecordState();
}

class _MoneyRecordState extends State<MoneyRecord> {

  late StoreMoneyDataGridSource _storeMoneyDataGridSource;
  late List<UserStoreMoney> userMoneyRecords = <UserStoreMoney>[];

  int? left_money;

  @override
  void initState() {
    super.initState();
    _fetchStoreMoneys();
    _fetchUserLeftMoney();
    _storeMoneyDataGridSource = StoreMoneyDataGridSource(storeMoneys: userMoneyRecords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title:
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 45, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image:AssetImage('images/logo.png',),
                        fit:BoxFit.scaleDown),),
                  height: 25,
                  width: 40,
                ),
                // Icon(FontAwesomeIcons.taxi),
                const SizedBox(width: 10,),
                const Text('24h派車'),
              ],
            ),
          )

          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(0,10,10,10),
          //     child: IconButton(
          //         onPressed: (){},
          //         icon: const Icon(Icons.notifications_outlined)),)],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    '目前餘額：',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (left_money != null)
                    Text(
                      left_money.toString(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 26),
                    )
                  else
                    const Text('?'),
                  Text(
                    ' 元',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: getStoreMoneyTable(),
            ),
          ],
        ),
    );
  }

  getStoreMoneyTable() {
    return SfDataGrid(
      source: _storeMoneyDataGridSource,
      rowHeight: 40,
      headerRowHeight: 45,
      selectionMode: SelectionMode.none,
      columnWidthMode: ColumnWidthMode.fill,
      columns: [
        GridColumn(
          columnName: 'date',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '日期',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
        GridColumn(
          columnName: 'increase_money',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '入扣帳',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
        GridColumn(
          columnName: 'user_left_money',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '當時餘額',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
        GridColumn(
          columnName: 'sum_money',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '結算餘額',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Future _fetchUserLeftMoney() async{
    var userModel = context.read<UserModel>();
    if(userModel.token != null){
      String path = ServerApi.PATH_USER_LEFT_MONEY;
      try {
        final response = await http.get(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'token ${userModel.token}'
          },
        );

        Map body = json.decode(response.body);
        print(body['left_money']);

        if(body['left_money']!=null){
          left_money = body['left_money'];
          setState(() {});
        }

      } catch (e) {
        print(e);
      }
    }else{
      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
    }
  }

  Future _fetchStoreMoneys() async {
    var userModel = context.read<UserModel>();
    if(userModel.token != null){
      String path = ServerApi.PATH_STORE_MONEYS;
      try {
        final response = await http.get(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'token ${userModel.token}'
          },
        );

        List body = json.decode(utf8.decode(response.body.runes.toList()));
        userMoneyRecords = body.map((value) => UserStoreMoney.fromJson(value)).toList();
        _storeMoneyDataGridSource = StoreMoneyDataGridSource(storeMoneys: userMoneyRecords);
        setState(() {});

        // }
      } catch (e) {
        print(e);
      }
    }else{
      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
    }
  }

}

class StoreMoneyDataGridSource extends DataGridSource {
  StoreMoneyDataGridSource({required List<UserStoreMoney> storeMoneys}) {
    dataGridRows = storeMoneys.map<DataGridRow>((dataGridRow) =>
        DataGridRow(cells: [
          DataGridCell<String>(columnName: 'date', value: dataGridRow.date.toString().substring(5,10)),
          DataGridCell<int>(columnName: 'increase_money', value: dataGridRow.increaseMoney),
          DataGridCell<int>(columnName: 'user_left_money', value: dataGridRow.userLeftMoney),
          DataGridCell<int>(columnName: 'sum_money', value: dataGridRow.sumMoney),
        ])
    ).toList();
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
          return Container(
              alignment: Alignment.center,
              child: Text(
                dataGridCell.value.toString(),
                overflow: TextOverflow.ellipsis,
              ));
        }).toList());
  }
}



