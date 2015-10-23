// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-10-23T14:42:19.066Z

part of chartjs;

// **************************************************************************
// Generator: DefinitelyTypedGenerator
// Target: library chartjs
// **************************************************************************

@JS()
class ChartDataSet {
  external String get label;
  external String get fillColor;
  external String get strokeColor;
  external String get pointColor;
  external String get pointStrokeColor;
  external String get pointHighlightFill;
  external String get pointHighlightStroke;
  external String get highlightFill;
  external String get highlightStroke;
  external List<num> get data;
  external factory ChartDataSet(
      {String label,
      String fillColor,
      String strokeColor,
      String pointColor,
      String pointStrokeColor,
      String pointHighlightFill,
      String pointHighlightStroke,
      String highlightFill,
      String highlightStroke,
      List<num> data});
}

@JS()
class LinearChartData {
  external List<String> get labels;
  external List<ChartDataSet> get datasets;
  external factory LinearChartData(
      {List<String> labels, List<ChartDataSet> datasets});
}

@JS()
class CircularChartData {
  external num get value;
  external String get color;
  external String get highlight;
  external String get label;
  external factory CircularChartData(
      {num value, String color, String highlight, String label});
}

@JS()
class ChartSettings {
  external bool get animation;
  external num get animationSteps;
  external String get animationEasing;
  external bool get showScale;
  external bool get scaleOverride;
  external num get scaleSteps;
  external num get scaleStepWidth;
  external num get scaleStartValue;
  external String get scaleLineColor;
  external num get scaleLineWidth;
  external bool get scaleShowLabels;
  external String get scaleLabel;
  external bool get scaleIntegersOnly;
  external bool get scaleBeginAtZero;
  external String get scaleFontFamily;
  external num get scaleFontSize;
  external String get scaleFontStyle;
  external String get scaleFontColor;
  external bool get responsive;
  external bool get maintainAspectRatio;
  external bool get showTooltips;
  external List<String> get tooltipEvents;
  external String get tooltipFillColor;
  external String get tooltipFontFamily;
  external num get tooltipFontSize;
  external String get tooltipFontStyle;
  external String get tooltipFontColor;
  external String get tooltipTitleFontFamily;
  external num get tooltipTitleFontSize;
  external String get tooltipTitleFontStyle;
  external String get tooltipTitleFontColor;
  external num get tooltipYPadding;
  external num get tooltipXPadding;
  external num get tooltipCaretSize;
  external num get tooltipCornerRadius;
  external num get tooltipXOffset;
  external String get tooltipTemplate;
  external String get multiTooltipTemplate;
  external get onAnimationProgress;
  external get onAnimationComplete;
  external factory ChartSettings(
      {bool animation,
      num animationSteps,
      String animationEasing,
      bool showScale,
      bool scaleOverride,
      num scaleSteps,
      num scaleStepWidth,
      num scaleStartValue,
      String scaleLineColor,
      num scaleLineWidth,
      bool scaleShowLabels,
      String scaleLabel,
      bool scaleIntegersOnly,
      bool scaleBeginAtZero,
      String scaleFontFamily,
      num scaleFontSize,
      String scaleFontStyle,
      String scaleFontColor,
      bool responsive,
      bool maintainAspectRatio,
      bool showTooltips,
      List<String> tooltipEvents,
      String tooltipFillColor,
      String tooltipFontFamily,
      num tooltipFontSize,
      String tooltipFontStyle,
      String tooltipFontColor,
      String tooltipTitleFontFamily,
      num tooltipTitleFontSize,
      String tooltipTitleFontStyle,
      String tooltipTitleFontColor,
      num tooltipYPadding,
      num tooltipXPadding,
      num tooltipCaretSize,
      num tooltipCornerRadius,
      num tooltipXOffset,
      String tooltipTemplate,
      String multiTooltipTemplate,
      dynamic onAnimationProgress(),
      dynamic onAnimationComplete()});
}

@JS()
class ChartOptions {
  external bool get scaleShowGridLines;
  external String get scaleGridLineColor;
  external num get scaleGridLineWidth;
  external String get legendTemplate;
  external factory ChartOptions(
      {bool scaleShowGridLines,
      String scaleGridLineColor,
      num scaleGridLineWidth,
      String legendTemplate});
}

@JS()
class PointsAtEvent {
  external num get value;
  external String get label;
  external String get datasetLabel;
  external String get strokeColor;
  external String get fillColor;
  external String get highlightFill;
  external String get highlightStroke;
  external num get x;
  external num get y;
  external factory PointsAtEvent(
      {num value,
      String label,
      String datasetLabel,
      String strokeColor,
      String fillColor,
      String highlightFill,
      String highlightStroke,
      num x,
      num y});
}

@JS()
class ChartInstance {
  external get clear;
  external get stop;
  external get resize;
  external get destroy;
  external get toBase64Image;
  external get generateLegend;
  external factory ChartInstance(
      {void clear(),
      void stop(),
      void resize(),
      void destroy(),
      String toBase64Image(),
      String generateLegend()});
}

@JS()
class LinearInstance {
  external get getPointsAtEvent;
  external get update;
  external get addData;
  external get removeData;
  external factory LinearInstance(
      {List<PointsAtEvent> getPointsAtEvent(Event event),
      void update(),
      void addData(List<num> valuesArray, String label),
      void removeData()});
}

@JS()
class CircularInstance {
  external get getSegmentsAtEvent;
  external get update;
  external get addData;
  external get removeData;
  external List get segments;
  external factory CircularInstance(
      {List getSegmentsAtEvent(Event event),
      void update(),
      void addData(CircularChartData valuesArray, num index),
      void removeData(num index),
      List});
}

@JS()
class LineChartOptions {
  external bool get bezierCurve;
  external num get bezierCurveTension;
  external bool get pointDot;
  external num get pointDotRadius;
  external num get pointDotStrokeWidth;
  external num get pointHitDetectionRadius;
  external bool get datasetStroke;
  external num get datasetStrokeWidth;
  external bool get datasetFill;
  external factory LineChartOptions(
      {bool bezierCurve,
      num bezierCurveTension,
      bool pointDot,
      num pointDotRadius,
      num pointDotStrokeWidth,
      num pointHitDetectionRadius,
      bool datasetStroke,
      num datasetStrokeWidth,
      bool datasetFill});
}

@JS()
class BarChartOptions {
  external bool get scaleBeginAtZero;
  external bool get barShowStroke;
  external num get barStrokeWidth;
  external num get barValueSpacing;
  external num get barDatasetSpacing;
  external factory BarChartOptions(
      {bool scaleBeginAtZero,
      bool barShowStroke,
      num barStrokeWidth,
      num barValueSpacing,
      num barDatasetSpacing});
}

@JS()
class RadarChartOptions {
  external bool get scaleShowLine;
  external bool get angleShowLineOut;
  external bool get scaleShowLabels;
  external bool get scaleBeginAtZero;
  external String get angleLineColor;
  external num get angleLineWidth;
  external String get pointLabelFontFamily;
  external String get pointLabelFontStyle;
  external num get pointLabelFontSize;
  external String get pointLabelFontColor;
  external bool get pointDot;
  external num get pointDotRadius;
  external num get pointDotStrokeWidth;
  external num get pointHitDetectionRadius;
  external bool get datasetStroke;
  external num get datasetStrokeWidth;
  external bool get datasetFill;
  external String get legendTemplate;
  external factory RadarChartOptions(
      {bool scaleShowLine,
      bool angleShowLineOut,
      bool scaleShowLabels,
      bool scaleBeginAtZero,
      String angleLineColor,
      num angleLineWidth,
      String pointLabelFontFamily,
      String pointLabelFontStyle,
      num pointLabelFontSize,
      String pointLabelFontColor,
      bool pointDot,
      num pointDotRadius,
      num pointDotStrokeWidth,
      num pointHitDetectionRadius,
      bool datasetStroke,
      num datasetStrokeWidth,
      bool datasetFill,
      String legendTemplate});
}

@JS()
class PolarAreaChartOptions {
  external bool get scaleShowLabelBackdrop;
  external String get scaleBackdropColor;
  external bool get scaleBeginAtZero;
  external num get scaleBackdropPaddingY;
  external num get scaleBackdropPaddingX;
  external bool get scaleShowLine;
  external bool get segmentShowStroke;
  external String get segmentStrokeColor;
  external num get segmentStrokeWidth;
  external num get animationSteps;
  external String get animationEasing;
  external bool get animateRotate;
  external bool get animateScale;
  external String get legendTemplate;
  external factory PolarAreaChartOptions(
      {bool scaleShowLabelBackdrop,
      String scaleBackdropColor,
      bool scaleBeginAtZero,
      num scaleBackdropPaddingY,
      num scaleBackdropPaddingX,
      bool scaleShowLine,
      bool segmentShowStroke,
      String segmentStrokeColor,
      num segmentStrokeWidth,
      num animationSteps,
      String animationEasing,
      bool animateRotate,
      bool animateScale,
      String legendTemplate});
}

@JS()
class PieChartOptions {
  external bool get segmentShowStroke;
  external String get segmentStrokeColor;
  external num get segmentStrokeWidth;
  external num get percentageInnerCutout;
  external num get animationSteps;
  external String get animationEasing;
  external bool get animateRotate;
  external bool get animateScale;
  external String get legendTemplate;
  external factory PieChartOptions(
      {bool segmentShowStroke,
      String segmentStrokeColor,
      num segmentStrokeWidth,
      num percentageInnerCutout,
      num animationSteps,
      String animationEasing,
      bool animateRotate,
      bool animateScale,
      String legendTemplate});
}

@JS()
class Chart {}

@JS() external get Chart;
