import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy proxy template.
    final class LegacyProxyTemplateView {
        var codeText: String
        var titleText: String
        var thresholdText: String
        var wardText: String
        var category: String
        var currency: String
        var durationMinutesText: String
        var statusLabel: String

        init(codeText: String, titleText: String, thresholdText: String, wardText: String, category: String, currency: String, durationMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.thresholdText = thresholdText
            self.wardText = wardText
            self.category = category
            self.currency = currency
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyProxyTemplateView(_ item: LegacyProxyTemplate) -> LegacyProxyTemplateView {
        return LegacyProxyTemplateView(
            codeText: item.code,
            titleText: item.title,
            thresholdText: String(format: "%.2f", item.threshold),
            wardText: item.ward,
            category: item.category,
            currency: Kit.Text.truncate(item.currency, limit: 120),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyProxyTemplateViews(_ items: [LegacyProxyTemplate]) -> [LegacyProxyTemplateView] {
        var views: [LegacyProxyTemplateView] = []
        for item in items {
            views.append(toLegacyProxyTemplateView(item))
        }
        return views
    }

    static func sumLegacyProxyTemplateView(_ view: LegacyProxyTemplateView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes)
    }
}
