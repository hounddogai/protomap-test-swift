import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanProfilesForLedger(_ items: [AcuityPlanProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveOvertimeLedgersFromProfile(_ items: [AcuityPlanProfile]) -> [OvertimeLedger] {
        var out: [OvertimeLedger] = []
        for item in items {
            let derived = newOvertimeLedger(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectOvertimeLedger(_ item: OvertimeLedger) -> Double {
        return acuityPlanGroupWeight(9, active: true)
    }
}
