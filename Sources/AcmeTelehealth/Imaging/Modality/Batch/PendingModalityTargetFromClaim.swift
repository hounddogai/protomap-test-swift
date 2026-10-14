import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptivePriorityClaimsForTarget(_ items: [AdaptivePriorityClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func derivePendingModalityTargetsFromClaim(_ items: [AdaptivePriorityClaim]) -> [PendingModalityTarget] {
        var out: [PendingModalityTarget] = []
        for item in items {
            let derived = newPendingModalityTarget(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyPendingModalityTarget(_ item: PendingModalityTarget) -> String {
        return normalizeSeasonalPriorityRuleCode(item.code)
    }
}
