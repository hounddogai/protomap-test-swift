import AcmePlatform
import Foundation

extension Consent {
    static func summarizeTieredRevocationRollupsForGroup(_ items: [TieredRevocationRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveDisclosureGroupsFromRollup(_ items: [TieredRevocationRollup]) -> [DisclosureGroup] {
        var out: [DisclosureGroup] = []
        for item in items {
            let derived = newDisclosureGroup(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyDisclosureGroup(_ item: DisclosureGroup) -> Double {
        return scheduledRevocationExceptionWeight(8, active: true)
    }
}
