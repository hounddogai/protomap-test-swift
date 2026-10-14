import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultNetworkWindowsForLedger(_ items: [DefaultNetworkWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLegacyClosureLedgersFromWindow(_ items: [DefaultNetworkWindow]) -> [LegacyClosureLedger] {
        var out: [LegacyClosureLedger] = []
        for item in items {
            let derived = newLegacyClosureLedger(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectLegacyClosureLedger(_ item: LegacyClosureLedger) -> String {
        return classifyRegionalNetworkRule(item.weightedExposure())
    }
}
