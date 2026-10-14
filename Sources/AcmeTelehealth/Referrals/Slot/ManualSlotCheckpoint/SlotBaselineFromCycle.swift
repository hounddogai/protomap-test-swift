import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeGlobalReferralCyclesForBaseline(_ items: [GlobalReferralCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSlotBaselinesFromCycle(_ items: [GlobalReferralCycle]) -> [SlotBaseline] {
        var out: [SlotBaseline] = []
        for item in items {
            let derived = newSlotBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankSlotBaseline(_ item: SlotBaseline) -> String {
        return normalizeBatchedReferralDraftCode(item.code)
    }
}
