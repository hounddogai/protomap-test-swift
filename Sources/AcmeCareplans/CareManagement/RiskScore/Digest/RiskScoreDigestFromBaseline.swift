import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedAssessmentBaselinesForDigest(_ items: [CappedAssessmentBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRiskScoreDigestsFromBaseline(_ items: [CappedAssessmentBaseline]) -> [RiskScoreDigest] {
        var out: [RiskScoreDigest] = []
        for item in items {
            let derived = newRiskScoreDigest(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyRiskScoreDigest(_ item: RiskScoreDigest) -> Double {
        return cappedAssessmentBaselineWeight(9, active: true)
    }
}
