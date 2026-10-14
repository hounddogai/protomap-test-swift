import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolVariancesForTemplate(_ items: [CareProtocolVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveAlertTemplatesFromVariance(_ items: [CareProtocolVariance]) -> [AlertTemplate] {
        var out: [AlertTemplate] = []
        for item in items {
            let derived = newAlertTemplate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankAlertTemplate(_ item: AlertTemplate) -> String {
        return classifyCareProtocolMilestone(item.weightedVolume())
    }
}
