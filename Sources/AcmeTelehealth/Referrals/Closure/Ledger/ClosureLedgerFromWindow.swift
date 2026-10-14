import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalClosureWindowsForLedger(_ items: [SeasonalClosureWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClosureLedgersFromWindow(_ items: [SeasonalClosureWindow]) -> [ClosureLedger] {
        var out: [ClosureLedger] = []
        for item in items {
            let derived = newClosureLedger(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleClosureLedger(_ item: ClosureLedger) -> String {
        return classifySeasonalClosureWindow(item.measuredValue())
    }
}
