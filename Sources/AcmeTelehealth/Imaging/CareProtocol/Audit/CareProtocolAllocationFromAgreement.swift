import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalPriorityAgreementsForAllocation(_ items: [GlobalPriorityAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveCareProtocolAllocationsFromAgreement(_ items: [GlobalPriorityAgreement]) -> [CareProtocolAllocation] {
        var out: [CareProtocolAllocation] = []
        for item in items {
            let derived = newCareProtocolAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCareProtocolAllocation(_ item: CareProtocolAllocation) -> String {
        return classifyGlobalPriorityAgreement(item.projectedExposure())
    }
}
