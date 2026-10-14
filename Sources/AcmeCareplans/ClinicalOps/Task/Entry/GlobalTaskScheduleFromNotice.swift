import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertNoticesForSchedule(_ items: [AlertNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveGlobalTaskSchedulesFromNotice(_ items: [AlertNotice]) -> [GlobalTaskSchedule] {
        var out: [GlobalTaskSchedule] = []
        for item in items {
            let derived = newGlobalTaskSchedule(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }
}
