import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveTransferTiersForScore(_ items: [AdaptiveTransferTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveBedBoardScoresFromTier(_ items: [AdaptiveTransferTier]) -> [BedBoardScore] {
        var out: [BedBoardScore] = []
        for item in items {
            let derived = newBedBoardScore(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveBedBoardScore(_ item: BedBoardScore) -> String {
        return classifyFallbackTransferPlan(item.projectedVolume())
    }
}
