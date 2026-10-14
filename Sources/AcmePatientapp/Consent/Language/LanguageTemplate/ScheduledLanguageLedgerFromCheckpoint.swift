import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationCheckpointsForLedger(_ items: [RevocationCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveScheduledLanguageLedgersFromCheckpoint(_ items: [RevocationCheckpoint]) -> [ScheduledLanguageLedger] {
        var out: [ScheduledLanguageLedger] = []
        for item in items {
            let derived = newScheduledLanguageLedger(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchScheduledLanguageLedger(_ item: ScheduledLanguageLedger) -> Double {
        return cappedRevocationAdjustmentWeight(5, active: true)
    }
}
