import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback denial rule.
    final class FallbackDenialRuleView {
        var code: String
        var label: String
        var expiresAtText: String
        var activeText: String
        var weight: String
        var phoneText: String
        var windowDays: String
        var statusLabel: String

        init(code: String, label: String, expiresAtText: String, activeText: String, weight: String, phoneText: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAtText = expiresAtText
            self.activeText = activeText
            self.weight = weight
            self.phoneText = phoneText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDenialRuleView(_ item: FallbackDenialRule) -> FallbackDenialRuleView {
        return FallbackDenialRuleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            expiresAtText: String(item.expiresAt),
            activeText: "\(item.active)",
            weight: String(format: "%.2f", item.weight),
            phoneText: item.phone,
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDenialRuleViews(_ items: [FallbackDenialRule]) -> [FallbackDenialRuleView] {
        var views: [FallbackDenialRuleView] = []
        for item in items {
            views.append(toFallbackDenialRuleView(item))
        }
        return views
    }

    static func sumFallbackDenialRuleView(_ view: FallbackDenialRuleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedExpiresAt) + parsedWeight + Double(parsedWindowDays)
    }
}
