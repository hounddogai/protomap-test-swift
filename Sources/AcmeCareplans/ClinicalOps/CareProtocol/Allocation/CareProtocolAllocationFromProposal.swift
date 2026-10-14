import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedHandoffProposalsForAllocation(_ items: [CappedHandoffProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveCareProtocolAllocationsFromProposal(_ items: [CappedHandoffProposal]) -> [CareProtocolAllocation] {
        var out: [CareProtocolAllocation] = []
        for item in items {
            let derived = newCareProtocolAllocation(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateCareProtocolAllocation(_ item: CareProtocolAllocation) -> String {
        return normalizeCappedHandoffMappingCode(item.code)
    }
}
