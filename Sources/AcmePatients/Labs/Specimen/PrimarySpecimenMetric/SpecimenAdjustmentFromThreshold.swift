import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacyPanelThresholdsForAdjustment(_ items: [LegacyPanelThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenAdjustmentsFromThreshold(_ items: [LegacyPanelThreshold]) -> [SpecimenAdjustment] {
        var out: [SpecimenAdjustment] = []
        for item in items {
            let derived = newSpecimenAdjustment(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeSpecimenAdjustment(_ item: SpecimenAdjustment) -> String {
        return classifyTieredPanelPlan(item.adjustedValue())
    }
}
