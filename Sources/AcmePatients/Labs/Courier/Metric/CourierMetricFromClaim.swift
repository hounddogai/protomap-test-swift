import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelClaimsForMetric(_ items: [PanelClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCourierMetricsFromClaim(_ items: [PanelClaim]) -> [CourierMetric] {
        var out: [CourierMetric] = []
        for item in items {
            let derived = newCourierMetric(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectCourierMetric(_ item: CourierMetric) -> Double {
        return panelClaimWeight(5, active: true)
    }
}
