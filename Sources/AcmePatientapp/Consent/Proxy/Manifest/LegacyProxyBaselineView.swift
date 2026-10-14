import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy proxy baseline.
    final class LegacyProxyBaselineView {
        var code: String
        var labelText: String
        var bed: String
        var segment: String
        var amount: String
        var maximumText: String
        var statusLabel: String

        init(code: String, labelText: String, bed: String, segment: String, amount: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.bed = bed
            self.segment = segment
            self.amount = amount
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyProxyBaselineView(_ item: LegacyProxyBaseline) -> LegacyProxyBaselineView {
        return LegacyProxyBaselineView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            bed: item.bed,
            segment: item.segment,
            amount: String(format: "%.2f", item.amount),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyProxyBaselineViews(_ items: [LegacyProxyBaseline]) -> [LegacyProxyBaselineView] {
        var views: [LegacyProxyBaselineView] = []
        for item in items {
            views.append(toLegacyProxyBaselineView(item))
        }
        return views
    }

    static func sumLegacyProxyBaselineView(_ view: LegacyProxyBaselineView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedAmount + parsedMaximum
    }
}
