import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedProxyExceptionsForDraft(_ items: [CappedProxyException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredProxyDraftsFromException(_ items: [CappedProxyException]) -> [TieredProxyDraft] {
        var out: [TieredProxyDraft] = []
        for item in items {
            let derived = newTieredProxyDraft(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyTieredProxyDraft(_ item: TieredProxyDraft) -> String {
        return classifyProxyTier(item.weightedValue())
    }
}
