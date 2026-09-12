import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_model.dart';
import '../models/stream_model.dart';
import '../theme/app_colors.dart';
import '../screens/monthly_calendar_screen.dart';

class StudentCard extends StatefulWidget {
  final StudentModel student;
  final VoidCallback onToggleStatus;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkAbsent;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const StudentCard({
    super.key,
    required this.student,
    required this.onToggleStatus,
    required this.onMarkPresent,
    required this.onMarkAbsent,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color textColor;
    Color subTextColor;

    if (widget.student.selected) {
      // Holiday state
      cardColor = AppColors.holiday;
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else if (widget.student.isPresent) {
      // Present state
      cardColor = AppColors.present;
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else if (widget.student.isAbsent) {
      // Absent state
      cardColor = AppColors.absent;
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else {
      // Default / unmarked state
      cardColor = Theme.of(context).cardColor;
      textColor = Theme.of(context).textTheme.titleLarge?.color ?? AppColors.textPrimary;
      subTextColor = Theme.of(context).colorScheme.primary;
    }

    final isColored = widget.student.selected || widget.student.isPresent || widget.student.isAbsent;

    return Dismissible(
      key: Key(widget.student.docId.isNotEmpty ? widget.student.docId : widget.student.rollno),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.present,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.absent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.cancel, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          widget.onMarkPresent();
        } else if (direction == DismissDirection.endToStart) {
          widget.onMarkAbsent();
        }
        return false; // Prevent the card from actually being removed from the UI list
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: !isColored ? Border.all(color: AppColors.cardBorder) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onToggleStatus();
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                if (widget.onEdit != null) widget.onEdit!();
              },
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  // Student info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student.rollno,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isColored ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student.stream,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Calendar View & Delete
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.calendar_month_rounded,
                          color: isColored ? Colors.white : AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MonthlyCalendarScreen(student: widget.student),
                            ),
                          );
                        },
                        tooltip: 'View Monthly Attendance',
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onDelete();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isColored ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
