import AcmePlatform
import Foundation

extension Labs {
    static func summarizeStrictSpecimenVariancesForProfile(_ items: [StrictSpecimenVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackResultProfilesFromVariance(_ items: [StrictSpecimenVariance]) -> [FallbackResultProfile] {
        var out: [FallbackResultProfile] = []
        for item in items {
            let derived = newFallbackResultProfile(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFallbackResultProfile(_ item: FallbackResultProfile) -> Double {
        return strictSpecimenVarianceWeight(5, active: true)
    }
}
