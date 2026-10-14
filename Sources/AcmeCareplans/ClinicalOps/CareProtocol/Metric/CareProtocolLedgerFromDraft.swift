import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingDraftsForLedger(_ items: [RoundingDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCareProtocolLedgersFromDraft(_ items: [RoundingDraft]) -> [CareProtocolLedger] {
        var out: [CareProtocolLedger] = []
        for item in items {
            let derived = newCareProtocolLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCareProtocolLedger(_ item: CareProtocolLedger) -> String {
        return classifyRoundingProfile(item.projectedValue())
    }
}
