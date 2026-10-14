import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertVariancesForDraft(_ items: [AlertVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCappedCareProtocolDraftsFromVariance(_ items: [AlertVariance]) -> [CappedCareProtocolDraft] {
        var out: [CappedCareProtocolDraft] = []
        for item in items {
            let derived = newCappedCareProtocolDraft(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCappedCareProtocolDraft(_ item: CappedCareProtocolDraft) -> Double {
        return defaultAlertProfileWeight(8, active: true)
    }
}
