import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusAgreementsForTemplate(_ items: [CensusAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveIsolationTemplatesFromAgreement(_ items: [CensusAgreement]) -> [IsolationTemplate] {
        var out: [IsolationTemplate] = []
        for item in items {
            let derived = newIsolationTemplate(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeIsolationTemplate(_ item: IsolationTemplate) -> Double {
        return censusAgreementWeight(5, active: true)
    }
}
