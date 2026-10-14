import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramAdjustmentsForAgreement(_ items: [ProgramAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAssessmentAgreementsFromAdjustment(_ items: [ProgramAdjustment]) -> [AssessmentAgreement] {
        var out: [AssessmentAgreement] = []
        for item in items {
            let derived = newAssessmentAgreement(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveAssessmentAgreement(_ item: AssessmentAgreement) -> String {
        return normalizeProgramAdjustmentCode(item.code)
    }
}
