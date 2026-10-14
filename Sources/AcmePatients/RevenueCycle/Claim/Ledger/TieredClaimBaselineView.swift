import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered claim baseline.
    final class TieredClaimBaselineView {
        var codeText: String
        var label: String
        var ceilingText: String
        var country: String
        var weightText: String
        var rate: String
        var ownerIDText: String
        var statusLabel: String

        init(codeText: String, label: String, ceilingText: String, country: String, weightText: String, rate: String, ownerIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ceilingText = ceilingText
            self.country = country
            self.weightText = weightText
            self.rate = rate
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredClaimBaselineView(_ item: TieredClaimBaseline) -> TieredClaimBaselineView {
        return TieredClaimBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            ceilingText: String(format: "%.2f", item.ceiling),
            country: item.country,
            weightText: String(format: "%.2f", item.weight),
            rate: String(format: "%.2f", item.rate),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredClaimBaselineViews(_ items: [TieredClaimBaseline]) -> [TieredClaimBaselineView] {
        var views: [TieredClaimBaselineView] = []
        for item in items {
            views.append(toTieredClaimBaselineView(item))
        }
        return views
    }

    static func sumTieredClaimBaselineView(_ view: TieredClaimBaselineView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCeiling + parsedWeight + parsedRate
    }
}
