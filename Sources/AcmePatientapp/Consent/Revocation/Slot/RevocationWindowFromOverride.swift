import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageOverridesForWindow(_ items: [LanguageOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRevocationWindowsFromOverride(_ items: [LanguageOverride]) -> [RevocationWindow] {
        var out: [RevocationWindow] = []
        for item in items {
            let derived = newRevocationWindow(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRevocationWindow(_ item: RevocationWindow) -> String {
        return classifyLegacyLanguageTemplate(item.adjustedLoad())
    }
}
