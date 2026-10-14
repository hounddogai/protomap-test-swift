import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialLedgersForScore(_ items: [DenialLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func derivePrimaryDenialScoresFromLedger(_ items: [DenialLedger]) -> [PrimaryDenialScore] {
        var out: [PrimaryDenialScore] = []
        for item in items {
            let derived = newPrimaryDenialScore(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPrimaryDenialScore(_ item: PrimaryDenialScore) -> String {
        return normalizeDenialAdjustmentCode(item.code)
    }
}
