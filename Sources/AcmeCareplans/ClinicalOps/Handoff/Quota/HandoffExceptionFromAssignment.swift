import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertAssignmentsForException(_ items: [AlertAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveHandoffExceptionsFromAssignment(_ items: [AlertAssignment]) -> [HandoffException] {
        var out: [HandoffException] = []
        for item in items {
            let derived = newHandoffException(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeHandoffException(_ item: HandoffException) -> String {
        return normalizeAlertBatchCode(item.code)
    }
}
