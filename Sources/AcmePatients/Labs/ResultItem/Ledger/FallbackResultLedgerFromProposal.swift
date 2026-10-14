import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelProposalsForLedger(_ items: [PanelProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFallbackResultLedgersFromProposal(_ items: [PanelProposal]) -> [FallbackResultLedger] {
        var out: [FallbackResultLedger] = []
        for item in items {
            let derived = newFallbackResultLedger(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeFallbackResultLedger(_ item: FallbackResultLedger) -> Double {
        return panelPreferenceWeight(2, active: true)
    }
}
