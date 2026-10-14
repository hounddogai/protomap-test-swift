import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationSnapshotsForManifest(_ items: [AuthorizationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAuthorizationManifestsFromSnapshot(_ items: [AuthorizationSnapshot]) -> [AuthorizationManifest] {
        var out: [AuthorizationManifest] = []
        for item in items {
            let derived = newAuthorizationManifest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAuthorizationManifest(_ item: AuthorizationManifest) -> Double {
        return manualAuthorizationSnapshotWeight(1, active: true)
    }
}
