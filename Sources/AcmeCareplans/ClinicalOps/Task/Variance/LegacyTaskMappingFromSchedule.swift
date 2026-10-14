import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyTaskSchedulesForMapping(_ items: [LegacyTaskSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveLegacyTaskMappingsFromSchedule(_ items: [LegacyTaskSchedule]) -> [LegacyTaskMapping] {
        var out: [LegacyTaskMapping] = []
        for item in items {
            let derived = newLegacyTaskMapping(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceLegacyTaskMapping(_ item: LegacyTaskMapping) -> String {
        return classifyWeightedTaskAssignment(item.projectedExposure())
    }
}
