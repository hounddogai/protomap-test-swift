import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertRollupsForCheckpoint(_ items: [AlertRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOrderSetCheckpointsFromRollup(_ items: [AlertRollup]) -> [OrderSetCheckpoint] {
        var out: [OrderSetCheckpoint] = []
        for item in items {
            let derived = newOrderSetCheckpoint(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planOrderSetCheckpoint(_ item: OrderSetCheckpoint) -> Double {
        return alertReservationWeight(7, active: true)
    }
}
