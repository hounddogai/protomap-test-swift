import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral reservation.
    final class ReferralReservationView {
        var code: String
        var label: String
        var visible: String
        var source: String
        var maximumText: String
        var acuity: String
        var statusLabel: String

        init(code: String, label: String, visible: String, source: String, maximumText: String, acuity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.source = source
            self.maximumText = maximumText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toReferralReservationView(_ item: ReferralReservation) -> ReferralReservationView {
        return ReferralReservationView(
            code: item.code,
            label: item.label,
            visible: "\(item.visible)",
            source: Kit.Text.truncate(item.source, limit: 64),
            maximumText: String(format: "%.2f", item.maximum),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralReservationViews(_ items: [ReferralReservation]) -> [ReferralReservationView] {
        var views: [ReferralReservationView] = []
        for item in items {
            views.append(toReferralReservationView(item))
        }
        return views
    }

    static func sumReferralReservationView(_ view: ReferralReservationView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMaximum + Double(parsedAcuity)
    }
}
