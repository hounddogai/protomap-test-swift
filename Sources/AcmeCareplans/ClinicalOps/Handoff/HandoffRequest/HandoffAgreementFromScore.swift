import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertScoresForAgreement(_ items: [AlertScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveHandoffAgreementsFromScore(_ items: [AlertScore]) -> [HandoffAgreement] {
        var out: [HandoffAgreement] = []
        for item in items {
            let derived = newHandoffAgreement(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeHandoffAgreement(_ item: HandoffAgreement) -> String {
        return classifyGlobalAlertSummary(item.netTotal())
    }
}
