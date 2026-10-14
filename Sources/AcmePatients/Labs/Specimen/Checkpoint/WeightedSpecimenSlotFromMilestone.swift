import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeMilestonesForSlot(_ items: [ReferenceRangeMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveWeightedSpecimenSlotsFromMilestone(_ items: [ReferenceRangeMilestone]) -> [WeightedSpecimenSlot] {
        var out: [WeightedSpecimenSlot] = []
        for item in items {
            let derived = newWeightedSpecimenSlot(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planWeightedSpecimenSlot(_ item: WeightedSpecimenSlot) -> String {
        return classifyReferenceRangeMilestone(item.netTotal())
    }
}
