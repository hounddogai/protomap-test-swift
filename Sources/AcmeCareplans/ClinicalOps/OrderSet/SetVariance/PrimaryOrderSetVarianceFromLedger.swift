import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyHandoffLedgersForVariance(_ items: [LegacyHandoffLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryOrderSetVariancesFromLedger(_ items: [LegacyHandoffLedger]) -> [PrimaryOrderSetVariance] {
        var out: [PrimaryOrderSetVariance] = []
        for item in items {
            let derived = newPrimaryOrderSetVariance(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitPrimaryOrderSetVariance(_ item: PrimaryOrderSetVariance) -> String {
        return classifyManualHandoffAssignment(item.weightedValue())
    }
}
