import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedRevocationDigestsForBundle(_ items: [BatchedRevocationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveBatchedWitnessBundlesFromDigest(_ items: [BatchedRevocationDigest]) -> [BatchedWitnessBundle] {
        var out: [BatchedWitnessBundle] = []
        for item in items {
            let derived = newBatchedWitnessBundle(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceBatchedWitnessBundle(_ item: BatchedWitnessBundle) -> String {
        return classifyCappedRevocationBundle(item.measuredValue())
    }
}
