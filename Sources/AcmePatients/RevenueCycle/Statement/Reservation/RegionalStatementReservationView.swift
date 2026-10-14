import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional statement reservation.
    final class RegionalStatementReservationView {
        var code: String
        var labelText: String
        var archived: String
        var limit: String
        var diagnosisCodeText: String
        var retries: String
        var maximum: String
        var pinned: String
        var statusLabel: String

        init(code: String, labelText: String, archived: String, limit: String, diagnosisCodeText: String, retries: String, maximum: String, pinned: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archived = archived
            self.limit = limit
            self.diagnosisCodeText = diagnosisCodeText
            self.retries = retries
            self.maximum = maximum
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStatementReservationView(_ item: RegionalStatementReservation) -> RegionalStatementReservationView {
        return RegionalStatementReservationView(
            code: item.code,
            labelText: item.label,
            archived: "\(item.archived)",
            limit: String(item.limit),
            diagnosisCodeText: item.diagnosisCode,
            retries: String(item.retries),
            maximum: String(format: "%.2f", item.maximum),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStatementReservationViews(_ items: [RegionalStatementReservation]) -> [RegionalStatementReservationView] {
        var views: [RegionalStatementReservationView] = []
        for item in items {
            views.append(toRegionalStatementReservationView(item))
        }
        return views
    }

    static func sumRegionalStatementReservationView(_ view: RegionalStatementReservationView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedLimit) + Double(parsedRetries) + parsedMaximum
    }
}
