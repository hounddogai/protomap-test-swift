import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment reservation.
    final class AssessmentReservationView {
        var code: String
        var name: String
        var ceiling: String
        var label: String
        var reviewer: String
        var minimum: String
        var maximumText: String
        var statusLabel: String

        init(code: String, name: String, ceiling: String, label: String, reviewer: String, minimum: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.label = label
            self.reviewer = reviewer
            self.minimum = minimum
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentReservationView(_ item: AssessmentReservation) -> AssessmentReservationView {
        return AssessmentReservationView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            label: item.label,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentReservationViews(_ items: [AssessmentReservation]) -> [AssessmentReservationView] {
        var views: [AssessmentReservationView] = []
        for item in items {
            views.append(toAssessmentReservationView(item))
        }
        return views
    }

    static func sumAssessmentReservationView(_ view: AssessmentReservationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedMinimum + parsedMaximum
    }
}
