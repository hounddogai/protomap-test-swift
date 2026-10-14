import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapAllocationsForException(_ items: [CareGapAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAssessmentExceptionsFromAllocation(_ items: [CareGapAllocation]) -> [AssessmentException] {
        var out: [AssessmentException] = []
        for item in items {
            let derived = newAssessmentException(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAssessmentException(_ item: AssessmentException) -> Double {
        return careGapAuditWeight(2, active: true)
    }
}
