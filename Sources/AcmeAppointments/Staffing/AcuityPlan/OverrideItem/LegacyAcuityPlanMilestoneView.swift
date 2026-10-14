import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy acuity plan milestone.
    final class LegacyAcuityPlanMilestoneView {
        var codeText: String
        var labelText: String
        var limit: String
        var ward: String
        var priority: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, labelText: String, limit: String, ward: String, priority: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.limit = limit
            self.ward = ward
            self.priority = priority
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAcuityPlanMilestoneView(_ item: LegacyAcuityPlanMilestone) -> LegacyAcuityPlanMilestoneView {
        return LegacyAcuityPlanMilestoneView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            limit: String(item.limit),
            ward: item.ward,
            priority: String(item.priority),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAcuityPlanMilestoneViews(_ items: [LegacyAcuityPlanMilestone]) -> [LegacyAcuityPlanMilestoneView] {
        var views: [LegacyAcuityPlanMilestoneView] = []
        for item in items {
            views.append(toLegacyAcuityPlanMilestoneView(item))
        }
        return views
    }

    static func sumLegacyAcuityPlanMilestoneView(_ view: LegacyAcuityPlanMilestoneView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority)
    }
}
