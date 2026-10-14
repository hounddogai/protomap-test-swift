import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingSpecimenCyclesForSlot(_ items: [PendingSpecimenCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRegionalReferenceRangeSlotsFromCycle(_ items: [PendingSpecimenCycle]) -> [RegionalReferenceRangeSlot] {
        var out: [RegionalReferenceRangeSlot] = []
        for item in items {
            let derived = newRegionalReferenceRangeSlot(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleRegionalReferenceRangeSlot(_ item: RegionalReferenceRangeSlot) -> String {
        return classifyLenientSpecimenMilestone(item.weightedExposure())
    }
}
