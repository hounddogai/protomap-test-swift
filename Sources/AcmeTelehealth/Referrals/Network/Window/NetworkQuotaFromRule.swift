import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureRulesForQuota(_ items: [ClosureRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveNetworkQuotasFromRule(_ items: [ClosureRule]) -> [NetworkQuota] {
        var out: [NetworkQuota] = []
        for item in items {
            let derived = newNetworkQuota(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileNetworkQuota(_ item: NetworkQuota) -> String {
        return normalizeClosureBaselineCode(item.code)
    }
}
