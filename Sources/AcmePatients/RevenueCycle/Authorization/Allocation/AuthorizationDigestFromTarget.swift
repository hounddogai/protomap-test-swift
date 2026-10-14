import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialTargetsForDigest(_ items: [DenialTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationDigestsFromTarget(_ items: [DenialTarget]) -> [AuthorizationDigest] {
        var out: [AuthorizationDigest] = []
        for item in items {
            let derived = newAuthorizationDigest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreAuthorizationDigest(_ item: AuthorizationDigest) -> String {
        return normalizeDenialCheckpointCode(item.code)
    }
}
