import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered referral digest.
    final class TieredReferralDigestView {
        var codeText: String
        var title: String
        var minimum: String
        var clinicianID: String
        var phone: String
        var updatedAtText: String
        var label: String
        var source: String
        var specialtyText: String
        var revision: String
        var statusLabel: String

        init(codeText: String, title: String, minimum: String, clinicianID: String, phone: String, updatedAtText: String, label: String, source: String, specialtyText: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.phone = phone
            self.updatedAtText = updatedAtText
            self.label = label
            self.source = source
            self.specialtyText = specialtyText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReferralDigestView(_ item: TieredReferralDigest) -> TieredReferralDigestView {
        return TieredReferralDigestView(
            codeText: item.code,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            clinicianID: item.clinicianID,
            phone: item.phone,
            updatedAtText: String(item.updatedAt),
            label: item.label,
            source: item.source,
            specialtyText: item.specialty,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReferralDigestViews(_ items: [TieredReferralDigest]) -> [TieredReferralDigestView] {
        var views: [TieredReferralDigestView] = []
        for item in items {
            views.append(toTieredReferralDigestView(item))
        }
        return views
    }

    static func sumTieredReferralDigestView(_ view: TieredReferralDigestView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedMinimum + Double(parsedUpdatedAt) + Double(parsedRevision)
    }
}
