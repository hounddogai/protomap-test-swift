import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryAcuityPlanRequestsForEntry(_ items: [PrimaryAcuityPlanRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveStrictShiftEntriesFromRequest(_ items: [PrimaryAcuityPlanRequest]) -> [StrictShiftEntry] {
        var out: [StrictShiftEntry] = []
        for item in items {
            let derived = newStrictShiftEntry(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveStrictShiftEntry(_ item: StrictShiftEntry) -> String {
        return normalizePrimaryAcuityPlanRequestCode(item.code)
    }
}
