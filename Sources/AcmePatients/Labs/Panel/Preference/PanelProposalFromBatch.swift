import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionBatchesForProposal(_ items: [AccessionBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePanelProposalsFromBatch(_ items: [AccessionBatch]) -> [PanelProposal] {
        var out: [PanelProposal] = []
        for item in items {
            let derived = newPanelProposal(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePanelProposal(_ item: PanelProposal) -> Double {
        return accessionPlanWeight(8, active: true)
    }
}
