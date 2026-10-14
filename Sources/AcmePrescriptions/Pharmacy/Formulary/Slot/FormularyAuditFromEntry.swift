import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallEntriesForAudit(_ items: [RecallEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFormularyAuditsFromEntry(_ items: [RecallEntry]) -> [FormularyAudit] {
        var out: [FormularyAudit] = []
        for item in items {
            let derived = newFormularyAudit(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFormularyAudit(_ item: FormularyAudit) -> String {
        return normalizeRecallProposalCode(item.code)
    }
}
