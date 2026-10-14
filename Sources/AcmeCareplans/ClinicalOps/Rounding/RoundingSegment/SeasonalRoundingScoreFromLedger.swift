import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalTaskLedgersForScore(_ items: [GlobalTaskLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSeasonalRoundingScoresFromLedger(_ items: [GlobalTaskLedger]) -> [SeasonalRoundingScore] {
        var out: [SeasonalRoundingScore] = []
        for item in items {
            let derived = newSeasonalRoundingScore(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankSeasonalRoundingScore(_ item: SeasonalRoundingScore) -> Double {
        return globalTaskLedgerWeight(1, active: true)
    }
}
