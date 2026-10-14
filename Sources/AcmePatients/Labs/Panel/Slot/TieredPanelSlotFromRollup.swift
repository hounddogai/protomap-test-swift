import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedCourierRollupsForSlot(_ items: [CappedCourierRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTieredPanelSlotsFromRollup(_ items: [CappedCourierRollup]) -> [TieredPanelSlot] {
        var out: [TieredPanelSlot] = []
        for item in items {
            let derived = newTieredPanelSlot(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleTieredPanelSlot(_ item: TieredPanelSlot) -> String {
        return normalizeCappedCourierRollupCode(item.code)
    }
}
