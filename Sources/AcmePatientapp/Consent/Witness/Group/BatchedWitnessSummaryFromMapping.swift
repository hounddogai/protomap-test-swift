import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationMappingsForSummary(_ items: [RevocationMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveBatchedWitnessSummariesFromMapping(_ items: [RevocationMapping]) -> [BatchedWitnessSummary] {
        var out: [BatchedWitnessSummary] = []
        for item in items {
            let derived = newBatchedWitnessSummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchBatchedWitnessSummary(_ item: BatchedWitnessSummary) -> String {
        return classifyRevocationMapping(item.adjustedExposure())
    }
}
