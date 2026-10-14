import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback overtime policy.
    final class FallbackOvertimePolicyView {
        var code: String
        var nameText: String
        var windowDays: String
        var budget: String
        var ceiling: String
        var category: String
        var channel: String
        var dosageMgText: String
        var retries: String
        var statusLabel: String

        init(code: String, nameText: String, windowDays: String, budget: String, ceiling: String, category: String, channel: String, dosageMgText: String, retries: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.windowDays = windowDays
            self.budget = budget
            self.ceiling = ceiling
            self.category = category
            self.channel = channel
            self.dosageMgText = dosageMgText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackOvertimePolicyView(_ item: FallbackOvertimePolicy) -> FallbackOvertimePolicyView {
        return FallbackOvertimePolicyView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            windowDays: String(item.windowDays),
            budget: String(format: "%.2f", item.budget),
            ceiling: String(format: "%.2f", item.ceiling),
            category: item.category,
            channel: item.channel,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackOvertimePolicyViews(_ items: [FallbackOvertimePolicy]) -> [FallbackOvertimePolicyView] {
        var views: [FallbackOvertimePolicyView] = []
        for item in items {
            views.append(toFallbackOvertimePolicyView(item))
        }
        return views
    }

    static func sumFallbackOvertimePolicyView(_ view: FallbackOvertimePolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedWindowDays) + parsedBudget + parsedCeiling
    }
}
