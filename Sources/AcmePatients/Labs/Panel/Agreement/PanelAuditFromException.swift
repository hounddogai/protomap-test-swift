import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalCourierExceptionsForAudit(_ items: [SeasonalCourierException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelAuditsFromException(_ items: [SeasonalCourierException]) -> [PanelAudit] {
        var out: [PanelAudit] = []
        for item in items {
            let derived = newPanelAudit(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPanelAudit(_ item: PanelAudit) -> String {
        return classifySeasonalCourierException(item.effectiveLoad())
    }
}
