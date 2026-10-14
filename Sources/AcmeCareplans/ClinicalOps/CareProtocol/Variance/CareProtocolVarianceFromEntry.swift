import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertEntriesForVariance(_ items: [AlertEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCareProtocolVariancesFromEntry(_ items: [AlertEntry]) -> [CareProtocolVariance] {
        var out: [CareProtocolVariance] = []
        for item in items {
            let derived = newCareProtocolVariance(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateCareProtocolVariance(_ item: CareProtocolVariance) -> Double {
        return alertCycleWeight(7, active: true)
    }
}
