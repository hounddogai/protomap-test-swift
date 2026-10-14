import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictWitnessAuditsForScore(_ items: [StrictWitnessAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func derivePendingRevocationScoresFromAudit(_ items: [StrictWitnessAudit]) -> [PendingRevocationScore] {
        var out: [PendingRevocationScore] = []
        for item in items {
            let derived = newPendingRevocationScore(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingRevocationScore(_ item: PendingRevocationScore) -> String {
        return witnessDigestBucket(item.netLoad())
    }
}
