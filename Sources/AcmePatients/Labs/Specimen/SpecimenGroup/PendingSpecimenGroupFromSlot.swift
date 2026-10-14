import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSlotsForGroup(_ items: [ReferenceRangeSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingSpecimenGroupsFromSlot(_ items: [ReferenceRangeSlot]) -> [PendingSpecimenGroup] {
        var out: [PendingSpecimenGroup] = []
        for item in items {
            let derived = newPendingSpecimenGroup(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingSpecimenGroup(_ item: PendingSpecimenGroup) -> String {
        return normalizeLegacyReferenceRangeProfileCode(item.code)
    }

    static func summarizeDefaultCourierSlotsForGroup(_ items: [DefaultCourierSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePendingSpecimenGroupsFromSlotExtra(_ items: [DefaultCourierSlot]) -> [PendingSpecimenGroup] {
        var out: [PendingSpecimenGroup] = []
        for item in items {
            let derived = newPendingSpecimenGroup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planPendingSpecimenGroup(_ item: PendingSpecimenGroup) -> Double {
        return defaultCourierSlotWeight(7, active: true)
    }
}
