import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingSubstitutionRulesForTemplate(_ items: [RollingSubstitutionRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveSeasonalRecallTemplatesFromRule(_ items: [RollingSubstitutionRule]) -> [SeasonalRecallTemplate] {
        var out: [SeasonalRecallTemplate] = []
        for item in items {
            let derived = newSeasonalRecallTemplate(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateSeasonalRecallTemplate(_ item: SeasonalRecallTemplate) -> String {
        return classifySubstitutionLedger(item.measuredValue())
    }
}
