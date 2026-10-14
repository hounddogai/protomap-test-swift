import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInventorySnapshotsForLedger(_ items: [PrimaryInventorySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTieredInteractionLedgersFromSnapshot(_ items: [PrimaryInventorySnapshot]) -> [TieredInteractionLedger] {
        var out: [TieredInteractionLedger] = []
        for item in items {
            let derived = newTieredInteractionLedger(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveTieredInteractionLedger(_ item: TieredInteractionLedger) -> String {
        return classifyBatchedInventoryPolicy(item.measuredValue())
    }
}
