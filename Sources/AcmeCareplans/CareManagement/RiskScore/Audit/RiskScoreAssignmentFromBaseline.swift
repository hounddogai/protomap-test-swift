import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingProgramBaselinesForAssignment(_ items: [RollingProgramBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRiskScoreAssignmentsFromBaseline(_ items: [RollingProgramBaseline]) -> [RiskScoreAssignment] {
        var out: [RiskScoreAssignment] = []
        for item in items {
            let derived = newRiskScoreAssignment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRiskScoreAssignment(_ item: RiskScoreAssignment) -> String {
        return normalizeRollingProgramBaselineCode(item.code)
    }
}
