import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingEligibilitySlotsForRollup(_ items: [PendingEligibilitySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveClosureRollupsFromSlot(_ items: [PendingEligibilitySlot]) -> [ClosureRollup] {
        var out: [ClosureRollup] = []
        for item in items {
            let derived = newClosureRollup(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateClosureRollup(_ item: ClosureRollup) -> String {
        return classifyEligibilityClaim(item.adjustedTotal())
    }
}
