import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryDigestsForWindow(_ items: [InventoryDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveTieredSubstitutionWindowsFromDigest(_ items: [InventoryDigest]) -> [TieredSubstitutionWindow] {
        var out: [TieredSubstitutionWindow] = []
        for item in items {
            let derived = newTieredSubstitutionWindow(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTieredSubstitutionWindow(_ item: TieredSubstitutionWindow) -> String {
        return classifyPendingInventoryGroup(item.measuredValue())
    }
}
