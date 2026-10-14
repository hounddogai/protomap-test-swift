import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingModalityPoliciesForBaseline(_ items: [PendingModalityPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRegionalStudyBaselinesFromPolicy(_ items: [PendingModalityPolicy]) -> [RegionalStudyBaseline] {
        var out: [RegionalStudyBaseline] = []
        for item in items {
            let derived = newRegionalStudyBaseline(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalStudyBaseline(_ item: RegionalStudyBaseline) -> String {
        return classifyModalityBudget(item.projectedTotal())
    }
}
