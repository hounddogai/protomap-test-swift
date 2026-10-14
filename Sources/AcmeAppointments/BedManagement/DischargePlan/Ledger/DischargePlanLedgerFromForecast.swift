import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanForecastsForLedger(_ items: [DischargePlanForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveDischargePlanLedgersFromForecast(_ items: [DischargePlanForecast]) -> [DischargePlanLedger] {
        var out: [DischargePlanLedger] = []
        for item in items {
            let derived = newDischargePlanLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDischargePlanLedger(_ item: DischargePlanLedger) -> String {
        return normalizeDischargePlanSlotCode(item.code)
    }
}
