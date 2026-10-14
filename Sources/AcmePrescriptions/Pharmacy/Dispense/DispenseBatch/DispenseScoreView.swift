import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense score.
    final class DispenseScoreView {
        var code: String
        var title: String
        var country: String
        var active: String
        var margin: String
        var region: String
        var rateText: String
        var visibleText: String
        var expiresAtText: String
        var limitText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, country: String, active: String, margin: String, region: String, rateText: String, visibleText: String, expiresAtText: String, limitText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.active = active
            self.margin = margin
            self.region = region
            self.rateText = rateText
            self.visibleText = visibleText
            self.expiresAtText = expiresAtText
            self.limitText = limitText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseScoreView(_ item: DispenseScore) -> DispenseScoreView {
        return DispenseScoreView(
            code: item.code,
            title: item.title,
            country: item.country,
            active: "\(item.active)",
            margin: String(format: "%.2f", item.margin),
            region: item.region,
            rateText: String(format: "%.2f", item.rate),
            visibleText: "\(item.visible)",
            expiresAtText: String(item.expiresAt),
            limitText: String(item.limit),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseScoreViews(_ items: [DispenseScore]) -> [DispenseScoreView] {
        var views: [DispenseScoreView] = []
        for item in items {
            views.append(toDispenseScoreView(item))
        }
        return views
    }

    static func sumDispenseScoreView(_ view: DispenseScoreView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMargin + parsedRate + Double(parsedExpiresAt)
    }
}
