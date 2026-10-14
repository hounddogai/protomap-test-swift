import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution assignment.
    final class SubstitutionAssignmentView {
        var codeText: String
        var titleText: String
        var unitText: String
        var rateText: String
        var description: String
        var durationMinutes: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, titleText: String, unitText: String, rateText: String, description: String, durationMinutes: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.unitText = unitText
            self.rateText = rateText
            self.description = description
            self.durationMinutes = durationMinutes
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionAssignmentView(_ item: SubstitutionAssignment) -> SubstitutionAssignmentView {
        return SubstitutionAssignmentView(
            codeText: item.code,
            titleText: item.title,
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            rateText: String(format: "%.2f", item.rate),
            description: item.description,
            durationMinutes: String(item.durationMinutes),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionAssignmentViews(_ items: [SubstitutionAssignment]) -> [SubstitutionAssignmentView] {
        var views: [SubstitutionAssignmentView] = []
        for item in items {
            views.append(toSubstitutionAssignmentView(item))
        }
        return views
    }

    static func sumSubstitutionAssignmentView(_ view: SubstitutionAssignmentView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedRate + Double(parsedDurationMinutes)
    }
}
