import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback referral reservation.
    final class FallbackReferralReservationView {
        var code: String
        var label: String
        var refillsText: String
        var facilityText: String
        var limitText: String
        var createdAtText: String
        var discount: String
        var active: String
        var statusLabel: String

        init(code: String, label: String, refillsText: String, facilityText: String, limitText: String, createdAtText: String, discount: String, active: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.refillsText = refillsText
            self.facilityText = facilityText
            self.limitText = limitText
            self.createdAtText = createdAtText
            self.discount = discount
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackReferralReservationView(_ item: FallbackReferralReservation) -> FallbackReferralReservationView {
        return FallbackReferralReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            refillsText: String(item.refills),
            facilityText: Kit.Text.truncate(item.facility, limit: 80),
            limitText: String(item.limit),
            createdAtText: String(item.createdAt),
            discount: String(format: "%.2f", item.discount),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackReferralReservationViews(_ items: [FallbackReferralReservation]) -> [FallbackReferralReservationView] {
        var views: [FallbackReferralReservationView] = []
        for item in items {
            views.append(toFallbackReferralReservationView(item))
        }
        return views
    }

    static func sumFallbackReferralReservationView(_ view: FallbackReferralReservationView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRefills) + Double(parsedLimit) + Double(parsedCreatedAt)
    }
}
