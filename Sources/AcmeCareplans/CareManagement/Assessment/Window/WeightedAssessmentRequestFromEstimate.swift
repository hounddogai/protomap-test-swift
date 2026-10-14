import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRegionalAssessmentEstimatesForRequest(_ items: [RegionalAssessmentEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveWeightedAssessmentRequestsFromEstimate(_ items: [RegionalAssessmentEstimate]) -> [WeightedAssessmentRequest] {
        var out: [WeightedAssessmentRequest] = []
        for item in items {
            let derived = newWeightedAssessmentRequest(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreWeightedAssessmentRequest(_ item: WeightedAssessmentRequest) -> String {
        return adaptiveAssessmentThresholdBucket(item.effectiveVolume())
    }
}
