import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeScheduledNetworkPreferencesForRollup(_ items: [ScheduledNetworkPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingSlotRollupsFromPreference(_ items: [ScheduledNetworkPreference]) -> [RollingSlotRollup] {
        var out: [RollingSlotRollup] = []
        for item in items {
            let derived = newRollingSlotRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRollingSlotRollup(_ item: RollingSlotRollup) -> String {
        return networkAgreementBucket(item.projectedValue())
    }
}
