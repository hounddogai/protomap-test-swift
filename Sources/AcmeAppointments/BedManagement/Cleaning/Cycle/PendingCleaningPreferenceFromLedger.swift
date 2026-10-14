import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualCensusLedgersForPreference(_ items: [ManualCensusLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePendingCleaningPreferencesFromLedger(_ items: [ManualCensusLedger]) -> [PendingCleaningPreference] {
        var out: [PendingCleaningPreference] = []
        for item in items {
            let derived = newPendingCleaningPreference(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePendingCleaningPreference(_ item: PendingCleaningPreference) -> Double {
        return rollingCensusLedgerWeight(5, active: true)
    }
}
