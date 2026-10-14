import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRegionalDenialPoliciesForRecord(_ items: [RegionalDenialPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLegacyStatementRecordsFromPolicy(_ items: [RegionalDenialPolicy]) -> [LegacyStatementRecord] {
        var out: [LegacyStatementRecord] = []
        for item in items {
            let derived = newLegacyStatementRecord(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLegacyStatementRecord(_ item: LegacyStatementRecord) -> String {
        return classifyManualDenialLedger(item.projectedTotal())
    }
}
