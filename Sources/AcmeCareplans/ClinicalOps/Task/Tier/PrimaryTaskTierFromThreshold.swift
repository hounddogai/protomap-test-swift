import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingThresholdsForTier(_ items: [RoundingThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePrimaryTaskTiersFromThreshold(_ items: [RoundingThreshold]) -> [PrimaryTaskTier] {
        var out: [PrimaryTaskTier] = []
        for item in items {
            let derived = newPrimaryTaskTier(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePrimaryTaskTier(_ item: PrimaryTaskTier) -> String {
        return manualRoundingBudgetBucket(item.projectedTotal())
    }
}
