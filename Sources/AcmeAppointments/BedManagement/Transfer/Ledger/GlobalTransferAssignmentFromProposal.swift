import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardProposalsForAssignment(_ items: [BedBoardProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveGlobalTransferAssignmentsFromProposal(_ items: [BedBoardProposal]) -> [GlobalTransferAssignment] {
        var out: [GlobalTransferAssignment] = []
        for item in items {
            let derived = newGlobalTransferAssignment(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateGlobalTransferAssignment(_ item: GlobalTransferAssignment) -> String {
        return regionalBedBoardAllocationBucket(item.weightedTotal())
    }
}
