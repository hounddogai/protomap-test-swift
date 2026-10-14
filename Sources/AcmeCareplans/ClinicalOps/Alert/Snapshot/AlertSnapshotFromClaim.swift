import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTieredAlertClaimsForSnapshot(_ items: [TieredAlertClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAlertSnapshotsFromClaim(_ items: [TieredAlertClaim]) -> [AlertSnapshot] {
        var out: [AlertSnapshot] = []
        for item in items {
            let derived = newAlertSnapshot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyAlertSnapshot(_ item: AlertSnapshot) -> String {
        return tieredAlertClaimBucket(item.weightedVolume())
    }
}
