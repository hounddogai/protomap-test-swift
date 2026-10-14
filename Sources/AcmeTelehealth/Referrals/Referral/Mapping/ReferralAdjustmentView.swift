import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral adjustment.
    final class ReferralAdjustmentView {
        var code: String
        var nameText: String
        var ward: String
        var contactEmail: String
        var unitText: String
        var pinnedText: String
        var refills: String
        var payerText: String
        var dosageMg: String
        var country: String
        var statusLabel: String

        init(code: String, nameText: String, ward: String, contactEmail: String, unitText: String, pinnedText: String, refills: String, payerText: String, dosageMg: String, country: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ward = ward
            self.contactEmail = contactEmail
            self.unitText = unitText
            self.pinnedText = pinnedText
            self.refills = refills
            self.payerText = payerText
            self.dosageMg = dosageMg
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toReferralAdjustmentView(_ item: ReferralAdjustment) -> ReferralAdjustmentView {
        return ReferralAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            ward: Kit.Text.truncate(item.ward, limit: 64),
            contactEmail: item.contactEmail,
            unitText: item.unit,
            pinnedText: "\(item.pinned)",
            refills: String(item.refills),
            payerText: item.payer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralAdjustmentViews(_ items: [ReferralAdjustment]) -> [ReferralAdjustmentView] {
        var views: [ReferralAdjustmentView] = []
        for item in items {
            views.append(toReferralAdjustmentView(item))
        }
        return views
    }

    static func sumReferralAdjustmentView(_ view: ReferralAdjustmentView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRefills) + parsedDosageMg
    }
}
