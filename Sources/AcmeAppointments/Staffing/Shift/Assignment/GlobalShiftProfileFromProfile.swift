import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanProfilesForProfile(_ items: [AcuityPlanProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveGlobalShiftProfilesFromProfile(_ items: [AcuityPlanProfile]) -> [GlobalShiftProfile] {
        var out: [GlobalShiftProfile] = []
        for item in items {
            let derived = newGlobalShiftProfile(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeGlobalShiftProfile(_ item: GlobalShiftProfile) -> Double {
        return acuityPlanBudgetWeight(5, active: true)
    }
}
