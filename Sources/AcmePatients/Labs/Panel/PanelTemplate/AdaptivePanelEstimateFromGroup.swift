import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionGroupsForEstimate(_ items: [AccessionGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveAdaptivePanelEstimatesFromGroup(_ items: [AccessionGroup]) -> [AdaptivePanelEstimate] {
        var out: [AdaptivePanelEstimate] = []
        for item in items {
            let derived = newAdaptivePanelEstimate(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAdaptivePanelEstimate(_ item: AdaptivePanelEstimate) -> Double {
        return weightedAccessionMappingWeight(8, active: true)
    }
}
