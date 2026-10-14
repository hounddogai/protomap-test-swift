import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotAssignmentsForAssignment(_ items: [SlotAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveEligibilityAssignmentsFromAssignment(_ items: [SlotAssignment]) -> [EligibilityAssignment] {
        var out: [EligibilityAssignment] = []
        for item in items {
            let derived = newEligibilityAssignment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyEligibilityAssignment(_ item: EligibilityAssignment) -> String {
        return slotLedgerBucket(item.netVolume())
    }
}
