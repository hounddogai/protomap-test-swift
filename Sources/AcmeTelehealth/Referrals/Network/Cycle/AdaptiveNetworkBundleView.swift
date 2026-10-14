import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive network bundle.
    final class AdaptiveNetworkBundleView {
        var code: String
        var title: String
        var reviewerText: String
        var description: String
        var refills: String
        var updatedAt: String
        var summary: String
        var expiresAt: String
        var dosageMg: String
        var revisionText: String
        var phoneText: String
        var statusLabel: String

        init(code: String, title: String, reviewerText: String, description: String, refills: String, updatedAt: String, summary: String, expiresAt: String, dosageMg: String, revisionText: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewerText = reviewerText
            self.description = description
            self.refills = refills
            self.updatedAt = updatedAt
            self.summary = summary
            self.expiresAt = expiresAt
            self.dosageMg = dosageMg
            self.revisionText = revisionText
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveNetworkBundleView(_ item: AdaptiveNetworkBundle) -> AdaptiveNetworkBundleView {
        return AdaptiveNetworkBundleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            reviewerText: item.reviewer,
            description: item.description,
            refills: String(item.refills),
            updatedAt: String(item.updatedAt),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            expiresAt: String(item.expiresAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            revisionText: String(item.revision),
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveNetworkBundleViews(_ items: [AdaptiveNetworkBundle]) -> [AdaptiveNetworkBundleView] {
        var views: [AdaptiveNetworkBundleView] = []
        for item in items {
            views.append(toAdaptiveNetworkBundleView(item))
        }
        return views
    }

    static func sumAdaptiveNetworkBundleView(_ view: AdaptiveNetworkBundleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRefills) + Double(parsedUpdatedAt) + Double(parsedExpiresAt)
    }
}
