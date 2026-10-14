import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolAssignmentsForRequest(_ items: [CareProtocolAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTaskRequestsFromAssignment(_ items: [CareProtocolAssignment]) -> [TaskRequest] {
        var out: [TaskRequest] = []
        for item in items {
            let derived = newTaskRequest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveTaskRequest(_ item: TaskRequest) -> Double {
        return careProtocolAssignmentWeight(8, active: true)
    }
}
