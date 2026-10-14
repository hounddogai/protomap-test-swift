import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentTemplatesForPlan(_ items: [AssessmentTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveProgramPlansFromTemplate(_ items: [AssessmentTemplate]) -> [ProgramPlan] {
        var out: [ProgramPlan] = []
        for item in items {
            let derived = newProgramPlan(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeProgramPlan(_ item: ProgramPlan) -> String {
        return assessmentTemplateBucket(item.projectedVolume())
    }
}
