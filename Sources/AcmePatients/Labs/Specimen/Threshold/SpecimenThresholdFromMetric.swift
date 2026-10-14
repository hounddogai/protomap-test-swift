import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelMetricsForThreshold(_ items: [PanelMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveSpecimenThresholdsFromMetric(_ items: [PanelMetric]) -> [SpecimenThreshold] {
        var out: [SpecimenThreshold] = []
        for item in items {
            let derived = newSpecimenThreshold(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleSpecimenThreshold(_ item: SpecimenThreshold) -> String {
        return normalizePanelPlanCode(item.code)
    }
}
