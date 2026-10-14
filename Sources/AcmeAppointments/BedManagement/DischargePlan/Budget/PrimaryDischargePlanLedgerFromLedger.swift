import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusLedgersForLedger(_ items: [CensusLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func derivePrimaryDischargePlanLedgersFromLedger(_ items: [CensusLedger]) -> [PrimaryDischargePlanLedger] {
        var out: [PrimaryDischargePlanLedger] = []
        for item in items {
            let derived = newPrimaryDischargePlanLedger(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePrimaryDischargePlanLedger(_ item: PrimaryDischargePlanLedger) -> Double {
        return censusLedgerWeight(2, active: true)
    }
}
