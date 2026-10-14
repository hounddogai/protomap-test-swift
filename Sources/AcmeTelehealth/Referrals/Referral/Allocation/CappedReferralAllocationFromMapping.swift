import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotMappingsForAllocation(_ items: [SlotMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveCappedReferralAllocationsFromMapping(_ items: [SlotMapping]) -> [CappedReferralAllocation] {
        var out: [CappedReferralAllocation] = []
        for item in items {
            let derived = newCappedReferralAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedReferralAllocation(_ item: CappedReferralAllocation) -> Double {
        return slotRequestWeight(1, active: true)
    }
}
