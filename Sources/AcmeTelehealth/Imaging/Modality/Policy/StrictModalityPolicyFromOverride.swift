import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityOverridesForPolicy(_ items: [PriorityOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveStrictModalityPoliciesFromOverride(_ items: [PriorityOverride]) -> [StrictModalityPolicy] {
        var out: [StrictModalityPolicy] = []
        for item in items {
            let derived = newStrictModalityPolicy(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeStrictModalityPolicy(_ item: StrictModalityPolicy) -> String {
        return classifyGlobalPriorityQuota(item.effectiveLoad())
    }
}
