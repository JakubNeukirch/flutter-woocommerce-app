//  Label StoreMax
//
//  Created by Anthony Gordon.
//  2021, WooSignal Ltd. All rights reserved.
//

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/models/billing_details.dart';
import 'package:flutter_app/app/models/cart.dart';
import 'package:flutter_app/app/models/cart_line_item.dart';
import 'package:flutter_app/app/models/checkout_session.dart';
import 'package:flutter_app/app/models/default_shipping.dart';
import 'package:flutter_app/app/models/payment_type.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/bootstrap/app_helper.dart';
import 'package:flutter_app/bootstrap/enums/symbol_position_enums.dart';
import 'package:flutter_app/bootstrap/shared_pref/shared_key.dart';
import 'package:flutter_app/config/app_currency.dart';
import 'package:flutter_app/config/app_payment_gateways.dart';
import 'package:flutter_app/resources/widgets/no_results_for_products_widget.dart';
import 'package:flutter_app/resources/widgets/woosignal_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:nylo_framework/helpers/helper.dart';
import 'package:platform_alert_dialog/platform_alert_dialog.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:status_alert/status_alert.dart';
import 'package:woosignal/models/response/products.dart';
import 'package:woosignal/models/response/tax_rate.dart';
import 'package:woosignal/woosignal.dart';

Future<User> getUser() async =>
    (await NyStorage.read<User>(SharedKey.authUser, model: User()));

appWooSignal(Function(WooSignal) api) async {
  WooSignal wooSignal = await WooSignal.getInstance(config: {
    "appKey": getEnv('APP_KEY'),
    "debugMode": getEnv('APP_DEBUG', defaultValue: true)
  });
  return await api(wooSignal);
}

List<PaymentType> getPaymentTypes() =>
    paymentTypeList.where((v) => v != null).toList();

PaymentType addPayment(
        {@required int id,
        @required String name,
        @required String desc,
        @required String assetImage,
        @required Function pay}) =>
    app_payment_gateways.contains(name)
        ? PaymentType(
            id: id,
            name: name,
            desc: desc,
            assetImage: assetImage,
            pay: pay,
          )
        : null;

showStatusAlert(context,
    {@required String title, String subtitle, IconData icon, int duration}) {
  StatusAlert.show(
    context,
    duration: Duration(seconds: duration ?? 2),
    title: title,
    subtitle: subtitle,
    configuration: IconConfiguration(icon: icon ?? Icons.done, size: 50),
  );
}

enum ToastNotificationStyleType {
  SUCCESS,
  WARNING,
  INFO,
  DANGER,
}

class ToastNotificationStyleMetaHelper {
  static ToastMeta getValue(ToastNotificationStyleType style) {
    switch (style) {
      case ToastNotificationStyleType.SUCCESS:
        return ToastMeta.success(action: () {
          ToastManager().dismissAll(showAnim: true);
        });
      case ToastNotificationStyleType.WARNING:
        return ToastMeta.warning(action: () {
          ToastManager().dismissAll(showAnim: true);
        });
      case ToastNotificationStyleType.INFO:
        return ToastMeta.info(action: () {
          ToastManager().dismissAll(showAnim: true);
        });
      case ToastNotificationStyleType.DANGER:
        return ToastMeta.danger(action: () {
          ToastManager().dismissAll(showAnim: true);
        });
      default:
        return ToastMeta.success(action: () {
          ToastManager().dismissAll(showAnim: true);
        });
    }
  }
}

class ToastMeta {
  Widget icon;
  String title;
  String description;
  Color color;
  Function action;
  Duration duration;
  ToastMeta(
      {this.icon,
      this.title,
      this.description,
      this.color,
      this.action,
      this.duration = const Duration(seconds: 2)});

  ToastMeta.success(
      {this.icon = const Icon(Icons.check, color: Colors.white, size: 30),
      this.title = "Success",
      this.description = "",
      this.color = Colors.green,
      this.action,
      this.duration = const Duration(seconds: 5)});
  ToastMeta.info(
      {this.icon = const Icon(Icons.info, color: Colors.white, size: 30),
      this.title = "",
      this.description = "",
      this.color = Colors.teal,
      this.action,
      this.duration = const Duration(seconds: 5)});
  ToastMeta.warning(
      {this.icon =
          const Icon(Icons.error_outline, color: Colors.white, size: 30),
      this.title = "Oops!",
      this.description = "",
      this.color = Colors.orange,
      this.action,
      this.duration = const Duration(seconds: 6)});
  ToastMeta.danger(
      {this.icon = const Icon(Icons.warning, color: Colors.white, size: 30),
      this.title = "Oops!",
      this.description = "",
      this.color = Colors.redAccent,
      this.action,
      this.duration = const Duration(seconds: 7)});
}

showToastNotification(BuildContext context,
    {ToastNotificationStyleType style,
    String title,
    IconData icon,
    String description = "",
    Duration duration}) {
  ToastMeta toastMeta = ToastNotificationStyleMetaHelper.getValue(style);
  toastMeta.title = trans(context, toastMeta.title);
  if (title != null) {
    toastMeta.title = title;
  }
  toastMeta.description = description;

  Widget _icon = toastMeta.icon;
  if (icon != null) {
    _icon = Icon(icon, color: Colors.white);
  }

  showToastWidget(
    InkWell(
      onTap: () => ToastManager().dismissAll(showAnim: true),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.0),
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        height: 100,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          color: toastMeta.color,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Pulse(
              child: Container(
                child: Center(
                  child: IconButton(
                    onPressed: () {},
                    icon: _icon,
                    padding: EdgeInsets.only(right: 16),
                  ),
                ),
              ),
              infinite: true,
              duration: Duration(milliseconds: 1500),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    toastMeta.title,
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    toastMeta.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    context: context,
    isIgnoring: false,
    position: StyledToastPosition.top,
    animation: StyledToastAnimation.slideFromTopFade,
    duration: duration ?? toastMeta.duration,
  );
}

String parseHtmlString(String htmlString) {
  var document = parse(htmlString);
  return parse(document.body.text).documentElement.text;
}

String moneyFormatter(double amount) {
  MoneyFormatter fmf = MoneyFormatter(
    amount: amount,
    settings: MoneyFormatterSettings(
      symbol: AppHelper.instance.appConfig.currencyMeta.symbolNative,
    ),
  );
  if (app_currency_symbol_position == SymbolPositionType.left) {
    return fmf.output.symbolOnLeft;
  } else if (app_currency_symbol_position == SymbolPositionType.right) {
    return fmf.output.symbolOnRight;
  }
  return fmf.output.symbolOnLeft;
}

String formatDoubleCurrency({@required double total}) {
  return moneyFormatter(total);
}

String formatStringCurrency({@required String total}) {
  double tmpVal = 0;
  if (total != null && total != "") {
    tmpVal = parseWcPrice(total);
  }
  return moneyFormatter(tmpVal);
}

String workoutSaleDiscount(
    {@required String salePrice, @required String priceBefore}) {
  double dSalePrice = parseWcPrice(salePrice);
  double dPriceBefore = parseWcPrice(priceBefore);
  return ((dPriceBefore - dSalePrice) * (100 / dPriceBefore))
      .toStringAsFixed(0);
}

openBrowserTab({@required String url}) async {
  await FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: CustomTabsOptions(toolbarColor: Colors.white70));
}

EdgeInsets safeAreaDefault() => EdgeInsets.only(left: 16, right: 16, bottom: 8);

bool isNumeric(String str) {
  if (str == null) {
    return false;
  }
  return double.tryParse(str) != null;
}

checkout(
    TaxRate taxRate,
    Function(String total, BillingDetails billingDetails, Cart cart)
        completeCheckout) async {
  String cartTotal = await CheckoutSession.getInstance
      .total(withFormat: false, taxRate: taxRate);
  BillingDetails billingDetails = CheckoutSession.getInstance.billingDetails;
  Cart cart = Cart.getInstance;
  return await completeCheckout(cartTotal, billingDetails, cart);
}

double strCal({@required String sum}) {
  if (sum == null || sum == "") {
    return 0;
  }
  Parser p = Parser();
  Expression exp = p.parse(sum);
  ContextModel cm = ContextModel();
  return exp.evaluate(EvaluationType.REAL, cm);
}

Future<double> workoutShippingCostWC({@required String sum}) async {
  if (sum == null || sum == "") {
    return 0;
  }
  List<CartLineItem> cartLineItem = await Cart.getInstance.getCart();
  sum = sum.replaceAllMapped(defaultRegex(r'\[qty\]', strict: true), (replace) {
    return cartLineItem
        .map((f) => f.quantity)
        .toList()
        .reduce((i, d) => i + d)
        .toString();
  });

  String orderTotal = await Cart.getInstance.getSubtotal();

  sum = sum.replaceAllMapped(defaultRegex(r'\[fee(.*)]'), (replace) {
    if (replace.groupCount < 1) {
      return "()";
    }
    String newSum = replace.group(1);

    // PERCENT
    String percentVal = newSum.replaceAllMapped(
        defaultRegex(r'percent="([0-9\.]+)"'), (replacePercent) {
      if (replacePercent != null && replacePercent.groupCount >= 1) {
        String strPercentage = "( (" +
            orderTotal.toString() +
            " * " +
            replacePercent.group(1).toString() +
            ") / 100 )";
        double calPercentage = strCal(sum: strPercentage);

        // MIN
        String strRegexMinFee = r'min_fee="([0-9\.]+)"';
        if (defaultRegex(strRegexMinFee).hasMatch(newSum)) {
          String strMinFee =
              defaultRegex(strRegexMinFee).firstMatch(newSum).group(1) ?? "0";
          double doubleMinFee = double.parse(strMinFee);

          if (calPercentage < doubleMinFee) {
            return "(" + doubleMinFee.toString() + ")";
          }
          newSum = newSum.replaceAll(defaultRegex(strRegexMinFee), "");
        }

        // MAX
        String strRegexMaxFee = r'max_fee="([0-9\.]+)"';
        if (defaultRegex(strRegexMaxFee).hasMatch(newSum)) {
          String strMaxFee =
              defaultRegex(strRegexMaxFee).firstMatch(newSum).group(1) ?? "0";
          double doubleMaxFee = double.parse(strMaxFee);

          if (calPercentage > doubleMaxFee) {
            return "(" + doubleMaxFee.toString() + ")";
          }
          newSum = newSum.replaceAll(defaultRegex(strRegexMaxFee), "");
        }
        return "(" + calPercentage.toString() + ")";
      }
      return "";
    });

    percentVal = percentVal
        .replaceAll(
            defaultRegex(r'(min_fee=\"([0-9\.]+)\"|max_fee=\"([0-9\.]+)\")'),
            "")
        .trim();
    return percentVal;
  });

  return strCal(sum: sum);
}

Future<double> workoutShippingClassCostWC(
    {@required String sum, List<CartLineItem> cartLineItem}) async {
  if (sum == null || sum == "") {
    return 0;
  }
  sum = sum.replaceAllMapped(defaultRegex(r'\[qty\]', strict: true), (replace) {
    return cartLineItem
        .map((f) => f.quantity)
        .toList()
        .reduce((i, d) => i + d)
        .toString();
  });

  String orderTotal = await Cart.getInstance.getSubtotal();

  sum = sum.replaceAllMapped(defaultRegex(r'\[fee(.*)]'), (replace) {
    if (replace.groupCount < 1) {
      return "()";
    }
    String newSum = replace.group(1);

    // PERCENT
    String percentVal = newSum.replaceAllMapped(
        defaultRegex(r'percent="([0-9\.]+)"'), (replacePercent) {
      if (replacePercent != null && replacePercent.groupCount >= 1) {
        String strPercentage = "( (" +
            orderTotal.toString() +
            " * " +
            replacePercent.group(1).toString() +
            ") / 100 )";
        double calPercentage = strCal(sum: strPercentage);

        // MIN
        String strRegexMinFee = r'min_fee="([0-9\.]+)"';
        if (defaultRegex(strRegexMinFee).hasMatch(newSum)) {
          String strMinFee =
              defaultRegex(strRegexMinFee).firstMatch(newSum).group(1) ?? "0";
          double doubleMinFee = double.parse(strMinFee);

          if (calPercentage < doubleMinFee) {
            return "(" + doubleMinFee.toString() + ")";
          }
          newSum = newSum.replaceAll(defaultRegex(strRegexMinFee), "");
        }

        // MAX
        String strRegexMaxFee = r'max_fee="([0-9\.]+)"';
        if (defaultRegex(strRegexMaxFee).hasMatch(newSum)) {
          String strMaxFee =
              defaultRegex(strRegexMaxFee).firstMatch(newSum).group(1) ?? "0";
          double doubleMaxFee = double.parse(strMaxFee);

          if (calPercentage > doubleMaxFee) {
            return "(" + doubleMaxFee.toString() + ")";
          }
          newSum = newSum.replaceAll(defaultRegex(strRegexMaxFee), "");
        }
        return "(" + calPercentage.toString() + ")";
      }
      return "";
    });

    percentVal = percentVal
        .replaceAll(
            defaultRegex(r'(min_fee=\"([0-9\.]+)\"|max_fee=\"([0-9\.]+)\")'),
            "")
        .trim();
    return percentVal;
  });

  return strCal(sum: sum);
}

RegExp defaultRegex(
  String pattern, {
  bool strict,
}) {
  return new RegExp(
    pattern,
    caseSensitive: strict ?? false,
    multiLine: false,
  );
}

bool isEmail(String em) {
  String p =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regExp = new RegExp(p);
  return regExp.hasMatch(em);
}

// 6 LENGTH, 1 DIGIT
bool validPassword(String pw) {
  String p = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$';
  RegExp regExp = new RegExp(p);
  return regExp.hasMatch(pw);
}

navigatorPush(BuildContext context,
    {@required String routeName,
    Object arguments,
    bool forgetAll = false,
    int forgetLast}) {
  if (forgetAll) {
    Navigator.of(context).pushNamedAndRemoveUntil(
        routeName, (Route<dynamic> route) => false,
        arguments: arguments ?? null);
  }
  if (forgetLast != null) {
    int count = 0;
    Navigator.of(context).popUntil((route) {
      return count++ == forgetLast;
    });
  }
  Navigator.of(context).pushNamed(routeName, arguments: arguments ?? null);
}

PlatformDialogAction dialogAction(BuildContext context,
    {@required title, ActionType actionType, Function() action}) {
  return PlatformDialogAction(
    actionType: actionType ?? ActionType.Default,
    child: Text(title ?? ""),
    onPressed: action ??
        () {
          Navigator.of(context).pop();
        },
  );
}

showPlatformAlertDialog(BuildContext context,
    {String title,
    String subtitle,
    List<PlatformDialogAction> actions,
    bool showDoneAction = true}) {
  if (showDoneAction) {
    actions
        .add(dialogAction(context, title: trans(context, "Done"), action: () {
      Navigator.of(context).pop();
    }));
  }
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return PlatformAlertDialog(
        title: Text(title ?? ""),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(subtitle ?? ""),
            ],
          ),
        ),
        actions: actions,
      );
    },
  );
}

DateTime parseDateTime(String strDate) => DateTime.parse(strDate);

DateFormat formatDateTime(String format) => DateFormat(format);

String dateFormatted({@required String date, @required String formatType}) =>
    formatDateTime(formatType).format(parseDateTime(date));

enum FormatType {
  DateTime,
  Date,
  Time,
}

String formatForDateTime(FormatType formatType) {
  switch (formatType) {
    case FormatType.Date:
      {
        return "yyyy-MM-dd";
      }
    case FormatType.DateTime:
      {
        return "dd-MM-yyyy hh:mm a";
      }
    case FormatType.Time:
      {
        return "hh:mm a";
      }
    default:
      {
        return "";
      }
  }
}

double parseWcPrice(String price) => (double.tryParse(price) ?? 0);

void appLogOutput(dynamic message) =>
    (getEnv('APP_DEBUG', defaultValue: true) ? NyLogger.debug(message) : null);

Widget refreshableScroll(context,
    {@required refreshController,
    @required VoidCallback onRefresh,
    @required VoidCallback onLoading,
    @required List<Product> products,
    @required onTap,
    key}) {
  return SmartRefresher(
    enablePullDown: true,
    enablePullUp: true,
    footer: CustomFooter(
      builder: (BuildContext context, LoadStatus mode) {
        Widget body;
        if (mode == LoadStatus.idle) {
          body = Text(trans(context, "pull up load"));
        } else if (mode == LoadStatus.loading) {
          body = CupertinoActivityIndicator();
        } else if (mode == LoadStatus.failed) {
          body = Text(trans(context, "Load Failed! Click retry!"));
        } else if (mode == LoadStatus.canLoading) {
          body = Text(trans(context, "release to load more"));
        } else {
          body = Text(trans(context, "No more products"));
        }
        return Container(
          height: 55.0,
          child: Center(child: body),
        );
      },
    ),
    controller: refreshController,
    onRefresh: onRefresh,
    onLoading: onLoading,
    child: (products.length != null && products.length > 0
        ? StaggeredGridView.countBuilder(
            crossAxisCount: 2,
            itemCount: products.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 200,
                child: ProductItemContainer(
                  index: (index),
                  product: products[index],
                  onTap: onTap,
                ),
              );
            },
            staggeredTileBuilder: (int index) => new StaggeredTile.fit(1),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
          )
        : NoResultsForProductsWidget()),
  );
}

class UserAuth {
  UserAuth._privateConstructor();
  static final UserAuth instance = UserAuth._privateConstructor();

  String redirect = "/home";
}

Future<List<DefaultShipping>> getDefaultShipping(BuildContext context) async {
  String data = await DefaultAssetBundle.of(context)
      .loadString("public/assets/json/default_shipping.json");
  dynamic dataJson = json.decode(data);
  List<DefaultShipping> shipping = [];

  dataJson.forEach((key, value) {
    DefaultShipping defaultShipping =
        DefaultShipping(code: key, country: value['country'], states: []);
    if (value['states'] != null) {
      value['states'].forEach((key1, value2) {
        defaultShipping.states
            .add(DefaultShippingState(code: key1, name: value2));
      });
    }
    shipping.add(defaultShipping);
  });
  return shipping;
}

String truncateString(String data, int length) {
  return (data.length >= length) ? '${data.substring(0, length)}...' : data;
}
