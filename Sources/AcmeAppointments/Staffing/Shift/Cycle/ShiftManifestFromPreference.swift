import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanPreferencesForManifest(_ items: [AcuityPlanPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveShiftManifestsFromPreference(_ items: [AcuityPlanPreference]) -> [ShiftManifest] {
        var out: [ShiftManifest] = []
        for item in items {
            let derived = newShiftManifest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreShiftManifest(_ item: ShiftManifest) -> String {
        return acuityPlanPreferenceBucket(item.projectedValue())
    }
}
