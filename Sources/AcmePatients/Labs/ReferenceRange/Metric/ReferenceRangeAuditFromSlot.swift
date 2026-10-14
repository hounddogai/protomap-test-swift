import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedSpecimenSlotsForAudit(_ items: [WeightedSpecimenSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveReferenceRangeAuditsFromSlot(_ items: [WeightedSpecimenSlot]) -> [ReferenceRangeAudit] {
        var out: [ReferenceRangeAudit] = []
        for item in items {
            let derived = newReferenceRangeAudit(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateReferenceRangeAudit(_ item: ReferenceRangeAudit) -> String {
        return classifyBatchedSpecimenBudget(item.adjustedTotal())
    }
}
