import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive priority milestone.
    final class AdaptivePriorityMilestoneView {
        var code: String
        var name: String
        var contactEmail: String
        var reviewer: String
        var updatedAtText: String
        var pinned: String
        var patientRef: String
        var statusLabel: String

        init(code: String, name: String, contactEmail: String, reviewer: String, updatedAtText: String, pinned: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.updatedAtText = updatedAtText
            self.pinned = pinned
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePriorityMilestoneView(_ item: AdaptivePriorityMilestone) -> AdaptivePriorityMilestoneView {
        return AdaptivePriorityMilestoneView(
            code: item.code,
            name: item.name,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            reviewer: item.reviewer,
            updatedAtText: String(item.updatedAt),
            pinned: "\(item.pinned)",
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePriorityMilestoneViews(_ items: [AdaptivePriorityMilestone]) -> [AdaptivePriorityMilestoneView] {
        var views: [AdaptivePriorityMilestoneView] = []
        for item in items {
            views.append(toAdaptivePriorityMilestoneView(item))
        }
        return views
    }

    static func sumAdaptivePriorityMilestoneView(_ view: AdaptivePriorityMilestoneView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
