import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertForecastsForRule(_ items: [AlertForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTaskRulesFromForecast(_ items: [AlertForecast]) -> [TaskRule] {
        var out: [TaskRule] = []
        for item in items {
            let derived = newTaskRule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectTaskRule(_ item: TaskRule) -> Double {
        return alertSummaryWeight(5, active: true)
    }
}
