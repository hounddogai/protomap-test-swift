import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackDischargePlanProposalsForEstimate(_ items: [FallbackDischargePlanProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualCleaningEstimatesFromProposal(_ items: [FallbackDischargePlanProposal]) -> [ManualCleaningEstimate] {
        var out: [ManualCleaningEstimate] = []
        for item in items {
            let derived = newManualCleaningEstimate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileManualCleaningEstimate(_ item: ManualCleaningEstimate) -> String {
        return dischargePlanProposalBucket(item.adjustedValue())
    }
}
