import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkOverridesForNotice(_ items: [NetworkOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveNetworkNoticesFromOverride(_ items: [NetworkOverride]) -> [NetworkNotice] {
        var out: [NetworkNotice] = []
        for item in items {
            let derived = newNetworkNotice(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchNetworkNotice(_ item: NetworkNotice) -> Double {
        return lenientNetworkWindowWeight(5, active: true)
    }
}
