import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingHandoffBaselinesForRecord(_ items: [PendingHandoffBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveTaskRecordsFromBaseline(_ items: [PendingHandoffBaseline]) -> [TaskRecord] {
        var out: [TaskRecord] = []
        for item in items {
            let derived = newTaskRecord(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyTaskRecord(_ item: TaskRecord) -> Double {
        return pendingHandoffBaselineWeight(8, active: true)
    }
}
