import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualFormularyAllocationsForDigest(_ items: [ManualFormularyAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFallbackInteractionDigestsFromAllocation(_ items: [ManualFormularyAllocation]) -> [FallbackInteractionDigest] {
        var out: [FallbackInteractionDigest] = []
        for item in items {
            let derived = newFallbackInteractionDigest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchFallbackInteractionDigest(_ item: FallbackInteractionDigest) -> String {
        return fallbackFormularyAgreementBucket(item.netLoad())
    }
}
