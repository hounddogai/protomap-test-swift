import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedCleaningSchedulesForBaseline(_ items: [BatchedCleaningSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientIsolationBaselinesFromSchedule(_ items: [BatchedCleaningSchedule]) -> [LenientIsolationBaseline] {
        var out: [LenientIsolationBaseline] = []
        for item in items {
            let derived = newLenientIsolationBaseline(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeLenientIsolationBaseline(_ item: LenientIsolationBaseline) -> String {
        return classifyLegacyCleaningForecast(item.netLoad())
    }
}
