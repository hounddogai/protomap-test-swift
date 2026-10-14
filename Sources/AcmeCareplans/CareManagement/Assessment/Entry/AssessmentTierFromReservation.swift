import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachReservationsForTier(_ items: [OutreachReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAssessmentTiersFromReservation(_ items: [OutreachReservation]) -> [AssessmentTier] {
        var out: [AssessmentTier] = []
        for item in items {
            let derived = newAssessmentTier(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeAssessmentTier(_ item: AssessmentTier) -> String {
        return classifyOutreachCycle(item.measuredValue())
    }
}
