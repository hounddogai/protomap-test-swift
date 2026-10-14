import AcmePlatform
import Foundation

extension Labs {
    static func summarizeBatchedAccessionNoticesForSlot(_ items: [BatchedAccessionNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRegionalReferenceRangeSlotsFromNotice(_ items: [BatchedAccessionNotice]) -> [RegionalReferenceRangeSlot] {
        var out: [RegionalReferenceRangeSlot] = []
        for item in items {
            let derived = newRegionalReferenceRangeSlot(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRegionalReferenceRangeSlot(_ item: RegionalReferenceRangeSlot) -> Double {
        return regionalAccessionScheduleWeight(6, active: true)
    }
}
