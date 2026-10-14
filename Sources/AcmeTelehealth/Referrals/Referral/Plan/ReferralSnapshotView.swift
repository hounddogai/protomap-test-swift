import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral snapshot.
    final class ReferralSnapshotView {
        var codeText: String
        var title: String
        var approved: String
        var region: String
        var windowDays: String
        var unit: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, title: String, approved: String, region: String, windowDays: String, unit: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.approved = approved
            self.region = region
            self.windowDays = windowDays
            self.unit = unit
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toReferralSnapshotView(_ item: ReferralSnapshot) -> ReferralSnapshotView {
        return ReferralSnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            approved: "\(item.approved)",
            region: item.region,
            windowDays: String(item.windowDays),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralSnapshotViews(_ items: [ReferralSnapshot]) -> [ReferralSnapshotView] {
        var views: [ReferralSnapshotView] = []
        for item in items {
            views.append(toReferralSnapshotView(item))
        }
        return views
    }

    static func sumReferralSnapshotView(_ view: ReferralSnapshotView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedSequence)
    }
}
