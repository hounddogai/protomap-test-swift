import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyReservationsForRule(_ items: [ProxyReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLanguageRulesFromReservation(_ items: [ProxyReservation]) -> [LanguageRule] {
        var out: [LanguageRule] = []
        for item in items {
            let derived = newLanguageRule(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLanguageRule(_ item: LanguageRule) -> String {
        return normalizeStrictProxyBaselineCode(item.code)
    }
}
