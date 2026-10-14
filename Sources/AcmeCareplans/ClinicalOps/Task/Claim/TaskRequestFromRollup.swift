import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertRollupsForRequest(_ items: [AlertRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTaskRequestsFromRollup(_ items: [AlertRollup]) -> [TaskRequest] {
        var out: [TaskRequest] = []
        for item in items {
            let derived = newTaskRequest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectTaskRequest(_ item: TaskRequest) -> Double {
        return primaryAlertMetricWeight(3, active: true)
    }
}
