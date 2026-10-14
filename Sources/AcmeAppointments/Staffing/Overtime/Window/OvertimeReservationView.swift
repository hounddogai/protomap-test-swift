import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime reservation.
    final class OvertimeReservationView {
        var code: String
        var title: String
        var clinicianID: String
        var threshold: String
        var dosageMgText: String
        var source: String
        var unit: String
        var regionText: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, threshold: String, dosageMgText: String, source: String, unit: String, regionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.threshold = threshold
            self.dosageMgText = dosageMgText
            self.source = source
            self.unit = unit
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeReservationView(_ item: OvertimeReservation) -> OvertimeReservationView {
        return OvertimeReservationView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            clinicianID: item.clinicianID,
            threshold: String(format: "%.2f", item.threshold),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            source: Kit.Text.truncate(item.source, limit: 120),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeReservationViews(_ items: [OvertimeReservation]) -> [OvertimeReservationView] {
        var views: [OvertimeReservationView] = []
        for item in items {
            views.append(toOvertimeReservationView(item))
        }
        return views
    }

    static func sumOvertimeReservationView(_ view: OvertimeReservationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedThreshold + parsedDosageMg
    }
}
