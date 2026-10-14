import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelAdjustmentsForLedger(_ items: [PanelAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveAdaptiveSpecimenLedgersFromAdjustment(_ items: [PanelAdjustment]) -> [AdaptiveSpecimenLedger] {
        var out: [AdaptiveSpecimenLedger] = []
        for item in items {
            let derived = newAdaptiveSpecimenLedger(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveSpecimenLedger(_ item: AdaptiveSpecimenLedger) -> String {
        return normalizePanelBaselineCode(item.code)
    }
}
