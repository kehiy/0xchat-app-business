import 'package:flutter/material.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';
import 'package:ox_common/widgets/common_image.dart';
import 'package:chatcore/chat-core.dart';
import 'package:lpinyin/lpinyin.dart';

const List<String> ALPHAS_INDEX = ["☆","A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"];

enum ContactType {
  contact,
  group,
}

class ContactChoosePage<T> extends StatefulWidget {
  final ContactType? contactType;
  final String? title;
  final String? searchBarHintText;
  const ContactChoosePage({super.key, this.contactType, this.title, this.searchBarHintText});

  @override
  State<ContactChoosePage<T>> createState() => _ContactChoosePageState<T>();
}

class _ContactChoosePageState<T> extends State<ContactChoosePage<T>> {
  List<T> _contactList = [];
  final List<T> _selectedContactList = [];
  final ValueNotifier<bool> _isClear = ValueNotifier(false);
  final TextEditingController _controller = TextEditingController();
  final Map<String, List<T>> _groupedContactList = {};
  Map<String, List<T>> _filteredContactList = {};

  List<T> get selectedContactList=> _selectedContactList;

  @override
  void initState() {
    super.initState();
    _initializeContactList();
    _controller.addListener(() {
      if (_controller.text.isNotEmpty) {
        _isClear.value = true;
      } else {
        _isClear.value = false;
      }
    });
  }

  void _initializeContactList() {
    if (widget.contactType == ContactType.contact) {
      _contactList = Contacts.sharedInstance.allContacts.values.toList() as List<T>;
    } else {
      _contactList = Groups.sharedInstance.myGroups.values.toList() as List<T>;
    }
  }

  groupedUser(){
    for (var v in ALPHAS_INDEX) {
      _groupedContactList[v] = [];
    }
    Map<UserDB, String> pinyinMap = <UserDB, String>{};
    // for (var user in _contactList) {
    //   String nameToConvert = user.nickName != null && user.nickName!.isNotEmpty ? user.nickName! : (user.name ?? '');
    //   String pinyin = PinyinHelper.getFirstWordPinyin(nameToConvert);
    //   pinyinMap[user] = pinyin;
    // }
    _contactList.sort((v1, v2) {
      return pinyinMap[v1]!.compareTo(pinyinMap[v2]!);
    });

    for (var item in _contactList) {
      var firstLetter = pinyinMap[item]![0].toUpperCase();
      if (!ALPHAS_INDEX.contains(firstLetter)) {
        firstLetter = '#';
      }
      _groupedContactList[firstLetter]?.add(item);
    }

    _groupedContactList.removeWhere((key, value) => value.isEmpty);
    _filteredContactList = _groupedContactList;
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColor.color190,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(Adapt.px(20)),
            topLeft: Radius.circular(Adapt.px(20)),
          ),
        ),
        child: Container(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildAppBar(),
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: _contactList.length,
            itemBuilder: (BuildContext context, int index) {
              // return _buildUserItem(_contactList[index]);
            },
          ),
        ),
      ],
    ).setPadding(EdgeInsets.symmetric(horizontal: Adapt.px(24)));
  }

  String buildTitle() {
    return widget.title ?? '';
  }

  Widget _buildTitleWidget() {
    return Text(
      buildTitle(),
      style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: Adapt.px(16),
          color: ThemeColor.color0),
    );
  }

  Widget buildEditButton() {
    return IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        icon: CommonImage(
          iconName: 'icon_done.png',
          width: Adapt.px(24),
          height: Adapt.px(24),
          useTheme: true,
        ),
        onPressed: () {
        }
    );
  }

  Widget _buildAppBar(){
    return SizedBox(
      height: Adapt.px(57),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            child: CommonImage(
              iconName: "icon_back_left_arrow.png",
              width: Adapt.px(24),
              height: Adapt.px(24),
              useTheme: true,
            ),
            onTap: () {
              OXNavigator.pop(context);
            },
          ),
          _buildTitleWidget(),
          buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ThemeColor.color180,
        ),
        height: Adapt.px(48),
        padding: EdgeInsets.symmetric(horizontal: Adapt.px(16)),
        margin: EdgeInsets.symmetric(vertical: Adapt.px(16)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  fontSize: Adapt.px(16),
                  fontWeight: FontWeight.w600,
                  height: Adapt.px(22.4) / Adapt.px(16),
                  color: ThemeColor.color0,
                ),
                decoration: InputDecoration(
                  icon: CommonImage(
                    iconName: 'icon_search.png',
                    width: Adapt.px(24),
                    height: Adapt.px(24),
                    fit: BoxFit.fill,
                  ),
                  // hintText: widget.searchBarHintText ?? 'search'.localized(),
                  hintText: widget.searchBarHintText ?? '',
                  hintStyle: TextStyle(
                    fontSize: Adapt.px(16),
                    fontWeight: FontWeight.w400,
                    height: Adapt.px(22.4) / Adapt.px(16),
                    color: ThemeColor.color160,),
                  border: InputBorder.none,),
                onChanged: _handlingSearch,
              ),
            ),
            ValueListenableBuilder(
              builder: (context, value, child) {
                return _isClear.value
                    ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {
                      _filteredContactList = _groupedContactList;
                    });
                  },
                  child: CommonImage(
                    iconName: 'icon_textfield_close.png',
                    width: Adapt.px(16),
                    height: Adapt.px(16),
                  ),
                )
                    : Container();
              },
              valueListenable: _isClear,
            ),
          ],
        ));
  }

  Widget _buildUserItem(UserDB user){
    return Container();
  }

  void _handlingSearch(String searchQuery){
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

