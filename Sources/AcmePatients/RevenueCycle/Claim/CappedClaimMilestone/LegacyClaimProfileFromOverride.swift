import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceOverridesForProfile(_ items: [RemittanceOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLegacyClaimProfilesFromOverride(_ items: [RemittanceOverride]) -> [LegacyClaimProfile] {
        var out: [LegacyClaimProfile] = []
        for item in items {
            let derived = newLegacyClaimProfile(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacyClaimProfile(_ item: LegacyClaimProfile) -> String {
        return classifyScheduledRemittanceMapping(item.measuredValue())
    }
}
