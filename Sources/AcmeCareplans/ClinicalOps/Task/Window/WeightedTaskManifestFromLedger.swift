import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalTaskLedgersForManifest(_ items: [GlobalTaskLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveWeightedTaskManifestsFromLedger(_ items: [GlobalTaskLedger]) -> [WeightedTaskManifest] {
        var out: [WeightedTaskManifest] = []
        for item in items {
            let derived = newWeightedTaskManifest(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedTaskManifest(_ item: WeightedTaskManifest) -> String {
        return normalizeGlobalTaskLedgerCode(item.code)
    }
}
