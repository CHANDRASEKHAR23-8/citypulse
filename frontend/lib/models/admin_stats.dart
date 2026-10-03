class AdminStats {
  final int totalComplaints;
  final int totalUsers;
  final int resolvedCount;
  final double avgResolutionHours;
  final Map<String, int> byStatus;
  final List<CategoryCount> byCategory;
  final List<DepartmentCount> byDepartment;
  final Map<String, int> byPriority;

  AdminStats({
    required this.totalComplaints,
    required this.totalUsers,
    required this.resolvedCount,
    required this.avgResolutionHours,
    required this.byStatus,
    required this.byCategory,
    required this.byDepartment,
    required this.byPriority,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final statusMap = <String, int>{};
    if (json['byStatus'] != null && json['byStatus'] is Map) {
      (json['byStatus'] as Map).forEach((k, v) {
        statusMap[k.toString()] = (v as num).toInt();
      });
    }

    final priorityMap = <String, int>{};
    if (json['byPriority'] != null && json['byPriority'] is Map) {
      (json['byPriority'] as Map).forEach((k, v) {
        priorityMap[k.toString()] = (v as num).toInt();
      });
    }

    final catList = <CategoryCount>[];
    if (json['byCategory'] != null && json['byCategory'] is List) {
      for (final item in json['byCategory']) {
        catList.add(CategoryCount(
          category: item['category'] as String? ?? '',
          count: (item['count'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    final deptList = <DepartmentCount>[];
    if (json['byDepartment'] != null && json['byDepartment'] is List) {
      for (final item in json['byDepartment']) {
        deptList.add(DepartmentCount(
          department: item['department'] as String? ?? '',
          count: (item['count'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    return AdminStats(
      totalComplaints: (json['totalComplaints'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      resolvedCount: (json['resolvedCount'] as num?)?.toInt() ?? 0,
      avgResolutionHours: (json['avgResolutionHours'] as num?)?.toDouble() ?? 0.0,
      byStatus: statusMap,
      byCategory: catList,
      byDepartment: deptList,
      byPriority: priorityMap,
    );
  }
}

class CategoryCount {
  final String category;
  final int count;
  CategoryCount({required this.category, required this.count});
}

class DepartmentCount {
  final String department;
  final int count;
  DepartmentCount({required this.department, required this.count});
}
