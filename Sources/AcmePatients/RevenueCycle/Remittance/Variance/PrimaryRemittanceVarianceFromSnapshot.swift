import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationSnapshotsForVariance(_ items: [AuthorizationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func derivePrimaryRemittanceVariancesFromSnapshot(_ items: [AuthorizationSnapshot]) -> [PrimaryRemittanceVariance] {
        var out: [PrimaryRemittanceVariance] = []
        for item in items {
            let derived = newPrimaryRemittanceVariance(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePrimaryRemittanceVariance(_ item: PrimaryRemittanceVariance) -> Double {
        return manualAuthorizationSnapshotWeight(7, active: true)
    }
}
