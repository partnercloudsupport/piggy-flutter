import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:piggy_flutter/model/transaction.dart';
import 'package:piggy_flutter/model/transaction_group_item.dart';
import 'package:piggy_flutter/ui/page/transaction/transaction_detail.dart';
import 'package:piggy_flutter/ui/widgets/common/message_placeholder.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionGroupItem> transactions;
  final Stream<bool> isLoading;
  final DateFormat formatter = DateFormat("EEE, MMM d, ''yy");

  TransactionList({Key key, this.transactions, this.isLoading})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactions == null) {
      return Center(child: CircularProgressIndicator());
    } else {
      if (transactions.length > 0) {
        List<Widget> groupedTransactionList = [];
        if (isLoading != null) {
          groupedTransactionList.add(_loadingInfo(isLoading));
        }

        groupedTransactionList.addAll(transactions
            .map((item) => buildGroupedTransactionTile(context, item)));
        return ListView(
          children: groupedTransactionList.toList(),
        );
      } else {
        return MessagePlaceholder();
      }
    }
  }

  Widget _loadingInfo(Stream<bool> isLoading) {
    return StreamBuilder<bool>(
      stream: isLoading,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data) {
          return LinearProgressIndicator();
        } else {
          return Container();
        }
      },
    );
  }

  buildGroupedTransactionTile(BuildContext context, TransactionGroupItem item) {
    Iterable<Widget> transactionList = item.transactions.map((transaction) =>
        buildTransactionList(context, transaction, item.groupby));

    return ExpansionTile(
        key: PageStorageKey(item.title),
        title: Text(item.title),
        initiallyExpanded: true,
        backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
        children: transactionList.toList());
  }

  buildTransactionList(BuildContext context, Transaction transaction,
      TransactionsGroupBy groupBy) {
    return MergeSemantics(
      child: new ListTile(
          dense: true,
          title: Text(groupBy == TransactionsGroupBy.Date
              ? transaction.categoryName
              : formatter.format(DateTime.parse(transaction.transactionTime))),
          subtitle: new Text("${transaction.description}\n${transaction
              .creatorUserName}'s ${transaction.accountName}"),
          isThreeLine: true,
          trailing: Text('${transaction.amount
              .toString()} ${transaction.accountCurrencySymbol}'),
          leading: CircleAvatar(
            child: Text(
              groupBy == TransactionsGroupBy.Category
                  ? DateTime.parse(transaction.transactionTime).day.toString()
                  : transaction.categoryName[0],
              style: TextStyle(color: transaction.amount > 0 ? Colors.white :Colors.black),
            ),
            backgroundColor: transaction.amount > 0
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          onTap: () {
            Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (BuildContext context) => new TransactionDetailPage(
                        transaction: transaction,
                      ),
                  fullscreenDialog: true,
                ));
          }),
    );
  }
}
