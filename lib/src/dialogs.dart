import 'package:flutter/material.dart' hide YearPicker;

import 'l10n/month_year_picker_localizations.dart';
import 'pickers.dart';
import 'utils.dart';

// ################################# CONSTANTS #################################
Size _portraitDialogSize(BuildContext context, double maxHeight) {
  final size = MediaQuery.of(context).size;
  if (maxHeight >= 600) {
    return Size(size.width * 0.5, size.height * 0.56);
  } else {
    return Size(size.width * 0.5, size.height * 0.7);
  }
}

const _landscapeDialogSize = Size(496.0, 344.0);
const _dialogSizeAnimationDuration = Duration(milliseconds: 200);
const _datePickerHeaderLandscapeWidth = 192.0;
const _datePickerHeaderPortraitHeight = 120.0;
const _headerPaddingLandscape = 16.0;

// ################################# FUNCTIONS #################################
/// Displays month year picker dialog.
/// [initialDate] is the initially selected month.
/// [firstDate] is the lower bound for month selection.
/// [lastDate] is the upper bound for month selection.
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required Color pickerColor,
  SelectableMonthYearPredicate? selectableMonthYearPredicate,
  Locale? locale,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  TextDirection? textDirection,
  TransitionBuilder? builder,
  MonthYearPickerMode initialMonthYearPickerMode = MonthYearPickerMode.month,
}) async {
  initialDate = monthYearOnly(initialDate);
  firstDate = monthYearOnly(firstDate);
  lastDate = monthYearOnly(lastDate);

  assert(
    !lastDate.isBefore(firstDate),
    'lastDate $lastDate must be on or after firstDate $firstDate.',
  );
  assert(
    !initialDate.isBefore(firstDate),
    'initialDate $initialDate must be on or after firstDate $firstDate.',
  );
  assert(
    !initialDate.isAfter(lastDate),
    'initialDate $initialDate must be on or before lastDate $lastDate.',
  );
  assert(debugCheckHasMaterialLocalizations(context));
  assert(debugCheckHasMonthYearPickerLocalizations(context));
  assert(debugCheckHasDirectionality(context));

  Widget dialog = MonthYearPickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialMonthYearPickerMode: initialMonthYearPickerMode,
      selectableMonthYearPredicate: selectableMonthYearPredicate,
      pickerColor: pickerColor);

  if (textDirection != null) {
    dialog = Directionality(
      textDirection: textDirection,
      child: dialog,
    );
  }

  if (locale != null) {
    dialog = Localizations.override(
      context: context,
      locale: locale,
      child: dialog,
    );
  }

  return await showDialog<DateTime>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (context) => builder == null ? dialog : builder(context, dialog),
  );
}

// ################################ ENUMERATIONS ###############################
enum MonthYearPickerMode {
  month,
  year,
}

// ################################## CLASSES ##################################
class MonthYearPickerDialog extends StatefulWidget {
  // ------------------------------- CONSTRUCTORS ------------------------------
  const MonthYearPickerDialog({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.initialMonthYearPickerMode,
    required this.pickerColor,
    this.selectableMonthYearPredicate,
  }) : super(key: key);

  // ---------------------------------- FIELDS ---------------------------------
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final MonthYearPickerMode initialMonthYearPickerMode;
  final SelectableMonthYearPredicate? selectableMonthYearPredicate;
  final Color pickerColor;

  // --------------------------------- METHODS ---------------------------------
  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  // ---------------------------------- FIELDS ---------------------------------
  final _yearPickerState = GlobalKey<YearPickerState>();
  final _monthPickerState = GlobalKey<MonthPickerState>();
  var _isShowingYear = false;
  var _canGoPrevious = false;
  var _canGoNext = false;
  late DateTime _selectedDate = widget.initialDate;

  // -------------------------------- PROPERTIES -------------------------------
  Size _dialogSize(double maxHeight) {
    final orientation = MediaQuery.of(context).orientation;

    switch (orientation) {
      case Orientation.portrait:
        return _portraitDialogSize(context, maxHeight);
      case Orientation.landscape:
        return _landscapeDialogSize;
    }
  }

  // --------------------------------- METHODS ---------------------------------
  @override
  void initState() {
    super.initState();
    _isShowingYear =
        widget.initialMonthYearPickerMode == MonthYearPickerMode.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(_updatePaginators);
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);
    final localizations = MonthYearPickerLocalizations.of(context);
    final media = MediaQuery.of(context);

    final orientation = media.orientation;

    // Constrain the textScaleFactor to the largest supported value to prevent
    // layout issues.

    final direction = Directionality.of(context);

    final dateText = materialLocalizations.formatMonthYear(_selectedDate);

    final dateStyle = orientation == Orientation.landscape
        ? const TextStyle(
            fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500)
        : const TextStyle(
            fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500);

    final Widget actions = SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.cancelButtonLabel,
                style: TextStyle(color: widget.pickerColor, fontSize: 12),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => Navigator.pop(context, _selectedDate),
            child: Text(
              localizations.okButtonLabel,
              style: TextStyle(color: widget.pickerColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    final semanticText = materialLocalizations.formatMonthYear(_selectedDate);
    final header = _Header(
      helpText: localizations.helpText,
      titleText: dateText,
      titleSemanticsLabel: semanticText,
      titleStyle: dateStyle,
      orientation: orientation,
      pickerColor: widget.pickerColor,
    );

    final switcher = Stack(
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: widget.pickerColor,
            padding: const EdgeInsets.only(
              left: 30,
            ),
          ),
          child: Row(
            children: [
              Text(materialLocalizations.formatYear(_selectedDate)),
              AnimatedRotation(
                duration: _dialogSizeAnimationDuration,
                turns: _isShowingYear ? 0.5 : 0.0,
                child: const Icon(Icons.arrow_drop_down),
              ),
            ],
          ),
          onPressed: () {
            setState(() {
              _isShowingYear = !_isShowingYear;
              _updatePaginators();
            });
          },
        ),
        PositionedDirectional(
          end: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  direction == TextDirection.rtl
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_left,
                ),
                onPressed: _canGoPrevious ? _goToPreviousPage : null,
              ),
              IconButton(
                icon: Icon(
                  direction == TextDirection.rtl
                      ? Icons.keyboard_arrow_left
                      : Icons.keyboard_arrow_right,
                ),
                onPressed: _canGoNext ? _goToNextPage : null,
              )
            ],
          ),
        ),
        const SizedBox(width: 12.0),
      ],
    );

    final picker = LayoutBuilder(
      builder: (context, constraints) {
        // final pickerMaxWidth =
        //     _landscapeDialogSize.width - _datePickerHeaderLandscapeWidth;
        // final width = constraints.maxHeight < pickerMaxWidth
        //     ? constraints.maxHeight / 2.8 * 4
        //     : null;

        //    final value = (pickerMaxWidth - (width ?? pickerMaxWidth));

        return Stack(
          children: [
            AnimatedPositioned(
              duration: _dialogSizeAnimationDuration,
              curve: Curves.easeOut,
              left: 10,
              right: 10,
              top: _isShowingYear ? 0.0 : -constraints.maxHeight,
              bottom: _isShowingYear ? 0.0 : constraints.maxHeight,
              child: SizedBox(
                height: constraints.maxHeight,
                child: YearPicker(
                  key: _yearPickerState,
                  pickerColor: widget.pickerColor,
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onPageChanged: _updateSelectedDate,
                  onYearSelected: _updateYear,
                  selectedDate: _selectedDate,
                  selectableMonthYearPredicate:
                      widget.selectableMonthYearPredicate,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _dialogSizeAnimationDuration,
              curve: Curves.easeOut,
              left: 10,
              right: 10,
              top: _isShowingYear ? constraints.maxHeight : 0.0,
              bottom: _isShowingYear ? -constraints.maxHeight : 0.0,
              child: SizedBox(
                height: constraints.maxHeight,
                child: MonthPicker(
                  key: _monthPickerState,
                  pickerColor: widget.pickerColor,
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onPageChanged: _updateSelectedDate,
                  onMonthSelected: _updateMonth,
                  selectedDate: _selectedDate,
                  selectableMonthYearPredicate:
                      widget.selectableMonthYearPredicate,
                ),
              ),
            )
          ],
        );
      },
    );

    return LayoutBuilder(builder: (context, constraints) {
      final width = _dialogSize(constraints.maxHeight).width;
      final height = _dialogSize(constraints.maxHeight).height;

      return Directionality(
        textDirection: direction,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            width: width,
            height: height,
            duration: _dialogSizeAnimationDuration,
            curve: Curves.easeIn,
            child: Builder(
              builder: (context) {
                switch (orientation) {
                  case Orientation.portrait:
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        switcher,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: picker,
                          ),
                        ),
                        actions,
                      ],
                    );
                  case Orientation.landscape:
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              switcher,
                              Expanded(child: picker),
                              actions,
                            ],
                          ),
                        ),
                      ],
                    );
                }
              },
            ),
          ),
        ),
      );
    });
  }

  void _updateYear(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, _selectedDate.month);
      _isShowingYear = false;
      _monthPickerState.currentState!.goToYear(year: _selectedDate.year);
    });
  }

  void _updateMonth(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month);
    });
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month);
      _updatePaginators();
    });
  }

  void _updatePaginators() {
    if (_isShowingYear) {
      _canGoNext = _yearPickerState.currentState!.canGoUp;
      _canGoPrevious = _yearPickerState.currentState!.canGoDown;
    } else {
      _canGoNext = _monthPickerState.currentState!.canGoUp;
      _canGoPrevious = _monthPickerState.currentState!.canGoDown;
    }
  }

  void _goToPreviousPage() {
    if (_isShowingYear) {
      _yearPickerState.currentState!.goDown();
    } else {
      _monthPickerState.currentState!.goDown();
    }
  }

  void _goToNextPage() {
    if (_isShowingYear) {
      _yearPickerState.currentState!.goUp();
    } else {
      _monthPickerState.currentState!.goUp();
    }
  }
}

class _Header extends StatelessWidget {
  // ------------------------------- CONSTRUCTORS ------------------------------
  const _Header(
      {Key? key,
      required this.helpText,
      required this.titleText,
      this.titleSemanticsLabel,
      required this.titleStyle,
      required this.orientation,
      required this.pickerColor})
      : super(key: key);

  // ---------------------------------- FIELDS ---------------------------------
  final String helpText;
  final String titleText;
  final String? titleSemanticsLabel;
  final TextStyle? titleStyle;
  final Orientation orientation;
  final Color pickerColor;

  // --------------------------------- METHODS ---------------------------------
  @override
  Widget build(BuildContext context) {
    // The header should use the primary color in light themes and surface color
    // in dark.

    final primarySurfaceColor = pickerColor;

    const helpStyle = TextStyle(fontSize: 10, color: Colors.white);

    final help = Text(
      helpText,
      style: helpStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final title = Text(
      titleText,
      semanticsLabel: titleSemanticsLabel ?? titleText,
      style: titleStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    switch (orientation) {
      case Orientation.portrait:
        return SizedBox(
          height: _datePickerHeaderPortraitHeight,
          child: Material(
            color: primarySurfaceColor,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 24.0,
                end: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  help,
                  const Flexible(child: SizedBox(height: 38.0)),
                  title,
                ],
              ),
            ),
          ),
        );
      case Orientation.landscape:
        return SizedBox(
          width: _datePickerHeaderLandscapeWidth,
          child: Material(
            color: primarySurfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _headerPaddingLandscape,
                  ),
                  child: help,
                ),
                const SizedBox(height: 56.0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _headerPaddingLandscape,
                    ),
                    child: title,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
