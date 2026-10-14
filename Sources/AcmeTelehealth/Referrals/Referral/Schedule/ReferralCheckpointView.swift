import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral checkpoint.
    final class ReferralCheckpointView {
        var codeText: String
        var name: String
        var ratioText: String
        var pinned: String
        var versionText: String
        var statusLabel: String

        init(codeText: String, name: String, ratioText: String, pinned: String, versionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ratioText = ratioText
            self.pinned = pinned
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toReferralCheckpointView(_ item: ReferralCheckpoint) -> ReferralCheckpointView {
        return ReferralCheckpointView(
            codeText: item.code,
            name: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            pinned: "\(item.pinned)",
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralCheckpointViews(_ items: [ReferralCheckpoint]) -> [ReferralCheckpointView] {
        var views: [ReferralCheckpointView] = []
        for item in items {
            views.append(toReferralCheckpointView(item))
        }
        return views
    }

    static func sumReferralCheckpointView(_ view: ReferralCheckpointView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRatio + Double(parsedVersion)
    }
}
