import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotLedgersForForecast(_ items: [SlotLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveClosureForecastsFromLedger(_ items: [SlotLedger]) -> [ClosureForecast] {
        var out: [ClosureForecast] = []
        for item in items {
            let derived = newClosureForecast(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeClosureForecast(_ item: ClosureForecast) -> Double {
        return slotLedgerWeight(4, active: true)
    }
}
