import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive panel digest.
    final class AdaptivePanelDigestView {
        var code: String
        var title: String
        var startsAtText: String
        var costText: String
        var summary: String
        var phone: String
        var rateText: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, title: String, startsAtText: String, costText: String, summary: String, phone: String, rateText: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.startsAtText = startsAtText
            self.costText = costText
            self.summary = summary
            self.phone = phone
            self.rateText = rateText
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePanelDigestView(_ item: AdaptivePanelDigest) -> AdaptivePanelDigestView {
        return AdaptivePanelDigestView(
            code: item.code,
            title: item.title,
            startsAtText: String(item.startsAt),
            costText: String(format: "%.2f", item.cost),
            summary: item.summary,
            phone: Kit.Text.truncate(item.phone, limit: 40),
            rateText: String(format: "%.2f", item.rate),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePanelDigestViews(_ items: [AdaptivePanelDigest]) -> [AdaptivePanelDigestView] {
        var views: [AdaptivePanelDigestView] = []
        for item in items {
            views.append(toAdaptivePanelDigestView(item))
        }
        return views
    }

    static func sumAdaptivePanelDigestView(_ view: AdaptivePanelDigestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedStartsAt) + parsedCost + parsedRate
    }
}
