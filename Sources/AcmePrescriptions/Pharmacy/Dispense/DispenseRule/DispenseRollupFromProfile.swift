import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingDispenseProfilesForRollup(_ items: [RollingDispenseProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDispenseRollupsFromProfile(_ items: [RollingDispenseProfile]) -> [DispenseRollup] {
        var out: [DispenseRollup] = []
        for item in items {
            let derived = newDispenseRollup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateDispenseRollup(_ item: DispenseRollup) -> String {
        return normalizeFallbackDispenseRequestCode(item.code)
    }
}
