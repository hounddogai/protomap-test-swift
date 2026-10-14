import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultInteractionAssignmentsForRollup(_ items: [DefaultInteractionAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePendingRecallRollupsFromAssignment(_ items: [DefaultInteractionAssignment]) -> [PendingRecallRollup] {
        var out: [PendingRecallRollup] = []
        for item in items {
            let derived = newPendingRecallRollup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePendingRecallRollup(_ item: PendingRecallRollup) -> String {
        return normalizeDefaultInteractionAssignmentCode(item.code)
    }
}
