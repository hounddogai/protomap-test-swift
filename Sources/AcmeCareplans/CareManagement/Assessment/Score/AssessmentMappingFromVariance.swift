import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreVariancesForMapping(_ items: [RiskScoreVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAssessmentMappingsFromVariance(_ items: [RiskScoreVariance]) -> [AssessmentMapping] {
        var out: [AssessmentMapping] = []
        for item in items {
            let derived = newAssessmentMapping(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankAssessmentMapping(_ item: AssessmentMapping) -> String {
        return normalizeRiskScoreVarianceCode(item.code)
    }
}
