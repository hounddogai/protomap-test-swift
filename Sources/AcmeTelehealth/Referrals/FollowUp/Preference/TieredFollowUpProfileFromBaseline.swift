import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureBaselinesForProfile(_ items: [ClosureBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveTieredFollowUpProfilesFromBaseline(_ items: [ClosureBaseline]) -> [TieredFollowUpProfile] {
        var out: [TieredFollowUpProfile] = []
        for item in items {
            let derived = newTieredFollowUpProfile(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceTieredFollowUpProfile(_ item: TieredFollowUpProfile) -> String {
        return classifyClosureBaseline(item.measuredValue())
    }
}
