import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a legacy priority assignment.
    final class LegacyPriorityAssignmentView {
        var codeText: String
        var name: String
        var unit: String
        var discount: String
        var pinned: String
        var archived: String
        var durationMinutesText: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, name: String, unit: String, discount: String, pinned: String, archived: String, durationMinutesText: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.unit = unit
            self.discount = discount
            self.pinned = pinned
            self.archived = archived
            self.durationMinutesText = durationMinutesText
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyPriorityAssignmentView(_ item: LegacyPriorityAssignment) -> LegacyPriorityAssignmentView {
        return LegacyPriorityAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            unit: item.unit,
            discount: String(format: "%.2f", item.discount),
            pinned: "\(item.pinned)",
            archived: "\(item.archived)",
            durationMinutesText: String(item.durationMinutes),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyPriorityAssignmentViews(_ items: [LegacyPriorityAssignment]) -> [LegacyPriorityAssignmentView] {
        var views: [LegacyPriorityAssignmentView] = []
        for item in items {
            views.append(toLegacyPriorityAssignmentView(item))
        }
        return views
    }

    static func sumLegacyPriorityAssignmentView(_ view: LegacyPriorityAssignmentView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDiscount + Double(parsedDurationMinutes) + Double(parsedGraceDays)
    }
}
