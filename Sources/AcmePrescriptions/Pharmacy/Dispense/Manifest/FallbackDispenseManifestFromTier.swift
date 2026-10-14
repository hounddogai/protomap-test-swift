import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseTiersForManifest(_ items: [DispenseTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveFallbackDispenseManifestsFromTier(_ items: [DispenseTier]) -> [FallbackDispenseManifest] {
        var out: [FallbackDispenseManifest] = []
        for item in items {
            let derived = newFallbackDispenseManifest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeFallbackDispenseManifest(_ item: FallbackDispenseManifest) -> String {
        return classifyDispenseThreshold(item.adjustedLoad())
    }
}
