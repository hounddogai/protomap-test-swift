import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetRequestsForAudit(_ items: [OrderSetRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTaskAuditsFromRequest(_ items: [OrderSetRequest]) -> [TaskAudit] {
        var out: [TaskAudit] = []
        for item in items {
            let derived = newTaskAudit(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveTaskAudit(_ item: TaskAudit) -> Double {
        return orderSetProfileWeight(3, active: true)
    }
}
