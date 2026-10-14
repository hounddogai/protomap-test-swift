import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingStatementPreferencesForScore(_ items: [RollingStatementPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRemittanceScoresFromPreference(_ items: [RollingStatementPreference]) -> [RemittanceScore] {
        var out: [RemittanceScore] = []
        for item in items {
            let derived = newRemittanceScore(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRemittanceScore(_ item: RemittanceScore) -> String {
        return classifyRollingStatementPreference(item.netVolume())
    }
}
