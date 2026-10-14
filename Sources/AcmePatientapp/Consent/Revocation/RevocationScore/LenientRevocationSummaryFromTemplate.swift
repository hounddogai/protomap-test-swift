import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLegacyProxyTemplatesForSummary(_ items: [LegacyProxyTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLenientRevocationSummariesFromTemplate(_ items: [LegacyProxyTemplate]) -> [LenientRevocationSummary] {
        var out: [LenientRevocationSummary] = []
        for item in items {
            let derived = newLenientRevocationSummary(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLenientRevocationSummary(_ item: LenientRevocationSummary) -> String {
        return classifyWeightedProxyGroup(item.measuredValue())
    }
}
