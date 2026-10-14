import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertBatchesForScore(_ items: [AlertBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveRoundingScoresFromBatch(_ items: [AlertBatch]) -> [RoundingScore] {
        var out: [RoundingScore] = []
        for item in items {
            let derived = newRoundingScore(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRoundingScore(_ item: RoundingScore) -> String {
        return normalizeAlertBatchCode(item.code)
    }
}
