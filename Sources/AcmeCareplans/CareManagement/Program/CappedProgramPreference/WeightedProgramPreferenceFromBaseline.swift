import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingProgramBaselinesForPreference(_ items: [RollingProgramBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWeightedProgramPreferencesFromBaseline(_ items: [RollingProgramBaseline]) -> [WeightedProgramPreference] {
        var out: [WeightedProgramPreference] = []
        for item in items {
            let derived = newWeightedProgramPreference(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateWeightedProgramPreference(_ item: WeightedProgramPreference) -> Double {
        return seasonalProgramBundleWeight(2, active: true)
    }
}
