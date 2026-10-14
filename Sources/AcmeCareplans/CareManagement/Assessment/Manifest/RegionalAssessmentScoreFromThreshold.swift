import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachThresholdsForScore(_ items: [OutreachThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRegionalAssessmentScoresFromThreshold(_ items: [OutreachThreshold]) -> [RegionalAssessmentScore] {
        var out: [RegionalAssessmentScore] = []
        for item in items {
            let derived = newRegionalAssessmentScore(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRegionalAssessmentScore(_ item: RegionalAssessmentScore) -> String {
        return classifyOutreachBudget(item.weightedVolume())
    }
}
