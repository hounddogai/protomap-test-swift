import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingEntriesForException(_ items: [RoundingEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveWeightedHandoffExceptionsFromEntry(_ items: [RoundingEntry]) -> [WeightedHandoffException] {
        var out: [WeightedHandoffException] = []
        for item in items {
            let derived = newWeightedHandoffException(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedHandoffException(_ item: WeightedHandoffException) -> String {
        return classifyRoundingRequest(item.effectiveVolume())
    }
}
