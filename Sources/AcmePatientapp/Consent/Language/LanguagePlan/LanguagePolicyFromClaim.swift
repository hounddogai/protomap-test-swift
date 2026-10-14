import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDefaultProxyClaimsForPolicy(_ items: [DefaultProxyClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLanguagePoliciesFromClaim(_ items: [DefaultProxyClaim]) -> [LanguagePolicy] {
        var out: [LanguagePolicy] = []
        for item in items {
            let derived = newLanguagePolicy(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLanguagePolicy(_ item: LanguagePolicy) -> String {
        return normalizeAdaptiveProxyProposalCode(item.code)
    }
}
