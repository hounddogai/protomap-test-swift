import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryAcuityPlanScoresForTemplate(_ items: [PrimaryAcuityPlanScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveScheduledShiftTemplatesFromScore(_ items: [PrimaryAcuityPlanScore]) -> [ScheduledShiftTemplate] {
        var out: [ScheduledShiftTemplate] = []
        for item in items {
            let derived = newScheduledShiftTemplate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyScheduledShiftTemplate(_ item: ScheduledShiftTemplate) -> String {
        return manualAcuityPlanProposalBucket(item.measuredValue())
    }
}
