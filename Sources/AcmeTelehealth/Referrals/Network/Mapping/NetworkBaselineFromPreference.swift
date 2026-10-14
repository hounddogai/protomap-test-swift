import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpPreferencesForBaseline(_ items: [FollowUpPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveNetworkBaselinesFromPreference(_ items: [FollowUpPreference]) -> [NetworkBaseline] {
        var out: [NetworkBaseline] = []
        for item in items {
            let derived = newNetworkBaseline(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeNetworkBaseline(_ item: NetworkBaseline) -> String {
        return normalizeTieredFollowUpProfileCode(item.code)
    }
}
