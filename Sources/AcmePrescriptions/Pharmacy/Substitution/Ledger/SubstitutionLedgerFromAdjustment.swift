import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultDispenseAdjustmentsForLedger(_ items: [DefaultDispenseAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveSubstitutionLedgersFromAdjustment(_ items: [DefaultDispenseAdjustment]) -> [SubstitutionLedger] {
        var out: [SubstitutionLedger] = []
        for item in items {
            let derived = newSubstitutionLedger(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceSubstitutionLedger(_ item: SubstitutionLedger) -> String {
        return manualDispenseScheduleBucket(item.weightedVolume())
    }
}
