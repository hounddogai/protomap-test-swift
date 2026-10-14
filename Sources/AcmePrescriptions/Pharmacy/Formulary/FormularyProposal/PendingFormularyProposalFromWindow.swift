import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyWindowsForProposal(_ items: [FormularyWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingFormularyProposalsFromWindow(_ items: [FormularyWindow]) -> [PendingFormularyProposal] {
        var out: [PendingFormularyProposal] = []
        for item in items {
            let derived = newPendingFormularyProposal(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scorePendingFormularyProposal(_ item: PendingFormularyProposal) -> String {
        return rollingFormularySnapshotBucket(item.measuredValue())
    }
}
