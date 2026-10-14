import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalCareProtocolRulesForScore(_ items: [RegionalCareProtocolRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveReadScoresFromRule(_ items: [RegionalCareProtocolRule]) -> [ReadScore] {
        var out: [ReadScore] = []
        for item in items {
            let derived = newReadScore(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceReadScore(_ item: ReadScore) -> String {
        return careProtocolManifestBucket(item.weightedValue())
    }
}
