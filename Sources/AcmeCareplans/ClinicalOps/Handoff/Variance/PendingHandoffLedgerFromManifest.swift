import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffManifestsForLedger(_ items: [HandoffManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func derivePendingHandoffLedgersFromManifest(_ items: [HandoffManifest]) -> [PendingHandoffLedger] {
        var out: [PendingHandoffLedger] = []
        for item in items {
            let derived = newPendingHandoffLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingHandoffLedger(_ item: PendingHandoffLedger) -> String {
        return classifyHandoffSlot(item.weightedValue())
    }
}
