import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackOutreachRulesForRule(_ items: [FallbackOutreachRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveFallbackRiskScoreRulesFromRule(_ items: [FallbackOutreachRule]) -> [FallbackRiskScoreRule] {
        var out: [FallbackRiskScoreRule] = []
        for item in items {
            let derived = newFallbackRiskScoreRule(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeFallbackRiskScoreRule(_ item: FallbackRiskScoreRule) -> String {
        return fallbackOutreachRuleBucket(item.adjustedExposure())
    }
}
