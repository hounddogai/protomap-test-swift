import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language tier.
    final class LanguageTierView {
        var code: String
        var titleText: String
        var windowDays: String
        var channel: String
        var region: String
        var statusLabel: String

        init(code: String, titleText: String, windowDays: String, channel: String, region: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDays = windowDays
            self.channel = channel
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageTierView(_ item: LanguageTier) -> LanguageTierView {
        return LanguageTierView(
            code: item.code,
            titleText: item.title,
            windowDays: String(item.windowDays),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            region: Kit.Text.truncate(item.region, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageTierViews(_ items: [LanguageTier]) -> [LanguageTierView] {
        var views: [LanguageTierView] = []
        for item in items {
            views.append(toLanguageTierView(item))
        }
        return views
    }

    static func sumLanguageTierView(_ view: LanguageTierView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
