import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped referral snapshot.
    final class CappedReferralSnapshotView {
        var codeText: String
        var nameText: String
        var graceDays: String
        var localeText: String
        var facilityText: String
        var statusLabel: String

        init(codeText: String, nameText: String, graceDays: String, localeText: String, facilityText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.graceDays = graceDays
            self.localeText = localeText
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReferralSnapshotView(_ item: CappedReferralSnapshot) -> CappedReferralSnapshotView {
        return CappedReferralSnapshotView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            graceDays: String(item.graceDays),
            localeText: item.locale,
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReferralSnapshotViews(_ items: [CappedReferralSnapshot]) -> [CappedReferralSnapshotView] {
        var views: [CappedReferralSnapshotView] = []
        for item in items {
            views.append(toCappedReferralSnapshotView(item))
        }
        return views
    }

    static func sumCappedReferralSnapshotView(_ view: CappedReferralSnapshotView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
