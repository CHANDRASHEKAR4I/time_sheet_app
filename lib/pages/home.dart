




import 'package:flutter/material.dart';

import '../data/news.dart';
import '../services/holiday_asn.dart';
import '../services/leave_set.dart';
import '../services/notification_service.dart';
import 'package:marquee/marquee.dart';
// import 'news.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
  }

  // ============================================================
  // MODE
  // ============================================================

  bool isLeaveSheet = false;

  // ============================================================
  // CURRENT MONTH
  // ============================================================

  DateTime currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // ============================================================
  // PROJECT
  // ============================================================

  String projectAllotment = 'Not Alloted';

  bool projectFrozen = false;

  final TextEditingController projectController =
      TextEditingController();

  final TextEditingController remarksController =
      TextEditingController();

  // ============================================================
  // TIMESHEET
  // ============================================================

  final Set<DateTime> selectedDates = {};

  final Map<DateTime, double> workingHours = {};

  final Map<DateTime, String> taskDescriptions = {};

  // ============================================================
  // LEAVES
  // ============================================================

  String? selectedLeaveType;

  final Map<String, Set<DateTime>> leaveDates = {
    'SL': {},
    'CL': {},
    'EL': {},
    'FL': {},
  };

  // ============================================================
  // SAVE / SUBMIT
  // ============================================================

  bool draftSaved = false;
  bool submitted = false;

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool isSameDate(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  // ============================================================
  // LEAVE CHECK
  // ============================================================

  String? getLeaveForDate(DateTime date) {
    final normalizedDate = dateOnly(date);

    for (final entry in leaveDates.entries) {
      if (entry.value.any(
        (d) => isSameDate(
          d,
          normalizedDate,
        ),
      )) {
        return entry.key;
      }
    }

    return null;
  }

  bool hasLeave(DateTime date) {
    return getLeaveForDate(date) != null;
  }

  // ============================================================
  // SELECT WORKING DATE
  // ============================================================

  void selectDate(DateTime date) {
    final normalizedDate = dateOnly(date);

    if (HolidayAsn.isNationalHoliday(
      normalizedDate,
    )) {
      return;
    }

    if (hasLeave(normalizedDate)) {
      return;
    }

    setState(() {
      if (!selectedDates.any(
        (d) => isSameDate(
          d,
          normalizedDate,
        ),
      )) {
        selectedDates.add(normalizedDate);

        workingHours[normalizedDate] = 8;
      }
    });
  }

  // ============================================================
  // RESET WORKING DATE
  // ============================================================

  void resetDate(DateTime date) {
    final normalizedDate = dateOnly(date);

    setState(() {
      selectedDates.removeWhere(
        (d) => isSameDate(
          d,
          normalizedDate,
        ),
      );

      workingHours.remove(
        normalizedDate,
      );
    });
  }

  // ============================================================
  // EDIT HOURS
  // ============================================================

  void editHours(DateTime date) {
    final normalizedDate = dateOnly(date);

    final controller = TextEditingController(
      text: (workingHours[
                  normalizedDate] ??
              8)
          .toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Working Hours',
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              hintText: 'Enter hours',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final hours =
                    double.tryParse(
                  controller.text,
                );

                if (hours != null &&
                    hours >= 0 &&
                    hours <= 24) {
                  setState(() {
                    workingHours[
                            normalizedDate] =
                        hours;
                  });

                  Navigator.pop(context);
                }
              },
              child:
                  const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TASK DESCRIPTION
  // ============================================================

  void openTaskDescription(
    DateTime date,
  ) {
    final normalizedDate =
        dateOnly(date);

    final controller =
        TextEditingController(
      text:
          taskDescriptions[
                  normalizedDate] ??
              '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Task Description',
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration:
                const InputDecoration(
              hintText:
                  'Enter task description...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final text =
                      controller.text
                          .trim();

                  if (text.isEmpty) {
                    taskDescriptions
                        .remove(
                      normalizedDate,
                    );
                  } else {
                    taskDescriptions[
                            normalizedDate] =
                        text;
                  }
                });

                Navigator.pop(context);
              },
              child:
                  const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LEAVE SELECTION
  // ============================================================

  void selectLeaveDate(
    DateTime date,
  ) {
    if (selectedLeaveType == null) {
      return;
    }

    final normalizedDate =
        dateOnly(date);

    if (HolidayAsn.isNationalHoliday(
      normalizedDate,
    )) {
      return;
    }

    final leaveCode =
        selectedLeaveType!;

    setState(() {
      final existingLeave =
          getLeaveForDate(
        normalizedDate,
      );

      // Already same leave.
      if (existingLeave == leaveCode) {
        leaveDates[leaveCode]!
            .removeWhere(
          (d) => isSameDate(
            d,
            normalizedDate,
          ),
        );

        return;
      }

      // Remove previous leave.
      if (existingLeave != null) {
        leaveDates[existingLeave]!
            .removeWhere(
          (d) => isSameDate(
            d,
            normalizedDate,
          ),
        );
      }

      // Remove working hours.
      selectedDates.removeWhere(
        (d) => isSameDate(
          d,
          normalizedDate,
        ),
      );

      workingHours.remove(
        normalizedDate,
      );

      // Add new leave.
      leaveDates[leaveCode]!.add(
        normalizedDate,
      );
    });
  }

  // ============================================================
  // LEAVE BALANCE
  // ============================================================

  int getRemainingLeave(
    String code,
  ) {
    final leave =
        LeaveSet.getByCode(code);

    return leave.totalDays -
        leaveDates[code]!.length;
  }

  // ============================================================
  // WEEK SELECT
  // ============================================================

  void selectWeek(
    int weekIndex,
  ) {
    final weeks =
        getCalendarWeeks();

    if (weekIndex >=
        weeks.length) {
      return;
    }

    setState(() {
      for (final date
          in weeks[weekIndex]) {
        final current =
            date.month ==
                    currentMonth.month &&
                date.year ==
                    currentMonth.year;

        if (!current) {
          continue;
        }

        if (date.weekday ==
                DateTime.saturday ||
            date.weekday ==
                DateTime.sunday) {
          continue;
        }

        if (HolidayAsn
            .isNationalHoliday(date)) {
          continue;
        }

        final normalized =
            dateOnly(date);

        if (!hasLeave(normalized)) {
          selectedDates.add(
            normalized,
          );

          workingHours[
              normalized] ??= 8;
        }
      }
    });
  }

  // ============================================================
  // SELECT ALL
  // ============================================================

  void selectAllWeekdays() {
    setState(() {
      final lastDay =
          DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      );

      for (int day = 1;
          day <= lastDay.day;
          day++) {
        final date =
            DateTime(
          currentMonth.year,
          currentMonth.month,
          day,
        );

        if (date.weekday ==
                DateTime.saturday ||
            date.weekday ==
                DateTime.sunday) {
          continue;
        }

        if (HolidayAsn
            .isNationalHoliday(date)) {
          continue;
        }

        if (!hasLeave(date)) {
          selectedDates.add(
            dateOnly(date),
          );

          workingHours[
              dateOnly(date)] ??= 8;
        }
      }
    });
  }

  // ============================================================
  // CALENDAR WEEKS
  // ============================================================

  List<List<DateTime>>
      getCalendarWeeks() {
    final firstDay =
        DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    );

    final lastDay =
        DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );

    final firstWeekday =
        firstDay.weekday % 7;

    final List<DateTime> dates =
        [];

    for (int i =
            firstWeekday - 1;
        i >= 0;
        i--) {
      dates.add(
        firstDay.subtract(
          Duration(
            days: i + 1,
          ),
        ),
      );
    }

    for (int day = 1;
        day <= lastDay.day;
        day++) {
      dates.add(
        DateTime(
          currentMonth.year,
          currentMonth.month,
          day,
        ),
      );
    }

    while (dates.length % 7 !=
        0) {
      dates.add(
        DateTime(
          currentMonth.year,
          currentMonth.month + 1,
          dates.length,
        ),
      );
    }

    final List<List<DateTime>>
        weeks = [];

    for (int i = 0;
        i < dates.length;
        i += 7) {
      weeks.add(
        dates.sublist(
          i,
          i + 7,
        ),
      );
    }

    return weeks;
  }

  // ============================================================
  // PROJECT
  // ============================================================

  void confirmProject() {
    if (projectController.text
        .trim()
        .isEmpty) {
      return;
    }

    setState(() {
      projectFrozen = true;
    });
  }

  // ============================================================
  // SAVE / SUBMIT
  // ============================================================

  void saveDraft() {
    setState(() {
      draftSaved = true;
    });
  }

  void submitTimesheet() {
    setState(() {
      submitted = true;
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetTimesheet() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Reset Timesheet?',
          ),
          content:
              const Text(
            'Everything will return to the initial state.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'CANCEL',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );

                setState(() {
                  projectController
                      .clear();

                  projectFrozen = false;

                  projectAllotment =
                      'Not Alloted';

                  selectedDates.clear();

                  workingHours.clear();

                  taskDescriptions
                      .clear();

                  for (final dates
                      in leaveDates
                          .values) {
                    dates.clear();
                  }

                  selectedLeaveType =
                      null;

                  remarksController
                      .clear();

                  draftSaved = false;

                  submitted = false;
                });
              },
              child:
                  const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================

  void previousMonth() {
    setState(() {
      currentMonth =
          DateTime(
        currentMonth.year,
        currentMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth =
          DateTime(
        currentMonth.year,
        currentMonth.month + 1,
      );
    });
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String monthName(
    int month,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final weeks =
        getCalendarWeeks();

    return Scaffold(
      backgroundColor:
          const Color(0xFF171717),

      appBar: AppBar(
            backgroundColor: isLeaveSheet
                ? const Color(0xFF5A3030)
                : const Color(0xFF171717),
            elevation: 0,
            centerTitle: true,

            // Small toggle on the far left
            leading: Transform.scale(
              scale: 0.60,
              child: Switch(
                value: isLeaveSheet,
                onChanged: (value) {
                  setState(() {
                    isLeaveSheet = value;
                  });
                },
                activeThumbColor: const Color(0xFFE57373),
                activeTrackColor: const Color(0xFF7A4444),
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white24,
              ),
            ),

            // Keep title centered
            title: Text(
              isLeaveSheet
                  ? 'LEAVE SHEET'
                  : 'TIME SHEET',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
          ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              children: [

                // ==================================================
                // NEWS
                // ==================================================

                Container(
                  width:
                      double.infinity,
                  height: 38,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        isLeaveSheet
                            ? const Color(
                                0xFF3A2424,
                              )
                            : const Color(
                                0xFF242424,
                              ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  child:
                      _buildNews(),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // PROJECT
                // ==================================================

                Row(
                  children: [

                    SizedBox(
                      width: 145,
                      height: 52,
                      child:
                          _projectAllotment(),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          _projectBox(),
                    ),

                    const SizedBox(
                      width: 2,
                    ),

                    _smallResetButton(),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // WEEK / LEAVE SELECTOR
                // ==================================================

                isLeaveSheet
                    ? _leaveSelector()
                    : _weekSelector(
                        weeks.length,
                      ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // CALENDAR
                // ==================================================

                _calendar(weeks),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // SAVE / SUBMIT
                // ==================================================

                _actionButtons(),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // REMARKS
                // ==================================================

                _remarks(),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // TEST NOTIFICATION
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 45,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        () async {
                      await NotificationService
                          .showTestNotification();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Test notification sent',
                          ),
                        ),
                      );
                    },
                    icon:
                        const Icon(
                      Icons.notifications,
                    ),
                    label:
                        const Text(
                      'Test Notification',
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF303030,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEWS WIDGET
  // ============================================================

  Widget _buildNews() {
    return Marquee(
      text: NewsData.messages.join('     •     '),
      scrollAxis: Axis.horizontal,
      blankSpace: 80,
      velocity: 60,
      pauseAfterRound: Duration.zero,
      accelerationDuration: Duration.zero,
      decelerationDuration: Duration.zero,
      startPadding: 0,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
      ),
    );
  }

  // ============================================================
  // PROJECT ALLOTMENT
  // ============================================================

  Widget _projectAllotment() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF242424),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value:
              projectAllotment,
          isExpanded: true,
          dropdownColor:
              const Color(
            0xFF242424,
          ),
          icon:
              const Icon(
            Icons.keyboard_arrow_down,
            color:
                Colors.white54,
            size: 18,
          ),
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 12,
          ),
          items: const [
            DropdownMenuItem(
              value:
                  'Not Alloted',
              child:
                  Text('Not Alloted'),
            ),
            DropdownMenuItem(
              value:
                  'Embedded BU',
              child:
                  Text('Embedded BU'),
            ),
          ],
          onChanged:
              projectFrozen
                  ? null
                  : (value) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(() {
                        projectAllotment =
                            value;
                      });
                    },
        ),
      ),
    );
  }

  // ============================================================
  // PROJECT BOX
  // ============================================================

  Widget _projectBox() {
    return Container(
      height: 52,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF242424),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child:
          Row(
        children: [

          Expanded(
            child: TextField(
              controller:
                  projectController,
              enabled:
                  !projectFrozen,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 13,
              ),
              decoration:
                  const InputDecoration(
                hintText:
                    'Project',
                hintStyle:
                    TextStyle(
                  color:
                      Colors.white54,
                ),
                border:
                    InputBorder.none,
                contentPadding:
                    EdgeInsets
                        .symmetric(
                  horizontal: 14,
                ),
              ),
            ),
          ),

          if (!projectFrozen)
            IconButton(
              onPressed:
                  confirmProject,
              padding:
                  EdgeInsets.zero,
              icon:
                  const Icon(
                Icons.add,
                color:
                    Colors.white54,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  Widget _smallResetButton() {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed:
            resetTimesheet,
        padding:
            EdgeInsets.zero,
        icon:
            const Icon(
          Icons.refresh,
          color:
              Colors.white54,
          size: 17,
        ),
      ),
    );
  }

  // ============================================================
  // WEEK SELECTOR
  // ============================================================

  Widget _weekSelector(
    int weekCount,
  ) {
    return Row(
      children: [

        for (int i = 0;
            i < weekCount;
            i++) ...[
          Expanded(
            child:
                _selectorButton(
              'WK${i + 1}',
              () =>
                  selectWeek(i),
            ),
          ),

          const SizedBox(
            width: 5,
          ),
        ],

        Expanded(
          child:
              _selectorButton(
            'ALL',
            selectAllWeekdays,
            green: true,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEAVE SELECTOR
  // ============================================================

  Widget _leaveSelector() {
    return Row(
      children: [
        for (int i = 0;
            i < LeaveSet.leaves.length;
            i++) ...[
          Expanded(
            child:
                _leaveButton(
              LeaveSet.leaves[i],
            ),
          ),

          if (i !=
              LeaveSet.leaves.length -
                  1)
            const SizedBox(
              width: 6,
            ),
        ],
      ],
    );
  }

  Widget _leaveButton(
    LeaveType leave,
  ) {
    final active =
        selectedLeaveType ==
            leave.code;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLeaveType =
              active
                  ? null
                  : leave.code;
        });
      },
      child: Container(
        height: 55,
        decoration:
            BoxDecoration(
          color: active
              ? const Color(
                  0xFFB85C5C,
                )
              : const Color(
                  0xFF303030,
                ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Text(
              leave.code,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              '${getRemainingLeave(leave.code)}',
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECTOR BUTTON
  // ============================================================

  Widget _selectorButton(
    String title,
    VoidCallback onPressed, {
    bool green = false,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              green
                  ? const Color(
                      0xFF36C96F,
                    )
                  : const Color(
                      0xFF303030,
                    ),
          elevation: 0,
          padding:
              EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
          ),
        ),
        child: Text(
          title,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _calendar(
    List<List<DateTime>> weeks,
  ) {
    const days = [
      'Su',
      'Mo',
      'Tu',
      'We',
      'Th',
      'Fr',
      'Sa',
    ];

    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF242424),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [

              Text(
                '${monthName(currentMonth.month)} '
                '${currentMonth.year}',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Row(
                children: [
                  IconButton(
                    onPressed:
                        previousMonth,
                    icon:
                        const Icon(
                      Icons.chevron_left,
                      color:
                          Colors.white70,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        nextMonth,
                    icon:
                        const Icon(
                      Icons.chevron_right,
                      color:
                          Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          Row(
            children:
                days.map(
              (day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),

          const SizedBox(
            height: 7,
          ),

          Column(
            children: [
              for (final week
                  in weeks)
                Row(
                  children: [
                    for (final date
                        in week)
                      Expanded(
                        child:
                            _dateCell(
                          date,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE CELL
  // ============================================================

  Widget _dateCell(
    DateTime date,
  ) {
    final current =
        date.month ==
                currentMonth.month &&
            date.year ==
                currentMonth.year;

    final holiday =
        HolidayAsn
            .isNationalHoliday(
      date,
    );

    final leave =
        getLeaveForDate(date);

    final selected =
        selectedDates.any(
      (d) => isSameDate(
        d,
        date,
      ),
    );

    final hasTask =
        taskDescriptions
            .containsKey(
      dateOnly(date),
    );

    final hours =
        workingHours[
                dateOnly(date)] ??
            8;

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,

      onTap: () {
        if (!current) {
          return;
        }

        if (isLeaveSheet) {
          selectLeaveDate(date);
          return;
        }

        if (holiday) {
          return;
        }

        if (selected) {
          resetDate(date);
        } else {
          selectDate(date);
        }
      },

      onLongPress: () {
        if (!current ||
            holiday ||
            isLeaveSheet) {
          return;
        }

        openTaskDescription(
          date,
        );
      },

      child: Container(
        height: 58,
        margin:
            const EdgeInsets.all(
          2,
        ),
        decoration:
            BoxDecoration(
          color: holiday
              ? const Color(
                  0xFFD9534F,
                )
              : leave != null
                  ? const Color(
                      0xFFD9534F,
                    )
                  : selected
                      ? const Color(
                          0xFF36C96F,
                        )
                      : Colors.transparent,
          borderRadius:
              BorderRadius.circular(
            8,
          ),
        ),
        child: Stack(
          children: [

            Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [

                  Text(
                    '${date.day}',
                    style:
                        TextStyle(
                      color: current
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 11,
                    ),
                  ),

                  if (holiday)
                    const Text(
                      'Holiday',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 7,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    )
                  else if (leave != null)
                    Text(
                      leave,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 8,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    )
                  else if (selected &&
                      !isLeaveSheet)
                    GestureDetector(
                      onTap: () {
                        editHours(
                          date,
                        );
                      },
                      child: Text(
                        hours.toStringAsFixed(
                          hours % 1 ==
                                  0
                              ? 0
                              : 1,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (hasTask)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFF9B4A3A),
                    shape:
                        BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _actionButtons() {
    return Row(
      children: [

        Expanded(
          child: SizedBox(
            height: 46,
            child:
                ElevatedButton(
              onPressed:
                  saveDraft,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    draftSaved
                        ? const Color(
                            0xFF36C96F,
                          )
                        : const Color(
                            0xFF3A3A3A,
                          ),
                elevation: 0,
              ),
              child: Text(
                draftSaved
                    ? 'Saved'
                    : 'Save Draft',
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: SizedBox(
            height: 46,
            child:
                ElevatedButton(
              onPressed:
                  submitTimesheet,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    submitted
                        ? const Color(
                            0xFF36C96F,
                          )
                        : const Color(
                            0xFF3A3A3A,
                          ),
                elevation: 0,
              ),
              child: Text(
                submitted
                    ? 'Submitted'
                    : 'Submit',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REMARKS
  // ============================================================

  Widget _remarks() {
    return Container(
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF242424),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: TextField(
        controller:
            remarksController,
        maxLines: 4,
        style:
            const TextStyle(
          color:
              Colors.white,
        ),
        decoration:
            const InputDecoration(
          hintText:
              'Remarks',
          hintStyle:
              TextStyle(
            color:
                Colors.white54,
          ),
          border:
              InputBorder.none,
          contentPadding:
              EdgeInsets.all(
            15,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    projectController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}