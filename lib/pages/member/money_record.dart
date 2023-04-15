import 'dart:convert';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/config/serverApi.dart';
import 'package:flutter_taxi_chinghsien/models/user_store_money.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import 'recent_order_detail_dialog.dart';
import 'package:http/http.dart' as http;

class MoneyRecord extends StatefulWidget {
  const MoneyRecord({Key? key}) : super(key: key);

  @override
  _MoneyRecordState createState() => _MoneyRecordState();
}

class _MoneyRecordState extends State<MoneyRecord> {

  late CaseDataGridSource _caseDataGridSource;
  late StoreMoneyDataGridSource _storeMoneyDataGridSource;

  late List<UserStoreMoney> userMoneyRecords = <UserStoreMoney>[];
  late List<Case> userCases = <Case>[];

  int? left_money;

  @override
  void initState() {
    super.initState();
    _fetchStoreMoneys();
    _fetchUserCases();
    _fetchUserLeftMoney();
    _caseDataGridSource = CaseDataGridSource(cases: userCases);
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                  alignment:Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text('目前餘額：',style: Theme.of(context).textTheme.bodyText1,),
                      (left_money != null)?
                      Text(left_money.toString(), style: Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 26))
                      :
                      const Text('?'),
                      Text(' 元',style: Theme.of(context).textTheme.bodyText1,),
                    ],
                  )
              ),
              getStoreMoneyTable(),
              Container(
                  margin: const EdgeInsets.all(20),
                  alignment:Alignment.centerLeft,
                  child: Text('近期接單：',style: Theme.of(context).textTheme.bodyText1,)
              ),
              getCasesTable()
            ],
          ),
        ));
  }

  getStoreMoneyTable(){
    return SizedBox(
      height: 250,
      child: SfDataGrid(
          source:_storeMoneyDataGridSource,
          verticalScrollPhysics: const NeverScrollableScrollPhysics(),
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
                      style: TextStyle(color: AppColor.primary,fontSize: 15),
                    ))),
            GridColumn(
                columnName: 'increase_money',
                label: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      '入扣帳',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColor.primary,fontSize: 15),
                    )
                )
            ),
            GridColumn(
                columnName: 'user_left_money',
                label: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      '當時餘額',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColor.primary,fontSize: 15),
                    )
                )
            ),
            GridColumn(
                columnName: 'sum_money',
                label: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      '結算餘額',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColor.primary,fontSize: 15),
                    )
                )
            ),
          ]
      ),
    );
  }
  
  getCasesTable(){
    return SizedBox(
      height: 500,
      child: SfDataGrid(
        source:_caseDataGridSource,
        verticalScrollPhysics: const NeverScrollableScrollPhysics(),
        rowHeight: 40,
        headerRowHeight: 45,
        selectionMode: SelectionMode.single,
        columnWidthMode: ColumnWidthMode.fill,
        onSelectionChanging: (List<DataGridRow> addedRows, List<DataGridRow> removedRows){
            final index = _caseDataGridSource.rows.indexOf(addedRows.last);
            Case theCase = userCases[index];
            showDialog(
                context: context,
                builder: (_){
                  return RecentOrderDetailDialog(theCase: theCase);});
            return false;
          },
        columns: [
          GridColumn(
            columnName: 'date',
            label: Container(
                alignment: Alignment.center,
                child: const Text(
                  '日期',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColor.primary,fontSize: 15),
                ))),
          GridColumn(
              columnName: 'onAddress',
              label: Container(
                  // padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: const Text(
                    '上車',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColor.primary,fontSize: 15),
                  ))),
          GridColumn(
              columnName: 'offAddress',
              label: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    '下車',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColor.primary,fontSize: 15),
                  ))),
          GridColumn(
              columnName: 'caseMoney',
              label: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    '車資',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColor.primary,fontSize: 15),
                  ))),
        ]
      ),
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

  Future _fetchUserCases() async {
    var userModel = context.read<UserModel>();
    if(userModel.token != null){
      String path = ServerApi.PATH_USER_CASE;
      try {
        final response = await http.get(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'token ${userModel.token}'
          },
        );

        List body = json.decode(utf8.decode(response.body.runes.toList()));
        userCases = body.map((value) => Case.fromJson(value)).toList();
        _caseDataGridSource = CaseDataGridSource(cases: userCases);
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

class CaseDataGridSource extends DataGridSource {
  CaseDataGridSource({required List<Case> cases}) {
    dataGridRows = cases.map<DataGridRow>((dataGridRow) =>
        DataGridRow(cells: [
              DataGridCell<String>(columnName: 'date', value: dataGridRow.createTime.toString().substring(5,10)),
              DataGridCell<String>(columnName: 'onAddress', value: dataGridRow.onAddress),
              DataGridCell<String>(columnName: 'offAddress', value: dataGridRow.offAddress),
              DataGridCell<int>(columnName: 'caseMoney', value: dataGridRow.caseMoney),
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



