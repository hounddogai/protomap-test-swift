import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierPlansForPreference(_ items: [CourierPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRegionalPanelPreferencesFromPlan(_ items: [CourierPlan]) -> [RegionalPanelPreference] {
        var out: [RegionalPanelPreference] = []
        for item in items {
            let derived = newRegionalPanelPreference(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectRegionalPanelPreference(_ item: RegionalPanelPreference) -> String {
        return classifyCourierPlan(item.weightedValue())
    }
}
