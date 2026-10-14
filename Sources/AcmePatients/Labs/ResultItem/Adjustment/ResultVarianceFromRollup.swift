import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionRollupsForVariance(_ items: [AccessionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveResultVariancesFromRollup(_ items: [AccessionRollup]) -> [ResultVariance] {
        var out: [ResultVariance] = []
        for item in items {
            let derived = newResultVariance(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateResultVariance(_ item: ResultVariance) -> String {
        return normalizeFallbackAccessionReservationCode(item.code)
    }
}
