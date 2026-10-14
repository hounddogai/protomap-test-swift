import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultProgramOverridesForSegment(_ items: [DefaultProgramOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedGoalSegmentsFromOverride(_ items: [DefaultProgramOverride]) -> [CappedGoalSegment] {
        var out: [CappedGoalSegment] = []
        for item in items {
            let derived = newCappedGoalSegment(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedGoalSegment(_ item: CappedGoalSegment) -> Double {
        return defaultProgramOverrideWeight(8, active: true)
    }
}
