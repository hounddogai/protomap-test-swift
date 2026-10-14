import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeDefaultCareProtocolRecordsForPreference(_ items: [DefaultCareProtocolRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTaskPreferencesFromRecord(_ items: [DefaultCareProtocolRecord]) -> [TaskPreference] {
        var out: [TaskPreference] = []
        for item in items {
            let derived = newTaskPreference(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planTaskPreference(_ item: TaskPreference) -> String {
        return careProtocolExceptionBucket(item.projectedExposure())
    }
}
