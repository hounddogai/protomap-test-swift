import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling accession reservation.
    final class RollingAccessionReservationView {
        var code: String
        var label: String
        var active: String
        var unit: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, active: String, unit: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.active = active
            self.unit = unit
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAccessionReservationView(_ item: RollingAccessionReservation) -> RollingAccessionReservationView {
        return RollingAccessionReservationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            active: "\(item.active)",
            unit: item.unit,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAccessionReservationViews(_ items: [RollingAccessionReservation]) -> [RollingAccessionReservationView] {
        var views: [RollingAccessionReservationView] = []
        for item in items {
            views.append(toRollingAccessionReservationView(item))
        }
        return views
    }

    static func sumRollingAccessionReservationView(_ view: RollingAccessionReservationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
