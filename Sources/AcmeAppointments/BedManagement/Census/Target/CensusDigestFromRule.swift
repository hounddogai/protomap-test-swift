import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeSeasonalIsolationRulesForDigest(_ items: [SeasonalIsolationRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCensusDigestsFromRule(_ items: [SeasonalIsolationRule]) -> [CensusDigest] {
        var out: [CensusDigest] = []
        for item in items {
            let derived = newCensusDigest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateCensusDigest(_ item: CensusDigest) -> String {
        return isolationPlanBucket(item.projectedTotal())
    }
}
