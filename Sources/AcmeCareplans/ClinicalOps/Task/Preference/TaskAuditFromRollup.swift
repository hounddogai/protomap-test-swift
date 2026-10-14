import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledAlertRollupsForAudit(_ items: [ScheduledAlertRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveTaskAuditsFromRollup(_ items: [ScheduledAlertRollup]) -> [TaskAudit] {
        var out: [TaskAudit] = []
        for item in items {
            let derived = newTaskAudit(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignTaskAudit(_ item: TaskAudit) -> Double {
        return manualAlertRecordWeight(4, active: true)
    }
}
