import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered assessment allocation.
    final class TieredAssessmentAllocationView {
        var code: String
        var label: String
        var approved: String
        var graceDays: String
        var startsAt: String
        var archived: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, approved: String, graceDays: String, startsAt: String, archived: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.approved = approved
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.archived = archived
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAssessmentAllocationView(_ item: TieredAssessmentAllocation) -> TieredAssessmentAllocationView {
        return TieredAssessmentAllocationView(
            code: item.code,
            label: item.label,
            approved: "\(item.approved)",
            graceDays: String(item.graceDays),
            startsAt: String(item.startsAt),
            archived: "\(item.archived)",
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAssessmentAllocationViews(_ items: [TieredAssessmentAllocation]) -> [TieredAssessmentAllocationView] {
        var views: [TieredAssessmentAllocationView] = []
        for item in items {
            views.append(toTieredAssessmentAllocationView(item))
        }
        return views
    }

    static func sumTieredAssessmentAllocationView(_ view: TieredAssessmentAllocationView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedStartsAt) + Double(parsedPriority)
    }
}
