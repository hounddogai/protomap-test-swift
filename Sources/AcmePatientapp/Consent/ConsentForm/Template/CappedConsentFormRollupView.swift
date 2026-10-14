import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped consent form rollup.
    final class CappedConsentFormRollupView {
        var code: String
        var label: String
        var ceilingText: String
        var budget: String
        var region: String
        var maximum: String
        var attemptsText: String
        var visitMinutesText: String
        var capacity: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, budget: String, region: String, maximum: String, attemptsText: String, visitMinutesText: String, capacity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.budget = budget
            self.region = region
            self.maximum = maximum
            self.attemptsText = attemptsText
            self.visitMinutesText = visitMinutesText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toCappedConsentFormRollupView(_ item: CappedConsentFormRollup) -> CappedConsentFormRollupView {
        return CappedConsentFormRollupView(
            code: item.code,
            label: item.label,
            ceilingText: String(format: "%.2f", item.ceiling),
            budget: String(format: "%.2f", item.budget),
            region: item.region,
            maximum: String(format: "%.2f", item.maximum),
            attemptsText: String(item.attempts),
            visitMinutesText: String(item.visitMinutes),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedConsentFormRollupViews(_ items: [CappedConsentFormRollup]) -> [CappedConsentFormRollupView] {
        var views: [CappedConsentFormRollupView] = []
        for item in items {
            views.append(toCappedConsentFormRollupView(item))
        }
        return views
    }

    static func sumCappedConsentFormRollupView(_ view: CappedConsentFormRollupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedBudget + parsedMaximum
    }
}
