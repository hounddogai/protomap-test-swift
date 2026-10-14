import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationPlansForManifest(_ items: [AuthorizationPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveDenialManifestsFromPlan(_ items: [AuthorizationPlan]) -> [DenialManifest] {
        var out: [DenialManifest] = []
        for item in items {
            let derived = newDenialManifest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveDenialManifest(_ item: DenialManifest) -> String {
        return normalizeAuthorizationTemplateCode(item.code)
    }
}
