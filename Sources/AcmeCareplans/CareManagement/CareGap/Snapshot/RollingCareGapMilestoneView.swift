import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling care gap milestone.
    final class RollingCareGapMilestoneView {
        var codeText: String
        var title: String
        var priority: String
        var ward: String
        var weight: String
        var statusLabel: String

        init(codeText: String, title: String, priority: String, ward: String, weight: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.priority = priority
            self.ward = ward
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareGapMilestoneView(_ item: RollingCareGapMilestone) -> RollingCareGapMilestoneView {
        return RollingCareGapMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            priority: String(item.priority),
            ward: item.ward,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareGapMilestoneViews(_ items: [RollingCareGapMilestone]) -> [RollingCareGapMilestoneView] {
        var views: [RollingCareGapMilestoneView] = []
        for item in items {
            views.append(toRollingCareGapMilestoneView(item))
        }
        return views
    }

    static func sumRollingCareGapMilestoneView(_ view: RollingCareGapMilestoneView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedPriority) + parsedWeight
    }
}
