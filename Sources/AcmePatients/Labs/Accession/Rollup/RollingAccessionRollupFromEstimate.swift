import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryPanelEstimatesForRollup(_ items: [PrimaryPanelEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRollingAccessionRollupsFromEstimate(_ items: [PrimaryPanelEstimate]) -> [RollingAccessionRollup] {
        var out: [RollingAccessionRollup] = []
        for item in items {
            let derived = newRollingAccessionRollup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRollingAccessionRollup(_ item: RollingAccessionRollup) -> String {
        return normalizePrimaryPanelEstimateCode(item.code)
    }
}
