import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

class AppIcons {
  AppIcons._();

  // Nav bar
  static String get home => Reicon.outline.home;
  static String get calendar => Reicon.outline.calendar;
  static String get wallet => Reicon.outline.wallet;
  static String get gallery => Reicon.outline.gallery;
  static String get hanger => Reicon.outline.hanger;

  // Actions
  static String get add => Reicon.outline.add;
  static String get minus => Reicon.outline.minus;
  static String get edit => Reicon.outline.edit;
  static String get trash => Reicon.outline.trash;
  static String get check => Reicon.outline.check;
  static String get close => Reicon.outline.x;
  static String get search => Reicon.outline.search;
  static String get copy => Reicon.outline.copy;
  static String get send => Reicon.outline.send;
  static String get link => Reicon.outline.link;
  static String get share => Reicon.outline.share;
  static String get logout => Reicon.outline.logout;
  static String get refresh => Reicon.outline.refresh;
  static String get more => Reicon.outline.more;
  static String get arrowLeft => Reicon.outline.arrowLeft;
  static String get arrowRight => Reicon.outline.arrowRight;
  static String get chevronLeft => Reicon.outline.chevronLeft;
  static String get chevronRight => Reicon.outline.chevronRight;
  static String get chevronDown => Reicon.outline.chevronDown;
  static String get filterFunnel => Reicon.outline.filter3;
  static String get eyeOn => Reicon.outline.eye;
  static String get eyeOff => Reicon.outline.eyeOff;
  static String get exportIcon => Reicon.outline.export;

  // Content / Categories
  static String get user => Reicon.outline.user;
  static String get people => Reicon.outline.people;
  static String get location => Reicon.outline.location;
  static String get building => Reicon.outline.building;
  static String get camera => Reicon.outline.camera;
  static String get music => Reicon.outline.music;
  static String get leaf => Reicon.outline.leaf;
  static String get envelope => Reicon.outline.envelope;
  static String get car => Reicon.outline.car;
  static String get heart => Reicon.outline.heart;
  static String get heartShine => Reicon.outline.heartShine;
  static String get heartLock => Reicon.outline.heartLock;
  static String get sparkle => Reicon.outline.sparkle;
  static String get sparkles => Reicon.outline.sparkles;
  static String get wand => Reicon.outline.wand;
  static String get store => Reicon.outline.store;
  static String get image => Reicon.outline.image;
  static String get imageSparkle => Reicon.outline.imageSparkle;
  static String get galleryAdd => Reicon.outline.galleryAdd;
  static String get receipt => Reicon.outline.receipt;
  static String get stickyNote => Reicon.outline.stickynote;
  static String get checklist => Reicon.outline.checklist;
  static String get warning => Reicon.outline.warning;
  static String get plate => Reicon.outline.plate;
  static String get document => Reicon.outline.document;
  static String get note => Reicon.outline.note;
  static String get calendarTick => Reicon.outline.calendarTick;
  static String get calendarEdit => Reicon.outline.calendarEdit;
  static String get calendarCheck => Reicon.outline.calendarCheck;

  // State / status
  static String get checkCircle => Reicon.outline.checkCircle;
  static String get closeCircle => Reicon.outline.closeCircle;
  static String get danger => Reicon.outline.danger;
  static String get record => Reicon.outline.record;
  static String get restart => Reicon.outline.restart;
  static String get messageCheck => Reicon.outline.messageCheck;

  // People / users
  static String get userAdd => Reicon.outline.userAdd;
  static String get heartFilled => Reicon.filled.heart;

  // Food / misc
  static String get forkKnife => Reicon.outline.forkKnife;
  static String get moreH => Reicon.outline.moreH;
  static String get cameraAlt => Reicon.outline.cameraAlt;
  static String get imageMinus => Reicon.outline.imageMinus;
  static String get musicNote => Reicon.outline.musicNote;
}

class AppIcon extends StatelessWidget {
  final String svgData;
  final double size;
  final Color? color;

  const AppIcon(this.svgData, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF191C1D);
    return SvgPicture.string(
      reiconSvg(svgData, size: size.ceil()),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
