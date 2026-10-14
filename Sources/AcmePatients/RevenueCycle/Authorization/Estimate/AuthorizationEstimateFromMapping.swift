import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationMappingsForEstimate(_ items: [AuthorizationMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAuthorizationEstimatesFromMapping(_ items: [AuthorizationMapping]) -> [AuthorizationEstimate] {
        var out: [AuthorizationEstimate] = []
        for item in items {
            let derived = newAuthorizationEstimate(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeAuthorizationEstimate(_ item: AuthorizationEstimate) -> String {
        return normalizeTieredAuthorizationBundleCode(item.code)
    }
}
