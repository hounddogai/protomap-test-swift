import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict assessment reservation.
    final class StrictAssessmentReservationView {
        var code: String
        var label: String
        var priority: String
        var versionText: String
        var archivedText: String
        var cost: String
        var capacity: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, priority: String, versionText: String, archivedText: String, cost: String, capacity: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.priority = priority
            self.versionText = versionText
            self.archivedText = archivedText
            self.cost = cost
            self.capacity = capacity
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAssessmentReservationView(_ item: StrictAssessmentReservation) -> StrictAssessmentReservationView {
        return StrictAssessmentReservationView(
            code: item.code,
            label: item.label,
            priority: String(item.priority),
            versionText: String(item.version),
            archivedText: "\(item.archived)",
            cost: String(format: "%.2f", item.cost),
            capacity: String(item.capacity),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAssessmentReservationViews(_ items: [StrictAssessmentReservation]) -> [StrictAssessmentReservationView] {
        var views: [StrictAssessmentReservationView] = []
        for item in items {
            views.append(toStrictAssessmentReservationView(item))
        }
        return views
    }

    static func sumStrictAssessmentReservationView(_ view: StrictAssessmentReservationView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedPriority) + Double(parsedVersion) + parsedCost
    }
}
