import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackTaskManifestsForRule(_ items: [FallbackTaskManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRoundingRulesFromManifest(_ items: [FallbackTaskManifest]) -> [RoundingRule] {
        var out: [RoundingRule] = []
        for item in items {
            let derived = newRoundingRule(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRoundingRule(_ item: RoundingRule) -> String {
        return classifyTaskPlan(item.projectedTotal())
    }
}
