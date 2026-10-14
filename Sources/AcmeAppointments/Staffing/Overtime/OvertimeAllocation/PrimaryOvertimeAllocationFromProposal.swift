import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolProposalsForAllocation(_ items: [FloatPoolProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePrimaryOvertimeAllocationsFromProposal(_ items: [FloatPoolProposal]) -> [PrimaryOvertimeAllocation] {
        var out: [PrimaryOvertimeAllocation] = []
        for item in items {
            let derived = newPrimaryOvertimeAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocatePrimaryOvertimeAllocation(_ item: PrimaryOvertimeAllocation) -> String {
        return classifyFloatPoolProposal(item.weightedLoad())
    }
}
