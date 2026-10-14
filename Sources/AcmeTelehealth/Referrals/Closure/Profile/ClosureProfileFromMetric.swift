import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureMetricsForProfile(_ items: [ClosureMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveClosureProfilesFromMetric(_ items: [ClosureMetric]) -> [ClosureProfile] {
        var out: [ClosureProfile] = []
        for item in items {
            let derived = newClosureProfile(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectClosureProfile(_ item: ClosureProfile) -> Double {
        return closureMilestoneWeight(2, active: true)
    }
}
