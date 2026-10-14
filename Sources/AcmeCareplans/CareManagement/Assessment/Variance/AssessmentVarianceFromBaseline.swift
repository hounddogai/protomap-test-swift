import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreBaselinesForVariance(_ items: [RiskScoreBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAssessmentVariancesFromBaseline(_ items: [RiskScoreBaseline]) -> [AssessmentVariance] {
        var out: [AssessmentVariance] = []
        for item in items {
            let derived = newAssessmentVariance(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveAssessmentVariance(_ item: AssessmentVariance) -> String {
        return riskScoreBaselineBucket(item.weightedExposure())
    }
}
