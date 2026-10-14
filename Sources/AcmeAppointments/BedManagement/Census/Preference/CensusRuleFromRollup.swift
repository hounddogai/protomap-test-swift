import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningRollupsForRule(_ items: [CleaningRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCensusRulesFromRollup(_ items: [CleaningRollup]) -> [CensusRule] {
        var out: [CensusRule] = []
        for item in items {
            let derived = newCensusRule(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCensusRule(_ item: CensusRule) -> String {
        return cleaningForecastBucket(item.netVolume())
    }
}
