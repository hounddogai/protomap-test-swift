import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalRemittanceAssignmentsForEntry(_ items: [GlobalRemittanceAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveLegacyAuthorizationEntriesFromAssignment(_ items: [GlobalRemittanceAssignment]) -> [LegacyAuthorizationEntry] {
        var out: [LegacyAuthorizationEntry] = []
        for item in items {
            let derived = newLegacyAuthorizationEntry(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceLegacyAuthorizationEntry(_ item: LegacyAuthorizationEntry) -> String {
        return classifyFallbackRemittanceBundle(item.effectiveTotal())
    }
}
