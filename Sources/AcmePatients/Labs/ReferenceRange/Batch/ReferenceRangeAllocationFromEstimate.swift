import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierEstimatesForAllocation(_ items: [CourierEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveReferenceRangeAllocationsFromEstimate(_ items: [CourierEstimate]) -> [ReferenceRangeAllocation] {
        var out: [ReferenceRangeAllocation] = []
        for item in items {
            let derived = newReferenceRangeAllocation(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignReferenceRangeAllocation(_ item: ReferenceRangeAllocation) -> String {
        return normalizeCourierEstimateCode(item.code)
    }
}
