import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeBatchedOvertimeMappingsForProposal(_ items: [BatchedOvertimeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveWeightedAcuityPlanProposalsFromMapping(_ items: [BatchedOvertimeMapping]) -> [WeightedAcuityPlanProposal] {
        var out: [WeightedAcuityPlanProposal] = []
        for item in items {
            let derived = newWeightedAcuityPlanProposal(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeWeightedAcuityPlanProposal(_ item: WeightedAcuityPlanProposal) -> String {
        return classifyLegacyOvertimeSnapshot(item.projectedValue())
    }
}
