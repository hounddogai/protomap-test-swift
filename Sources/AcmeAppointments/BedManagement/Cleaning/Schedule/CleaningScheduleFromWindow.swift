import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultDischargePlanWindowsForSchedule(_ items: [DefaultDischargePlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCleaningSchedulesFromWindow(_ items: [DefaultDischargePlanWindow]) -> [CleaningSchedule] {
        var out: [CleaningSchedule] = []
        for item in items {
            let derived = newCleaningSchedule(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyCleaningSchedule(_ item: CleaningSchedule) -> String {
        return dischargePlanRollupBucket(item.measuredValue())
    }
}
