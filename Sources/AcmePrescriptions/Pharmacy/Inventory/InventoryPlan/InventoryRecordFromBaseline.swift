import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedSubstitutionBaselinesForRecord(_ items: [CappedSubstitutionBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveInventoryRecordsFromBaseline(_ items: [CappedSubstitutionBaseline]) -> [InventoryRecord] {
        var out: [InventoryRecord] = []
        for item in items {
            let derived = newInventoryRecord(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planInventoryRecord(_ item: InventoryRecord) -> String {
        return substitutionBudgetBucket(item.effectiveVolume())
    }
}
