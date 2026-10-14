import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultAssessmentEstimatesForTemplate(_ items: [DefaultAssessmentEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCappedOutreachTemplatesFromEstimate(_ items: [DefaultAssessmentEstimate]) -> [CappedOutreachTemplate] {
        var out: [CappedOutreachTemplate] = []
        for item in items {
            let derived = newCappedOutreachTemplate(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCappedOutreachTemplate(_ item: CappedOutreachTemplate) -> Double {
        return rollingAssessmentReservationWeight(5, active: true)
    }
}
