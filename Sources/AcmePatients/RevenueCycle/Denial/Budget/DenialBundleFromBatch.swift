import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientClaimBatchesForBundle(_ items: [LenientClaimBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveDenialBundlesFromBatch(_ items: [LenientClaimBatch]) -> [DenialBundle] {
        var out: [DenialBundle] = []
        for item in items {
            let derived = newDenialBundle(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeDenialBundle(_ item: DenialBundle) -> Double {
        return tieredClaimMetricWeight(4, active: true)
    }
}
