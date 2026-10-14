import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveCareProtocolReservationsForTier(_ items: [AdaptiveCareProtocolReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveTieredReadTiersFromReservation(_ items: [AdaptiveCareProtocolReservation]) -> [TieredReadTier] {
        var out: [TieredReadTier] = []
        for item in items {
            let derived = newTieredReadTier(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectTieredReadTier(_ item: TieredReadTier) -> String {
        return normalizeRegionalCareProtocolDigestCode(item.code)
    }
}
