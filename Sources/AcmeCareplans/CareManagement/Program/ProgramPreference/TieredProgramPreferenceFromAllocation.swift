import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapAllocationsForPreference(_ items: [CareGapAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredProgramPreferencesFromAllocation(_ items: [CareGapAllocation]) -> [TieredProgramPreference] {
        var out: [TieredProgramPreference] = []
        for item in items {
            let derived = newTieredProgramPreference(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectTieredProgramPreference(_ item: TieredProgramPreference) -> String {
        return classifyCareGapTarget(item.effectiveExposure())
    }
}
