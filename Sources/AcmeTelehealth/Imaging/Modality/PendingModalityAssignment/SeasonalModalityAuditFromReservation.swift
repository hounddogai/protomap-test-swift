import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveCareProtocolReservationsForAudit(_ items: [AdaptiveCareProtocolReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveSeasonalModalityAuditsFromReservation(_ items: [AdaptiveCareProtocolReservation]) -> [SeasonalModalityAudit] {
        var out: [SeasonalModalityAudit] = []
        for item in items {
            let derived = newSeasonalModalityAudit(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleSeasonalModalityAudit(_ item: SeasonalModalityAudit) -> Double {
        return adaptiveCareProtocolReservationWeight(6, active: true)
    }
}
