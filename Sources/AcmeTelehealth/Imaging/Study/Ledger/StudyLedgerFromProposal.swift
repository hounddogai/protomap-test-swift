import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWeightedReadProposalsForLedger(_ items: [WeightedReadProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStudyLedgersFromProposal(_ items: [WeightedReadProposal]) -> [StudyLedger] {
        var out: [StudyLedger] = []
        for item in items {
            let derived = newStudyLedger(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceStudyLedger(_ item: StudyLedger) -> String {
        return lenientReadForecastBucket(item.netValue())
    }
}
