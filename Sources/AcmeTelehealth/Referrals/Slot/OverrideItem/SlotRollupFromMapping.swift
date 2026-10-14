import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualClosureMappingsForRollup(_ items: [ManualClosureMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSlotRollupsFromMapping(_ items: [ManualClosureMapping]) -> [SlotRollup] {
        var out: [SlotRollup] = []
        for item in items {
            let derived = newSlotRollup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeSlotRollup(_ item: SlotRollup) -> Double {
        return cappedClosureMilestoneWeight(8, active: true)
    }
}
