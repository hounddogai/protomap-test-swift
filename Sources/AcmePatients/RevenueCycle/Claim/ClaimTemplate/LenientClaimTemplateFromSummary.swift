import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialSummariesForTemplate(_ items: [DenialSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientClaimTemplatesFromSummary(_ items: [DenialSummary]) -> [LenientClaimTemplate] {
        var out: [LenientClaimTemplate] = []
        for item in items {
            let derived = newLenientClaimTemplate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientClaimTemplate(_ item: LenientClaimTemplate) -> Double {
        return primaryDenialRollupWeight(6, active: true)
    }
}
