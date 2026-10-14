import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualDenialProfilesForPlan(_ items: [ManualDenialProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLegacyStatementPlansFromProfile(_ items: [ManualDenialProfile]) -> [LegacyStatementPlan] {
        var out: [LegacyStatementPlan] = []
        for item in items {
            let derived = newLegacyStatementPlan(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacyStatementPlan(_ item: LegacyStatementPlan) -> String {
        return fallbackDenialBaselineBucket(item.projectedTotal())
    }
}
