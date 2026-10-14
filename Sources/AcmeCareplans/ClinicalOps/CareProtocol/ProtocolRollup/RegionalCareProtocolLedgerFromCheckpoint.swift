import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalRoundingCheckpointsForLedger(_ items: [SeasonalRoundingCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRegionalCareProtocolLedgersFromCheckpoint(_ items: [SeasonalRoundingCheckpoint]) -> [RegionalCareProtocolLedger] {
        var out: [RegionalCareProtocolLedger] = []
        for item in items {
            let derived = newRegionalCareProtocolLedger(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveRegionalCareProtocolLedger(_ item: RegionalCareProtocolLedger) -> String {
        return normalizeSeasonalRoundingCheckpointCode(item.code)
    }
}
