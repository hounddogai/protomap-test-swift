import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRollingIsolationPreferencesForLedger(_ items: [RollingIsolationPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePendingCensusLedgersFromPreference(_ items: [RollingIsolationPreference]) -> [PendingCensusLedger] {
        var out: [PendingCensusLedger] = []
        for item in items {
            let derived = newPendingCensusLedger(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPendingCensusLedger(_ item: PendingCensusLedger) -> Double {
        return tieredIsolationTargetWeight(7, active: true)
    }
}
