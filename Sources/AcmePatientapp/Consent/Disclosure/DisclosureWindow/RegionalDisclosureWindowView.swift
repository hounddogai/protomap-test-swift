import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional disclosure window.
    final class RegionalDisclosureWindowView {
        var code: String
        var title: String
        var channel: String
        var graceDaysText: String
        var rate: String
        var statusLabel: String

        init(code: String, title: String, channel: String, graceDaysText: String, rate: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.channel = channel
            self.graceDaysText = graceDaysText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDisclosureWindowView(_ item: RegionalDisclosureWindow) -> RegionalDisclosureWindowView {
        return RegionalDisclosureWindowView(
            code: item.code,
            title: item.title,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            graceDaysText: String(item.graceDays),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDisclosureWindowViews(_ items: [RegionalDisclosureWindow]) -> [RegionalDisclosureWindowView] {
        var views: [RegionalDisclosureWindowView] = []
        for item in items {
            views.append(toRegionalDisclosureWindowView(item))
        }
        return views
    }

    static func sumRegionalDisclosureWindowView(_ view: RegionalDisclosureWindowView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedGraceDays) + parsedRate
    }
}
