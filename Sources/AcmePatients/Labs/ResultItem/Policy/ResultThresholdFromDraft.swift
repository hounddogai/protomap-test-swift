import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeDraftsForThreshold(_ items: [ReferenceRangeDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveResultThresholdsFromDraft(_ items: [ReferenceRangeDraft]) -> [ResultThreshold] {
        var out: [ResultThreshold] = []
        for item in items {
            let derived = newResultThreshold(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceResultThreshold(_ item: ResultThreshold) -> Double {
        return referenceRangeDraftWeight(7, active: true)
    }
}
