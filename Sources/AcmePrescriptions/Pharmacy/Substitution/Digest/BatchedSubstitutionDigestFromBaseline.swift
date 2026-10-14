import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionBaselinesForDigest(_ items: [SubstitutionBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedSubstitutionDigestsFromBaseline(_ items: [SubstitutionBaseline]) -> [BatchedSubstitutionDigest] {
        var out: [BatchedSubstitutionDigest] = []
        for item in items {
            let derived = newBatchedSubstitutionDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedSubstitutionDigest(_ item: BatchedSubstitutionDigest) -> Double {
        return manualSubstitutionQuotaWeight(9, active: true)
    }
}
