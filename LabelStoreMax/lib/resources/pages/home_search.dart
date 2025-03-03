//  Label StoreMax
//
//  Created by Anthony Gordon.
//  2021, WooSignal Ltd. All rights reserved.
//

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import 'package:flutter/material.dart';
import 'package:flutter_app/bootstrap/app_helper.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/widgets/buttons.dart';
import 'package:nylo_framework/helpers/helper.dart';

import '../widgets/woosignal_ui.dart';

class HomeSearchPage extends StatefulWidget {
  HomeSearchPage();

  @override
  _HomeSearchPageState createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<HomeSearchPage> {
  _HomeSearchPageState();

  TextEditingController _txtSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  _actionSearch() {
    Navigator.pushNamed(context, "/product-search",
            arguments: _txtSearchController.text)
        .then((search) {
      if (AppHelper.instance.themeType != "notic") {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: StoreLogo(height: 55),
        centerTitle: true,
      ),
      body: SafeArea(
        minimum: safeAreaDefault(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Icon(Icons.search, size: 36),
              margin: EdgeInsets.only(bottom: 20),
            ),
            TextField(
              controller: _txtSearchController,
              style: Theme.of(context).textTheme.headline3,
              keyboardType: TextInputType.text,
              autocorrect: false,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PrimaryButton(
                title: trans(context, "Search"),
                action: _actionSearch,
              ),
            )
          ],
        ),
      ),
    );
  }
}
