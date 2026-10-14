import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingResultBaselinesForLedger(_ items: [PendingResultBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalSpecimenLedgersFromBaseline(_ items: [PendingResultBaseline]) -> [SeasonalSpecimenLedger] {
        var out: [SeasonalSpecimenLedger] = []
        for item in items {
            let derived = newSeasonalSpecimenLedger(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeSeasonalSpecimenLedger(_ item: SeasonalSpecimenLedger) -> Double {
        return primaryResultWindowWeight(8, active: true)
    }
}
