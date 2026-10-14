import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationTiersForSnapshot(_ items: [AuthorizationTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRemittanceSnapshotsFromTier(_ items: [AuthorizationTier]) -> [RemittanceSnapshot] {
        var out: [RemittanceSnapshot] = []
        for item in items {
            let derived = newRemittanceSnapshot(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectRemittanceSnapshot(_ item: RemittanceSnapshot) -> String {
        return authorizationClaimBucket(item.netLoad())
    }
}
