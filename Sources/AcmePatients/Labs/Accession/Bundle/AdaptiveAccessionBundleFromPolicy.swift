import AcmePlatform
import Foundation

extension Labs {
    static func summarizeStrictPanelPoliciesForBundle(_ items: [StrictPanelPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveAdaptiveAccessionBundlesFromPolicy(_ items: [StrictPanelPolicy]) -> [AdaptiveAccessionBundle] {
        var out: [AdaptiveAccessionBundle] = []
        for item in items {
            let derived = newAdaptiveAccessionBundle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAdaptiveAccessionBundle(_ item: AdaptiveAccessionBundle) -> String {
        return normalizeSeasonalPanelPolicyCode(item.code)
    }
}
