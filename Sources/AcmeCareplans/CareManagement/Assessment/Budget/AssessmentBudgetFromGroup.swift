import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramGroupsForBudget(_ items: [ProgramGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveAssessmentBudgetsFromGroup(_ items: [ProgramGroup]) -> [AssessmentBudget] {
        var out: [AssessmentBudget] = []
        for item in items {
            let derived = newAssessmentBudget(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateAssessmentBudget(_ item: AssessmentBudget) -> String {
        return classifyProgramGroup(item.measuredValue())
    }
}
