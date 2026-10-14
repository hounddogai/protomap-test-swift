import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolMilestonesForSnapshot(_ items: [CareProtocolMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRoundingSnapshotsFromMilestone(_ items: [CareProtocolMilestone]) -> [RoundingSnapshot] {
        var out: [RoundingSnapshot] = []
        for item in items {
            let derived = newRoundingSnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRoundingSnapshot(_ item: RoundingSnapshot) -> String {
        return classifyCareProtocolMilestone(item.adjustedExposure())
    }
}
