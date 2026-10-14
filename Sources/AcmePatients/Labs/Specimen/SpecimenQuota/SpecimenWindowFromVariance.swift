import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedAccessionVariancesForWindow(_ items: [WeightedAccessionVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenWindowsFromVariance(_ items: [WeightedAccessionVariance]) -> [SpecimenWindow] {
        var out: [SpecimenWindow] = []
        for item in items {
            let derived = newSpecimenWindow(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleSpecimenWindow(_ item: SpecimenWindow) -> String {
        return normalizeScheduledAccessionMilestoneCode(item.code)
    }
}
