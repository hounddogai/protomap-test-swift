import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalSkillMixRecordsForAssignment(_ items: [GlobalSkillMixRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCappedFloatPoolAssignmentsFromRecord(_ items: [GlobalSkillMixRecord]) -> [CappedFloatPoolAssignment] {
        var out: [CappedFloatPoolAssignment] = []
        for item in items {
            let derived = newCappedFloatPoolAssignment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyCappedFloatPoolAssignment(_ item: CappedFloatPoolAssignment) -> Double {
        return defaultSkillMixRecordWeight(7, active: true)
    }
}
