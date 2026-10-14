import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRegionalOrderSetOverridesForRecord(_ items: [RegionalOrderSetOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTaskRecordsFromOverride(_ items: [RegionalOrderSetOverride]) -> [TaskRecord] {
        var out: [TaskRecord] = []
        for item in items {
            let derived = newTaskRecord(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeTaskRecord(_ item: TaskRecord) -> String {
        return classifyPendingOrderSetGroup(item.projectedVolume())
    }
}
