import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual outreach assignment.
    final class ManualOutreachAssignmentView {
        var code: String
        var labelText: String
        var endsAt: String
        var rate: String
        var maximum: String
        var name: String
        var durationMinutes: String
        var score: String
        var statusLabel: String

        init(code: String, labelText: String, endsAt: String, rate: String, maximum: String, name: String, durationMinutes: String, score: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.endsAt = endsAt
            self.rate = rate
            self.maximum = maximum
            self.name = name
            self.durationMinutes = durationMinutes
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toManualOutreachAssignmentView(_ item: ManualOutreachAssignment) -> ManualOutreachAssignmentView {
        return ManualOutreachAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            endsAt: String(item.endsAt),
            rate: String(format: "%.2f", item.rate),
            maximum: String(format: "%.2f", item.maximum),
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualOutreachAssignmentViews(_ items: [ManualOutreachAssignment]) -> [ManualOutreachAssignmentView] {
        var views: [ManualOutreachAssignmentView] = []
        for item in items {
            views.append(toManualOutreachAssignmentView(item))
        }
        return views
    }

    static func sumManualOutreachAssignmentView(_ view: ManualOutreachAssignmentView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedEndsAt) + parsedRate + parsedMaximum
    }
}
