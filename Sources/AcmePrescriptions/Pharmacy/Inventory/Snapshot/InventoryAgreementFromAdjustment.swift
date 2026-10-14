import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultDispenseAdjustmentsForAgreement(_ items: [DefaultDispenseAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveInventoryAgreementsFromAdjustment(_ items: [DefaultDispenseAdjustment]) -> [InventoryAgreement] {
        var out: [InventoryAgreement] = []
        for item in items {
            let derived = newInventoryAgreement(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveInventoryAgreement(_ item: InventoryAgreement) -> Double {
        return manualDispenseScheduleWeight(8, active: true)
    }
}
