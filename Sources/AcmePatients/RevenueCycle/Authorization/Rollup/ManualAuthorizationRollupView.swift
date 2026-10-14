import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual authorization rollup.
    final class ManualAuthorizationRollupView {
        var code: String
        var labelText: String
        var ownerIDText: String
        var copay: String
        var approvedText: String
        var maximumText: String
        var categoryText: String
        var channel: String
        var segment: String
        var rate: String
        var locale: String
        var statusLabel: String

        init(code: String, labelText: String, ownerIDText: String, copay: String, approvedText: String, maximumText: String, categoryText: String, channel: String, segment: String, rate: String, locale: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ownerIDText = ownerIDText
            self.copay = copay
            self.approvedText = approvedText
            self.maximumText = maximumText
            self.categoryText = categoryText
            self.channel = channel
            self.segment = segment
            self.rate = rate
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toManualAuthorizationRollupView(_ item: ManualAuthorizationRollup) -> ManualAuthorizationRollupView {
        return ManualAuthorizationRollupView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            ownerIDText: item.ownerID,
            copay: String(format: "%.2f", item.copay),
            approvedText: "\(item.approved)",
            maximumText: String(format: "%.2f", item.maximum),
            categoryText: item.category,
            channel: item.channel,
            segment: item.segment,
            rate: String(format: "%.2f", item.rate),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAuthorizationRollupViews(_ items: [ManualAuthorizationRollup]) -> [ManualAuthorizationRollupView] {
        var views: [ManualAuthorizationRollupView] = []
        for item in items {
            views.append(toManualAuthorizationRollupView(item))
        }
        return views
    }

    static func sumManualAuthorizationRollupView(_ view: ManualAuthorizationRollupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCopay + parsedMaximum + parsedRate
    }
}
