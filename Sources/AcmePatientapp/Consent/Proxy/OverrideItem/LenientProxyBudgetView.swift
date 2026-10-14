import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient proxy budget.
    final class LenientProxyBudgetView {
        var code: String
        var label: String
        var limitText: String
        var timezone: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, limitText: String, timezone: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limitText = limitText
            self.timezone = timezone
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProxyBudgetView(_ item: LenientProxyBudget) -> LenientProxyBudgetView {
        return LenientProxyBudgetView(
            code: item.code,
            label: item.label,
            limitText: String(item.limit),
            timezone: item.timezone,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProxyBudgetViews(_ items: [LenientProxyBudget]) -> [LenientProxyBudgetView] {
        var views: [LenientProxyBudgetView] = []
        for item in items {
            views.append(toLenientProxyBudgetView(item))
        }
        return views
    }

    static func sumLenientProxyBudgetView(_ view: LenientProxyBudgetView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedLimit) + parsedMinimum
    }
}
