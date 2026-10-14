import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityClaimsForMapping(_ items: [PriorityClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCappedModalityMappingsFromClaim(_ items: [PriorityClaim]) -> [CappedModalityMapping] {
        var out: [CappedModalityMapping] = []
        for item in items {
            let derived = newCappedModalityMapping(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCappedModalityMapping(_ item: CappedModalityMapping) -> String {
        return classifyPriorityMetric(item.netTotal())
    }
}
