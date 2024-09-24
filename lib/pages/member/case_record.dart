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

class CaseRecord extends StatefulWidget {
  const CaseRecord({Key? key}) : super(key: key);

  @override
  _CaseRecordState createState() => _CaseRecordState();
}

class _CaseRecordState extends State<CaseRecord> {

  late CaseDataGridSource _caseDataGridSource;
  late List<Case> userCases = <Case>[];


  @override
  void initState() {
    super.initState();
    _fetchUserCases();
    _caseDataGridSource = CaseDataGridSource(cases: userCases);

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
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              alignment: Alignment.centerLeft,
              child: Text(
                '近期接單：',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(
              child: getCasesTable(),
            ),
          ],
        ),
    );
  }

  getCasesTable() {
    return SfDataGrid(
      source: _caseDataGridSource,
      rowHeight: 40,
      headerRowHeight: 45,
      selectionMode: SelectionMode.single,
      columnWidthMode: ColumnWidthMode.fill,
      onSelectionChanging: (List<DataGridRow> addedRows, List<DataGridRow> removedRows) {
        final index = _caseDataGridSource.rows.indexOf(addedRows.last);
        Case theCase = userCases[index];
        showDialog(
          context: context,
          builder: (_) {
            return RecentOrderDetailDialog(theCase: theCase);
          },
        );
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
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
        GridColumn(
          columnName: 'onAddress',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '上車',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
        GridColumn(
          columnName: 'offAddress',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '下車',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
        GridColumn(
          columnName: 'caseMoney',
          label: Container(
            alignment: Alignment.center,
            child: const Text(
              '車資',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.primary, fontSize: 15),
            ),
          ),
        ),
      ],
    );
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



