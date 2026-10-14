import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanSchedulesForNotice(_ items: [AcuityPlanSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAdaptiveShiftNoticesFromSchedule(_ items: [AcuityPlanSchedule]) -> [AdaptiveShiftNotice] {
        var out: [AdaptiveShiftNotice] = []
        for item in items {
            let derived = newAdaptiveShiftNotice(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveShiftNotice(_ item: AdaptiveShiftNotice) -> String {
        return normalizeAcuityPlanScheduleCode(item.code)
    }
}
