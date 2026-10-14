import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeManualCareProtocolBundlesForAllocation(_ items: [ManualCareProtocolBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedStudyAllocationsFromBundle(_ items: [ManualCareProtocolBundle]) -> [CappedStudyAllocation] {
        var out: [CappedStudyAllocation] = []
        for item in items {
            let derived = newCappedStudyAllocation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCappedStudyAllocation(_ item: CappedStudyAllocation) -> String {
        return manualCareProtocolBundleBucket(item.measuredValue())
    }
}
