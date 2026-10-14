import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedReferenceRangeAgreementsForSlot(_ items: [CappedReferenceRangeAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveReferenceRangeSlotsFromAgreement(_ items: [CappedReferenceRangeAgreement]) -> [ReferenceRangeSlot] {
        var out: [ReferenceRangeSlot] = []
        for item in items {
            let derived = newReferenceRangeSlot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleReferenceRangeSlot(_ item: ReferenceRangeSlot) -> String {
        return pendingReferenceRangeSummaryBucket(item.measuredValue())
    }
}
