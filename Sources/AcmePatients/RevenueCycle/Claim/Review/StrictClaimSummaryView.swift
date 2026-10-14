import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict claim summary.
    final class StrictClaimSummaryView {
        var codeText: String
        var title: String
        var source: String
        var summary: String
        var expiresAtText: String
        var version: String
        var updatedAt: String
        var startsAtText: String
        var label: String
        var statusLabel: String

        init(codeText: String, title: String, source: String, summary: String, expiresAtText: String, version: String, updatedAt: String, startsAtText: String, label: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.source = source
            self.summary = summary
            self.expiresAtText = expiresAtText
            self.version = version
            self.updatedAt = updatedAt
            self.startsAtText = startsAtText
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toStrictClaimSummaryView(_ item: StrictClaimSummary) -> StrictClaimSummaryView {
        return StrictClaimSummaryView(
            codeText: item.code,
            title: item.title,
            source: Kit.Text.truncate(item.source, limit: 64),
            summary: item.summary,
            expiresAtText: String(item.expiresAt),
            version: String(item.version),
            updatedAt: String(item.updatedAt),
            startsAtText: String(item.startsAt),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictClaimSummaryViews(_ items: [StrictClaimSummary]) -> [StrictClaimSummaryView] {
        var views: [StrictClaimSummaryView] = []
        for item in items {
            views.append(toStrictClaimSummaryView(item))
        }
        return views
    }

    static func sumStrictClaimSummaryView(_ view: StrictClaimSummaryView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedVersion) + Double(parsedUpdatedAt)
    }
}
