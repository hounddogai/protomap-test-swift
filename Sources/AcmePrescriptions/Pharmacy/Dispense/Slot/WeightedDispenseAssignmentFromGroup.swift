import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyInventoryGroupsForAssignment(_ items: [LegacyInventoryGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveWeightedDispenseAssignmentsFromGroup(_ items: [LegacyInventoryGroup]) -> [WeightedDispenseAssignment] {
        var out: [WeightedDispenseAssignment] = []
        for item in items {
            let derived = newWeightedDispenseAssignment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeWeightedDispenseAssignment(_ item: WeightedDispenseAssignment) -> String {
        return normalizeLegacyInventoryGroupCode(item.code)
    }
}
