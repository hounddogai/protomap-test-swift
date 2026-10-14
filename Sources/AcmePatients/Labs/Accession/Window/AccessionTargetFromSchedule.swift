import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingPanelSchedulesForTarget(_ items: [RollingPanelSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAccessionTargetsFromSchedule(_ items: [RollingPanelSchedule]) -> [AccessionTarget] {
        var out: [AccessionTarget] = []
        for item in items {
            let derived = newAccessionTarget(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveAccessionTarget(_ item: AccessionTarget) -> Double {
        return panelAgreementWeight(1, active: true)
    }
}
