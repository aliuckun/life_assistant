import 'package:flutter/material.dart';
import '../../domain/plan_models.dart';
import '../utils/planner_constants.dart';

class PlanTaskCard extends StatelessWidget {
  final PlanItem plan;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const PlanTaskCard({
    super.key,
    required this.plan,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // DB'den gelen kategori ismiyle UI objesini bul
    final uiCategory = PlannerConstants.getCategoryByName(plan.categoryName);

    bool isDone = plan.isCompleted;
    Color priorityColor;

    switch (plan.priority) {
      case PlanPriority.high:
        priorityColor = Colors.redAccent;
        break;
      case PlanPriority.medium:
        priorityColor = Colors.orangeAccent;
        break;
      case PlanPriority.low:
        priorityColor = Colors.blueGrey;
        break;
    }

    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_sweep_outlined,
          color: Colors.red[400],
          size: 30,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol: Saat
                  Column(
                    children: [
                      Text(
                        plan.startTime.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDone ? Colors.grey[400] : Colors.black87,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 24,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.grey[200]
                              : uiCategory.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        plan.endTime.format(context),
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Orta: İçerik
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: uiCategory.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    uiCategory.icon,
                                    size: 10,
                                    color: uiCategory.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    uiCategory.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: uiCategory.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (plan.priority == PlanPriority.high && !isDone)
                              Icon(
                                Icons.priority_high_rounded,
                                size: 14,
                                color: priorityColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey[400] : Colors.black87,
                          ),
                        ),
                        if (plan.description != null &&
                            plan.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            plan.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDone
                                  ? Colors.grey[300]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Sağ: Checkbox
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: isDone ? Colors.green : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
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
