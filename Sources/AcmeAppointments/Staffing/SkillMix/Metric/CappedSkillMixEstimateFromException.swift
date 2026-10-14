import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftExceptionsForEstimate(_ items: [ShiftException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCappedSkillMixEstimatesFromException(_ items: [ShiftException]) -> [CappedSkillMixEstimate] {
        var out: [CappedSkillMixEstimate] = []
        for item in items {
            let derived = newCappedSkillMixEstimate(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCappedSkillMixEstimate(_ item: CappedSkillMixEstimate) -> String {
        return classifyShiftTarget(item.adjustedTotal())
    }
}
