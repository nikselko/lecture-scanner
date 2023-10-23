import 'package:flutter/material.dart';

class AnimatedSquare extends StatefulWidget {
  AnimatedSquare({
    this.width,
    this.height,
    this.widgetSize,
    this.padding,
    this.onScan,
    this.animationDuration,
    this.squareBorderColor,
    this.squareColor,
    this.borderWidth,
    Key key,
  }) : super(key: key);
  final double width;
  final double height;
  final EdgeInsets padding;
  final Size widgetSize;
  final Function(String str) onScan;
  final Duration animationDuration;
  final Color squareBorderColor;
  final Color squareColor;
  final double borderWidth;
  @override
  AnimatedSquareState createState() => AnimatedSquareState();
}

class AnimatedSquareState extends State<AnimatedSquare>
    with TickerProviderStateMixin {
  double _fraction = 0.0;
  List<Offset> from = List<Offset>();
  List<Offset> to = List<Offset>();
  List<Offset> offsets;
  List<Animation<Offset>> animations;
  AnimationController controller;
  CurvedAnimation curved;
  String scanResult;

  void setScanResult(String result){
    setState(() {
        scanResult = result;
    });
  }

  void changeToOffset(List<Offset> newOffset) {
    setState(() {
      to = newOffset;
      controller.stop();
      controller.duration = widget.animationDuration ?? controller.duration;
      animations.forEach((c) => c.removeStatusListener(_statusListenerIdle));
      animations = newOffset.map((offset) {
        int i = newOffset.indexOf(offset);
        Offset fromOffset = offsets[i];
        return Tween<Offset>(
          begin: fromOffset,
          end: offset,
        ).animate(curved);
      }).toList();
    });
    controller.forward().whenComplete(
      () => widget?.onScan(scanResult));
    
  }

  void onRescan() => revertOffset().whenComplete(() => initAnimation());

  TickerFuture revertOffset() {
    double left = (widget.widgetSize.width - widget.width) / 2;
    double top = (widget.widgetSize.height - widget.height) / 2 + widget.padding.top;
    double right = (widget.widgetSize.width - widget.width) / 2 + widget.width;
    double bottom = (widget.widgetSize.height - widget.height) / 2 + widget.height + widget.padding.top;

    List<Offset> newOffset = [
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom)
    ];
    setState(() {
      controller.stop();
      controller.duration = const Duration(milliseconds: 1000);
      animations.forEach((c) => c.removeStatusListener(_statusListenerIdle));
      animations = newOffset.map((offset) {
        int i = newOffset.indexOf(offset);
        Offset fromOffset = offsets[i];
        return Tween<Offset>(
          begin: fromOffset,
          end: offset,
        ).animate(curved);
      }).toList();
    });
    return controller.forward();
  }

  void initAnimation() {
    final double tween = 0.9;
    double left = (widget.widgetSize.width - widget.width) / 2;
    double top = ((widget.widgetSize.height - widget.height) / 2) + widget.padding.top;
    double right = (widget.widgetSize.width - widget.width) / 2 + widget.width;
    double bottom = (widget.widgetSize.height - widget.height) / 2 + widget.height + widget.padding.top;

    from = [
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom)
    ];
    offsets = from;

    right = (widget.widgetSize.width - widget.width) / 2 + widget.width * tween;
    bottom = (widget.widgetSize.height - widget.height) / 2 + widget.height * tween + widget.padding.top;
    left = (widget.widgetSize.width - widget.width) / 2 + widget.width * (1 - tween);
    top = (widget.widgetSize.height - widget.height) / 2 + widget.height * (1 - tween) + widget.padding.top;

    to = [
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom)
    ];

    controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    curved = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    animations = from.map((offset) {
      int i = from.indexOf(offset);
      Offset toOffset = to[i];
      return Tween<Offset>(
        begin: offset,
        end: toOffset,
      ).animate(curved)
        ..addListener(() => setState(() => offsets[i] = animations[i].value))
        ..addStatusListener(_statusListenerIdle);
    }).toList();

    controller.forward();
  }

  void _statusListenerIdle(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      controller.forward();
    }
  }

  @override
  void initState() {
    initAnimation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.transparent,
    child: CustomPaint(
      painter: _SquarePainter(
        points: offsets,
        color: widget.squareColor
          ?? ((widget.squareBorderColor != null)
            ? widget.squareBorderColor.withOpacity(0.25)
            : Colors.blue.withOpacity(0.25)),
        borderColor: widget.squareBorderColor
          ?? ((widget.squareColor != null)
            ? widget.squareColor.withOpacity(1)
            : Colors.blue),
        borderWidth: widget.borderWidth ?? 2.5,
        tween: _fraction,
      ),
    ),
  );
}

class _SquarePainter extends CustomPainter {
  final List<Offset> points;
  final double tween;
  final Color borderColor;
  final Color color;
  final double borderWidth;

  _SquarePainter({this.points, this.color, this.borderColor, this.borderWidth, this.tween});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(Path()..addPolygon(points ?? [], true),
        Paint()..color = color);
    Paint _paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(points[0], points[1], _paint);
    canvas.drawLine(points[1], points[2], _paint);
    canvas.drawLine(points[2], points[3], _paint);
    canvas.drawLine(points[3], points[0], _paint);
  }

  @override
  bool shouldRepaint(_SquarePainter oldDelegate) {
    return true;
  }
}