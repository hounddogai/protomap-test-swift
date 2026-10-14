import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalRevocationReservationsForSummary(_ items: [SeasonalRevocationReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func derivePrimaryProxySummariesFromReservation(_ items: [SeasonalRevocationReservation]) -> [PrimaryProxySummary] {
        var out: [PrimaryProxySummary] = []
        for item in items {
            let derived = newPrimaryProxySummary(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computePrimaryProxySummary(_ item: PrimaryProxySummary) -> String {
        return normalizeManualRevocationSegmentCode(item.code)
    }
}
