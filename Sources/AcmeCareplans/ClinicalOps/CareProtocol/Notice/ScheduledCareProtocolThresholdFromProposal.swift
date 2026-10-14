import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAdaptiveCareProtocolProposalsForThreshold(_ items: [AdaptiveCareProtocolProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveScheduledCareProtocolThresholdsFromProposal(_ items: [AdaptiveCareProtocolProposal]) -> [ScheduledCareProtocolThreshold] {
        var out: [ScheduledCareProtocolThreshold] = []
        for item in items {
            let derived = newScheduledCareProtocolThreshold(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planScheduledCareProtocolThreshold(_ item: ScheduledCareProtocolThreshold) -> String {
        return adaptiveCareProtocolProposalBucket(item.measuredValue())
    }
}
