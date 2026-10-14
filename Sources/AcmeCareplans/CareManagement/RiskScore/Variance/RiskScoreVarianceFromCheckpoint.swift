import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentCheckpointsForVariance(_ items: [AssessmentCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveRiskScoreVariancesFromCheckpoint(_ items: [AssessmentCheckpoint]) -> [RiskScoreVariance] {
        var out: [RiskScoreVariance] = []
        for item in items {
            let derived = newRiskScoreVariance(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRiskScoreVariance(_ item: RiskScoreVariance) -> String {
        return classifyAssessmentCheckpoint(item.adjustedVolume())
    }
}
