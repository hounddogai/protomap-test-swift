import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyProposalsForSnapshot(_ items: [FormularyProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedFormularySnapshotsFromProposal(_ items: [FormularyProposal]) -> [CappedFormularySnapshot] {
        var out: [CappedFormularySnapshot] = []
        for item in items {
            let derived = newCappedFormularySnapshot(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCappedFormularySnapshot(_ item: CappedFormularySnapshot) -> String {
        return classifyDefaultFormularySnapshot(item.netLoad())
    }
}
