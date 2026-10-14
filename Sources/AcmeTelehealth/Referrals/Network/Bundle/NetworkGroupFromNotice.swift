import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualNetworkNoticesForGroup(_ items: [ManualNetworkNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveNetworkGroupsFromNotice(_ items: [ManualNetworkNotice]) -> [NetworkGroup] {
        var out: [NetworkGroup] = []
        for item in items {
            let derived = newNetworkGroup(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveNetworkGroup(_ item: NetworkGroup) -> String {
        return classifyManualNetworkNotice(item.adjustedTotal())
    }
}
