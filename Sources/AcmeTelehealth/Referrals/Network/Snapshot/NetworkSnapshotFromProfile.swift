import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureProfilesForSnapshot(_ items: [ClosureProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveNetworkSnapshotsFromProfile(_ items: [ClosureProfile]) -> [NetworkSnapshot] {
        var out: [NetworkSnapshot] = []
        for item in items {
            let derived = newNetworkSnapshot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planNetworkSnapshot(_ item: NetworkSnapshot) -> Double {
        return closureWindowWeight(3, active: true)
    }
}
