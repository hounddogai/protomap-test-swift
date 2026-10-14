import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanForecastsForRule(_ items: [DischargePlanForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCleaningRulesFromForecast(_ items: [DischargePlanForecast]) -> [CleaningRule] {
        var out: [CleaningRule] = []
        for item in items {
            let derived = newCleaningRule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCleaningRule(_ item: CleaningRule) -> String {
        return classifyDischargePlanMilestone(item.adjustedLoad())
    }
}
