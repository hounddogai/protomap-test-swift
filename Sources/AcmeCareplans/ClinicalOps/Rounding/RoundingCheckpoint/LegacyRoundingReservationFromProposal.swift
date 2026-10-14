import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackHandoffProposalsForReservation(_ items: [FallbackHandoffProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLegacyRoundingReservationsFromProposal(_ items: [FallbackHandoffProposal]) -> [LegacyRoundingReservation] {
        var out: [LegacyRoundingReservation] = []
        for item in items {
            let derived = newLegacyRoundingReservation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankLegacyRoundingReservation(_ item: LegacyRoundingReservation) -> String {
        return normalizeHandoffTierCode(item.code)
    }
}
