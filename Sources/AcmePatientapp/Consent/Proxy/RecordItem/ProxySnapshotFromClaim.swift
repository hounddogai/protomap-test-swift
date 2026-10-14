import AcmePlatform
import Foundation

extension Consent {
    static func summarizePendingRevocationClaimsForSnapshot(_ items: [PendingRevocationClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveProxySnapshotsFromClaim(_ items: [PendingRevocationClaim]) -> [ProxySnapshot] {
        var out: [ProxySnapshot] = []
        for item in items {
            let derived = newProxySnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeProxySnapshot(_ item: ProxySnapshot) -> String {
        return cappedRevocationTemplateBucket(item.netLoad())
    }
}
