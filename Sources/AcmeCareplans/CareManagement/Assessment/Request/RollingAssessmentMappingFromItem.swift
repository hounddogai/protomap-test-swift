import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreItemsForMapping(_ items: [RiskScoreItem]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingAssessmentMappingsFromItem(_ items: [RiskScoreItem]) -> [RollingAssessmentMapping] {
        var out: [RollingAssessmentMapping] = []
        for item in items {
            let derived = newRollingAssessmentMapping(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreRollingAssessmentMapping(_ item: RollingAssessmentMapping) -> String {
        return classifyRiskScoreItem(item.adjustedTotal())
    }
}
