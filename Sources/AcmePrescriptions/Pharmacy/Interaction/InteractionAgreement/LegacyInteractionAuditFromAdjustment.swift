import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultDispenseAdjustmentsForAudit(_ items: [DefaultDispenseAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveLegacyInteractionAuditsFromAdjustment(_ items: [DefaultDispenseAdjustment]) -> [LegacyInteractionAudit] {
        var out: [LegacyInteractionAudit] = []
        for item in items {
            let derived = newLegacyInteractionAudit(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateLegacyInteractionAudit(_ item: LegacyInteractionAudit) -> Double {
        return manualDispenseScheduleWeight(4, active: true)
    }
}
