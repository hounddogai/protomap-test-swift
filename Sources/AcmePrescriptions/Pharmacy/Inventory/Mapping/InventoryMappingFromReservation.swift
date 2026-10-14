import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryRecallReservationsForMapping(_ items: [PrimaryRecallReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInventoryMappingsFromReservation(_ items: [PrimaryRecallReservation]) -> [InventoryMapping] {
        var out: [InventoryMapping] = []
        for item in items {
            let derived = newInventoryMapping(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateInventoryMapping(_ item: InventoryMapping) -> String {
        return normalizeStrictRecallReviewCode(item.code)
    }
}
