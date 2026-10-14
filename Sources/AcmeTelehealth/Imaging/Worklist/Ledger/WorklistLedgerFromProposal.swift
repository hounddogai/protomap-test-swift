import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalCareProtocolProposalsForLedger(_ items: [SeasonalCareProtocolProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveWorklistLedgersFromProposal(_ items: [SeasonalCareProtocolProposal]) -> [WorklistLedger] {
        var out: [WorklistLedger] = []
        for item in items {
            let derived = newWorklistLedger(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveWorklistLedger(_ item: WorklistLedger) -> Double {
        return fallbackCareProtocolPolicyWeight(8, active: true)
    }
}
