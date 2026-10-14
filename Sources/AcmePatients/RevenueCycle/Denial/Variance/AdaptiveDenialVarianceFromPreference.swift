import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementPreferencesForVariance(_ items: [StatementPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAdaptiveDenialVariancesFromPreference(_ items: [StatementPreference]) -> [AdaptiveDenialVariance] {
        var out: [AdaptiveDenialVariance] = []
        for item in items {
            let derived = newAdaptiveDenialVariance(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAdaptiveDenialVariance(_ item: AdaptiveDenialVariance) -> String {
        return normalizeStatementBundleCode(item.code)
    }
}
