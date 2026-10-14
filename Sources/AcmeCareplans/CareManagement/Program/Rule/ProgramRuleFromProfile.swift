import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentProfilesForRule(_ items: [AssessmentProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveProgramRulesFromProfile(_ items: [AssessmentProfile]) -> [ProgramRule] {
        var out: [ProgramRule] = []
        for item in items {
            let derived = newProgramRule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeProgramRule(_ item: ProgramRule) -> String {
        return normalizeAssessmentAdjustmentCode(item.code)
    }
}
