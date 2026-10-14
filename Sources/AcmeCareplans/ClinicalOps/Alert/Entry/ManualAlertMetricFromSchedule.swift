import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledCareProtocolSchedulesForMetric(_ items: [ScheduledCareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualAlertMetricsFromSchedule(_ items: [ScheduledCareProtocolSchedule]) -> [ManualAlertMetric] {
        var out: [ManualAlertMetric] = []
        for item in items {
            let derived = newManualAlertMetric(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankManualAlertMetric(_ item: ManualAlertMetric) -> String {
        return normalizeScheduledCareProtocolScheduleCode(item.code)
    }
}
