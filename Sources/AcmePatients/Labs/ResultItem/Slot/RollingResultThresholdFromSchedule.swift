import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientResultSchedulesForThreshold(_ items: [LenientResultSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRollingResultThresholdsFromSchedule(_ items: [LenientResultSchedule]) -> [RollingResultThreshold] {
        var out: [RollingResultThreshold] = []
        for item in items {
            let derived = newRollingResultThreshold(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingResultThreshold(_ item: RollingResultThreshold) -> String {
        return lenientResultScheduleBucket(item.adjustedTotal())
    }
}
