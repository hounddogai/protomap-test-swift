import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up manifest.
    final class FollowUpManifestView {
        var codeText: String
        var titleText: String
        var locale: String
        var specialty: String
        var externalRef: String
        var cost: String
        var segment: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, titleText: String, locale: String, specialty: String, externalRef: String, cost: String, segment: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.locale = locale
            self.specialty = specialty
            self.externalRef = externalRef
            self.cost = cost
            self.segment = segment
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpManifestView(_ item: FollowUpManifest) -> FollowUpManifestView {
        return FollowUpManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            locale: item.locale,
            specialty: item.specialty,
            externalRef: item.externalRef,
            cost: String(format: "%.2f", item.cost),
            segment: item.segment,
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpManifestViews(_ items: [FollowUpManifest]) -> [FollowUpManifestView] {
        var views: [FollowUpManifestView] = []
        for item in items {
            views.append(toFollowUpManifestView(item))
        }
        return views
    }

    static func sumFollowUpManifestView(_ view: FollowUpManifestView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
