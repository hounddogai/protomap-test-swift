import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationSnapshotsForMapping(_ items: [AuthorizationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveDefaultChargeMappingsFromSnapshot(_ items: [AuthorizationSnapshot]) -> [DefaultChargeMapping] {
        var out: [DefaultChargeMapping] = []
        for item in items {
            let derived = newDefaultChargeMapping(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreDefaultChargeMapping(_ item: DefaultChargeMapping) -> Double {
        return manualAuthorizationSnapshotWeight(4, active: true)
    }
}
