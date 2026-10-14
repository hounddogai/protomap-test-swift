import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualNetworkPreferencesForBaseline(_ items: [ManualNetworkPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveLegacyEligibilityBaselinesFromPreference(_ items: [ManualNetworkPreference]) -> [LegacyEligibilityBaseline] {
        var out: [LegacyEligibilityBaseline] = []
        for item in items {
            let derived = newLegacyEligibilityBaseline(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceLegacyEligibilityBaseline(_ item: LegacyEligibilityBaseline) -> Double {
        return lenientNetworkSnapshotWeight(9, active: true)
    }
}
