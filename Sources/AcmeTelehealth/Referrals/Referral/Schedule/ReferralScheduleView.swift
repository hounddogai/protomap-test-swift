import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral schedule.
    final class ReferralScheduleView {
        var code: String
        var name: String
        var threshold: String
        var encounterIDText: String
        var summary: String
        var contactEmail: String
        var specialtyText: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, threshold: String, encounterIDText: String, summary: String, contactEmail: String, specialtyText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.encounterIDText = encounterIDText
            self.summary = summary
            self.contactEmail = contactEmail
            self.specialtyText = specialtyText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toReferralScheduleView(_ item: ReferralSchedule) -> ReferralScheduleView {
        return ReferralScheduleView(
            code: item.code,
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            encounterIDText: item.encounterID,
            summary: item.summary,
            contactEmail: item.contactEmail,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 120),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralScheduleViews(_ items: [ReferralSchedule]) -> [ReferralScheduleView] {
        var views: [ReferralScheduleView] = []
        for item in items {
            views.append(toReferralScheduleView(item))
        }
        return views
    }

    static func sumReferralScheduleView(_ view: ReferralScheduleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedThreshold + Double(parsedQuantity)
    }
}
