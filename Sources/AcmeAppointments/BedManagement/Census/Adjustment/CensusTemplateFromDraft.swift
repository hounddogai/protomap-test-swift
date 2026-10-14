import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferDraftsForTemplate(_ items: [TransferDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCensusTemplatesFromDraft(_ items: [TransferDraft]) -> [CensusTemplate] {
        var out: [CensusTemplate] = []
        for item in items {
            let derived = newCensusTemplate(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCensusTemplate(_ item: CensusTemplate) -> String {
        return classifyTransferDraft(item.adjustedExposure())
    }
}
