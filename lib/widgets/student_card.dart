import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../theme/app_colors.dart';
import '../screens/monthly_calendar_screen.dart';

class StudentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Color cardColor;
    Color textColor;
    Color subTextColor;

    if (student.selected) {
      // Holiday state
      cardColor = AppColors.holiday;
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else if (student.isPresent) {
      // Present state
      cardColor = AppColors.present;
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else if (student.isAbsent) {
      // Absent state
      cardColor = AppColors.absent;
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else {
      // Default / unmarked state
      cardColor = Colors.white;
      textColor = AppColors.textPrimary;
      subTextColor = AppColors.primary;
    }

    final isColored = student.selected || student.isPresent || student.isAbsent;

    return Dismissible(
      key: Key(student.docId.isNotEmpty ? student.docId : student.rollno),
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
        if (direction == DismissDirection.startToEnd) {
          onMarkPresent();
        } else if (direction == DismissDirection.endToStart) {
          onMarkAbsent();
        }
        return false; // Prevent the card from actually being removed from the UI list
      },
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
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggleStatus,
            onLongPress: onEdit,
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
                          student.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.rollno,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isColored ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.stream,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MonthlyCalendarScreen(student: student),
                            ),
                          );
                        },
                        tooltip: 'View Monthly Attendance',
                      ),
                      InkWell(
                        onTap: onDelete,
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
