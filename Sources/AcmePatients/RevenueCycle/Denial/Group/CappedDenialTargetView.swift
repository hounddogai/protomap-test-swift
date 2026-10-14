import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped denial target.
    final class CappedDenialTargetView {
        var codeText: String
        var name: String
        var activeText: String
        var ceiling: String
        var amount: String
        var regionText: String
        var graceDays: String
        var countryText: String
        var statusLabel: String

        init(codeText: String, name: String, activeText: String, ceiling: String, amount: String, regionText: String, graceDays: String, countryText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.activeText = activeText
            self.ceiling = ceiling
            self.amount = amount
            self.regionText = regionText
            self.graceDays = graceDays
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDenialTargetView(_ item: CappedDenialTarget) -> CappedDenialTargetView {
        return CappedDenialTargetView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            activeText: "\(item.active)",
            ceiling: String(format: "%.2f", item.ceiling),
            amount: String(format: "%.2f", item.amount),
            regionText: item.region,
            graceDays: String(item.graceDays),
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDenialTargetViews(_ items: [CappedDenialTarget]) -> [CappedDenialTargetView] {
        var views: [CappedDenialTargetView] = []
        for item in items {
            views.append(toCappedDenialTargetView(item))
        }
        return views
    }

    static func sumCappedDenialTargetView(_ view: CappedDenialTargetView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCeiling + parsedAmount + Double(parsedGraceDays)
    }
}
