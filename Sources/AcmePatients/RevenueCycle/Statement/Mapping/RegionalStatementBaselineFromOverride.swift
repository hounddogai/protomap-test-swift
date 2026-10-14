import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialOverridesForBaseline(_ items: [DenialOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRegionalStatementBaselinesFromOverride(_ items: [DenialOverride]) -> [RegionalStatementBaseline] {
        var out: [RegionalStatementBaseline] = []
        for item in items {
            let derived = newRegionalStatementBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRegionalStatementBaseline(_ item: RegionalStatementBaseline) -> String {
        return normalizeDenialOverrideCode(item.code)
    }
}
