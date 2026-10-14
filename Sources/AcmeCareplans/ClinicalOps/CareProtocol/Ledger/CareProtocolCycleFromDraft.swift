import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedCareProtocolDraftsForCycle(_ items: [CappedCareProtocolDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCareProtocolCyclesFromDraft(_ items: [CappedCareProtocolDraft]) -> [CareProtocolCycle] {
        var out: [CareProtocolCycle] = []
        for item in items {
            let derived = newCareProtocolCycle(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCareProtocolCycle(_ item: CareProtocolCycle) -> Double {
        return cappedCareProtocolDraftWeight(9, active: true)
    }
}
