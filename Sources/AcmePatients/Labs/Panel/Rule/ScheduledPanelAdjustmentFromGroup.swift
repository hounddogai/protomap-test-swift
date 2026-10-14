import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredPanelGroupsForAdjustment(_ items: [TieredPanelGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveScheduledPanelAdjustmentsFromGroup(_ items: [TieredPanelGroup]) -> [ScheduledPanelAdjustment] {
        var out: [ScheduledPanelAdjustment] = []
        for item in items {
            let derived = newScheduledPanelAdjustment(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceScheduledPanelAdjustment(_ item: ScheduledPanelAdjustment) -> String {
        return normalizePanelReservationCode(item.code)
    }
}
