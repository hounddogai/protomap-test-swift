import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictShiftDigestsForRecord(_ items: [StrictShiftDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAcuityPlanRecordsFromDigest(_ items: [StrictShiftDigest]) -> [AcuityPlanRecord] {
        var out: [AcuityPlanRecord] = []
        for item in items {
            let derived = newAcuityPlanRecord(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAcuityPlanRecord(_ item: AcuityPlanRecord) -> String {
        return classifyPendingShiftBudget(item.netValue())
    }
}
