import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLenientEligibilityEstimatesForCheckpoint(_ items: [LenientEligibilityEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveClosureCheckpointsFromEstimate(_ items: [LenientEligibilityEstimate]) -> [ClosureCheckpoint] {
        var out: [ClosureCheckpoint] = []
        for item in items {
            let derived = newClosureCheckpoint(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateClosureCheckpoint(_ item: ClosureCheckpoint) -> Double {
        return pendingEligibilityForecastWeight(4, active: true)
    }
}
