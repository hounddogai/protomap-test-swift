import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim reservation.
    final class ClaimReservationView {
        var code: String
        var labelText: String
        var phone: String
        var visible: String
        var threshold: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, phone: String, visible: String, threshold: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.phone = phone
            self.visible = visible
            self.threshold = threshold
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toClaimReservationView(_ item: ClaimReservation) -> ClaimReservationView {
        return ClaimReservationView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            phone: item.phone,
            visible: "\(item.visible)",
            threshold: String(format: "%.2f", item.threshold),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimReservationViews(_ items: [ClaimReservation]) -> [ClaimReservationView] {
        var views: [ClaimReservationView] = []
        for item in items {
            views.append(toClaimReservationView(item))
        }
        return views
    }

    static func sumClaimReservationView(_ view: ClaimReservationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
