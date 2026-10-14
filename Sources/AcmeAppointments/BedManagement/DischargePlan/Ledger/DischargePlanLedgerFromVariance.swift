import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryCensusVariancesForLedger(_ items: [PrimaryCensusVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDischargePlanLedgersFromVariance(_ items: [PrimaryCensusVariance]) -> [DischargePlanLedger] {
        var out: [DischargePlanLedger] = []
        for item in items {
            let derived = newDischargePlanLedger(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeDischargePlanLedger(_ item: DischargePlanLedger) -> String {
        return classifyGlobalCensusSlot(item.effectiveValue())
    }
}
