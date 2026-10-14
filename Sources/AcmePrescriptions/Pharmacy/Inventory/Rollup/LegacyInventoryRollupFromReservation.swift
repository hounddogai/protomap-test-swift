import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryReservationsForRollup(_ items: [InventoryReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLegacyInventoryRollupsFromReservation(_ items: [InventoryReservation]) -> [LegacyInventoryRollup] {
        var out: [LegacyInventoryRollup] = []
        for item in items {
            let derived = newLegacyInventoryRollup(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLegacyInventoryRollup(_ item: LegacyInventoryRollup) -> String {
        return normalizeInventoryReservationCode(item.code)
    }
}
