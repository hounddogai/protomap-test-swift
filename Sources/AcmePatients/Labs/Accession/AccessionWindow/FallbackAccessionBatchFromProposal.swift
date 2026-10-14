import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultCourierProposalsForBatch(_ items: [DefaultCourierProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackAccessionBatchesFromProposal(_ items: [DefaultCourierProposal]) -> [FallbackAccessionBatch] {
        var out: [FallbackAccessionBatch] = []
        for item in items {
            let derived = newFallbackAccessionBatch(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackAccessionBatch(_ item: FallbackAccessionBatch) -> Double {
        return defaultCourierProposalWeight(6, active: true)
    }
}
