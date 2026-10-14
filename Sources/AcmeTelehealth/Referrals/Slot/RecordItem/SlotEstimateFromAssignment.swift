import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureAssignmentsForEstimate(_ items: [ClosureAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveSlotEstimatesFromAssignment(_ items: [ClosureAssignment]) -> [SlotEstimate] {
        var out: [SlotEstimate] = []
        for item in items {
            let derived = newSlotEstimate(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitSlotEstimate(_ item: SlotEstimate) -> String {
        return normalizeClosureNoticeCode(item.code)
    }
}
