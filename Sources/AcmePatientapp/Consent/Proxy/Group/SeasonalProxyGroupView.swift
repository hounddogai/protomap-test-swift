import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal proxy group.
    final class SeasonalProxyGroupView {
        var codeText: String
        var titleText: String
        var active: String
        var weight: String
        var updatedAtText: String
        var summary: String
        var refills: String
        var pinned: String
        var statusLabel: String

        init(codeText: String, titleText: String, active: String, weight: String, updatedAtText: String, summary: String, refills: String, pinned: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.active = active
            self.weight = weight
            self.updatedAtText = updatedAtText
            self.summary = summary
            self.refills = refills
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalProxyGroupView(_ item: SeasonalProxyGroup) -> SeasonalProxyGroupView {
        return SeasonalProxyGroupView(
            codeText: item.code,
            titleText: item.title,
            active: "\(item.active)",
            weight: String(format: "%.2f", item.weight),
            updatedAtText: String(item.updatedAt),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            refills: String(item.refills),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalProxyGroupViews(_ items: [SeasonalProxyGroup]) -> [SeasonalProxyGroupView] {
        var views: [SeasonalProxyGroupView] = []
        for item in items {
            views.append(toSeasonalProxyGroupView(item))
        }
        return views
    }

    static func sumSeasonalProxyGroupView(_ view: SeasonalProxyGroupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedWeight + Double(parsedUpdatedAt) + Double(parsedRefills)
    }
}
