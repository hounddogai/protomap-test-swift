import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyAuditsForSchedule(_ items: [FormularyAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRollingInventorySchedulesFromAudit(_ items: [FormularyAudit]) -> [RollingInventorySchedule] {
        var out: [RollingInventorySchedule] = []
        for item in items {
            let derived = newRollingInventorySchedule(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitRollingInventorySchedule(_ item: RollingInventorySchedule) -> String {
        return classifyFormularySlot(item.weightedTotal())
    }
}
