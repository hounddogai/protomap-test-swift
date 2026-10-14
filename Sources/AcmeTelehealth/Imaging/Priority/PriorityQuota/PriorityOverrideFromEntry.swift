import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeFallbackModalityEntriesForOverride(_ items: [FallbackModalityEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePriorityOverridesFromEntry(_ items: [FallbackModalityEntry]) -> [PriorityOverride] {
        var out: [PriorityOverride] = []
        for item in items {
            let derived = newPriorityOverride(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPriorityOverride(_ item: PriorityOverride) -> Double {
        return modalityDigestWeight(5, active: true)
    }
}
