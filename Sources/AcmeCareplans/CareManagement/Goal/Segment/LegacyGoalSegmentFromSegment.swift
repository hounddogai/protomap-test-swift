import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentSegmentsForSegment(_ items: [AssessmentSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveLegacyGoalSegmentsFromSegment(_ items: [AssessmentSegment]) -> [LegacyGoalSegment] {
        var out: [LegacyGoalSegment] = []
        for item in items {
            let derived = newLegacyGoalSegment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyLegacyGoalSegment(_ item: LegacyGoalSegment) -> String {
        return classifyLegacyAssessmentEstimate(item.adjustedVolume())
    }
}
