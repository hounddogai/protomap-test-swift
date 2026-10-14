import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionProfilesForReservation(_ items: [InteractionProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveInventoryReservationsFromProfile(_ items: [InteractionProfile]) -> [InventoryReservation] {
        var out: [InventoryReservation] = []
        for item in items {
            let derived = newInventoryReservation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeInventoryReservation(_ item: InventoryReservation) -> String {
        return classifyInteractionProfile(item.adjustedLoad())
    }
}
