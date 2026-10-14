import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelAuditsForScore(_ items: [PanelAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePendingReferenceRangeScoresFromAudit(_ items: [PanelAudit]) -> [PendingReferenceRangeScore] {
        var out: [PendingReferenceRangeScore] = []
        for item in items {
            let derived = newPendingReferenceRangeScore(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPendingReferenceRangeScore(_ item: PendingReferenceRangeScore) -> Double {
        return panelAgreementWeight(1, active: true)
    }
}
